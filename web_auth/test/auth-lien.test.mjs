import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  MESSAGES,
  demarrer,
  lireParametresDuFragment,
  messagePourEchec,
  soumettreMotDePasse,
  validerMotDePasse,
} from '../public/ouvrir-lien-email/auth-lien.js';

// Page d'accès au compte : c'est par elle que passe tout parent bloqué
// hors de son compte. Elle n'a pas d'écran de repli — d'où cette
// couverture, qui décrit les réponses de l'API sans réseau.

const API_URL = 'https://exemple.supabase.co';
const API_KEY = 'cle-publique-de-test';

/// Faux `fetch` : rejoue les réponses décrites, et enregistre les
/// appels reçus pour pouvoir les inspecter.
function fauxFetch(reponses) {
  const appels = [];

  const impl = async (url, options) => {
    appels.push({ url, options });

    const suivante = reponses.shift();

    if (suivante === undefined) {
      throw new Error('Appel réseau inattendu : ' + url);
    }

    if (suivante.panneReseau) {
      throw new TypeError('Failed to fetch');
    }

    return {
      ok: suivante.statut >= 200 && suivante.statut < 300,
      status: suivante.statut,
      json: async () => {
        if (suivante.corpsIllisible) {
          throw new SyntaxError('Unexpected token');
        }

        return suivante.corps ?? {};
      },
    };
  };

  impl.appels = appels;

  return impl;
}

describe('Lecture du lien reçu par email', () => {
  test('Un fragment complet est accepté', () => {
    assert.deepEqual(
      lireParametresDuFragment('#token_hash=abc123&type=recovery'),
      { tokenHash: 'abc123', type: 'recovery' },
    );
  });

  test('Le dièse initial est facultatif', () => {
    assert.deepEqual(
      lireParametresDuFragment('token_hash=abc123&type=signup'),
      { tokenHash: 'abc123', type: 'signup' },
    );
  });

  test('Un fragment vide est refusé', () => {
    assert.equal(lireParametresDuFragment(''), null);
    assert.equal(lireParametresDuFragment('#'), null);
  });

  test('Un jeton sans type est refusé', () => {
    assert.equal(lireParametresDuFragment('#token_hash=abc'), null);
  });

  test('Un type sans jeton est refusé', () => {
    assert.equal(lireParametresDuFragment('#type=recovery'), null);
  });

  test('Un type inconnu est refusé', () => {
    assert.equal(
      lireParametresDuFragment('#token_hash=abc&type=invite'),
      null,
      'Seuls recovery et signup sont pris en charge par cette page.',
    );
  });

  test('Une valeur non textuelle est refusée', () => {
    assert.equal(lireParametresDuFragment(undefined), null);
    assert.equal(lireParametresDuFragment(null), null);
  });
});

describe('Règles du mot de passe', () => {
  test('Huit caractères suffisent', () => {
    assert.equal(validerMotDePasse('12345678', '12345678'), null);
  });

  test('Sept caractères sont refusés', () => {
    assert.equal(
      validerMotDePasse('1234567', '1234567'),
      MESSAGES.motDePasseTropCourt,
    );
  });

  test('Deux saisies différentes sont refusées', () => {
    assert.equal(
      validerMotDePasse('motdepasse1', 'motdepasse2'),
      MESSAGES.motsDePasseDifferents,
    );
  });

  test(
    'La longueur est vérifiée avant la correspondance : le message '
    + 'désigne le vrai problème',
    () => {
      assert.equal(
        validerMotDePasse('court', 'autre'),
        MESSAGES.motDePasseTropCourt,
      );
    },
  );

  test('Une saisie vide est refusée', () => {
    assert.equal(
      validerMotDePasse('', ''),
      MESSAGES.motDePasseTropCourt,
    );
  });
});

describe('Traduction des échecs de l’API', () => {
  test('Un mot de passe jugé trop simple est nommé comme tel', () => {
    assert.equal(
      messagePourEchec(422, { error_code: 'weak_password' }),
      MESSAGES.motDePasseTropSimple,
    );
  });

  test('Réutiliser l’ancien mot de passe est nommé comme tel', () => {
    assert.equal(
      messagePourEchec(422, { code: 'same_password' }),
      MESSAGES.motDePasseIdentique,
    );
  });

  test(
    'Un 4xx sur le jeton donne le message unique expiré/déjà utilisé',
    () => {
      for (const statut of [400, 401, 403, 404, 422]) {
        assert.equal(
          messagePourEchec(statut, { code: 'otp_expired' }),
          MESSAGES.lienPerime,
          `statut ${statut}`,
        );
      }
    },
  );

  test('Une panne serveur ne prétend pas que le lien a expiré', () => {
    assert.equal(
      messagePourEchec(500, null),
      MESSAGES.generique,
      'Dire "lien expiré" sur un 500 enverrait le parent redemander '
      + 'un email pour rien.',
    );
  });

  test('Un corps illisible ne fait pas échouer la traduction', () => {
    assert.equal(messagePourEchec(400, null), MESSAGES.lienPerime);
  });
});

describe('Ouverture du lien "mot de passe oublié"', () => {
  test('Un lien valide ouvre le formulaire avec la session', async () => {
    const fetch = fauxFetch([
      { statut: 200, corps: { access_token: 'jeton-de-session' } },
    ]);

    const vue = await demarrer({
      fragment: '#token_hash=abc123&type=recovery',
      fetch,
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, {
      type: 'formulaire-mot-de-passe',
      accessToken: 'jeton-de-session',
    });

    const appel = fetch.appels[0];

    assert.equal(appel.url, `${API_URL}/auth/v1/verify`);
    assert.equal(appel.options.method, 'POST');
    assert.equal(appel.options.headers.apikey, API_KEY);
    assert.deepEqual(JSON.parse(appel.options.body), {
      type: 'recovery',
      token_hash: 'abc123',
    });
  });

  test('Un lien expiré ou déjà utilisé affiche le message unique', async () => {
    const vue = await demarrer({
      fragment: '#token_hash=abc123&type=recovery',
      fetch: fauxFetch([
        { statut: 401, corps: { code: 'otp_expired' } },
      ]),
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, {
      type: 'erreur',
      message: MESSAGES.lienPerime,
    });
  });

  test('Un lien sans fragment n’appelle même pas l’API', async () => {
    const fetch = fauxFetch([]);

    const vue = await demarrer({
      fragment: '',
      fetch,
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, {
      type: 'erreur',
      message: MESSAGES.lienInvalide,
    });
    assert.equal(fetch.appels.length, 0);
  });

  test('Une coupure réseau est annoncée comme telle', async () => {
    const vue = await demarrer({
      fragment: '#token_hash=abc123&type=recovery',
      fetch: fauxFetch([{ panneReseau: true }]),
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, {
      type: 'erreur',
      message: MESSAGES.reseau,
    });
  });

  test(
    'Une réponse acceptée mais sans session ne laisse pas le '
    + 'formulaire s’ouvrir dans le vide',
    async () => {
      const vue = await demarrer({
        fragment: '#token_hash=abc123&type=recovery',
        fetch: fauxFetch([{ statut: 200, corps: {} }]),
        apiUrl: API_URL,
        apiKey: API_KEY,
      });

      assert.deepEqual(vue, {
        type: 'erreur',
        message: MESSAGES.generique,
      });
    },
  );
});

describe('Ouverture du lien "confirmation de compte"', () => {
  test('Un lien valide confirme le compte, sans formulaire', async () => {
    const fetch = fauxFetch([
      { statut: 200, corps: { access_token: 'jeton' } },
    ]);

    const vue = await demarrer({
      fragment: '#token_hash=xyz789&type=signup',
      fetch,
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, { type: 'compte-confirme' });

    assert.deepEqual(JSON.parse(fetch.appels[0].options.body), {
      type: 'signup',
      token_hash: 'xyz789',
    });
  });

  test('Un lien déjà utilisé affiche le message unique', async () => {
    const vue = await demarrer({
      fragment: '#token_hash=xyz789&type=signup',
      fetch: fauxFetch([{ statut: 403, corps: {} }]),
      apiUrl: API_URL,
      apiKey: API_KEY,
    });

    assert.deepEqual(vue, {
      type: 'erreur',
      message: MESSAGES.lienPerime,
    });
  });
});

describe('Enregistrement du nouveau mot de passe', () => {
  test('Un mot de passe valide est envoyé avec la session', async () => {
    const fetch = fauxFetch([{ statut: 200, corps: { id: 'u1' } }]);

    const resultat = await soumettreMotDePasse({
      fetch,
      apiUrl: API_URL,
      apiKey: API_KEY,
      accessToken: 'jeton-de-session',
      motDePasse: 'unMotDePasseSolide',
      confirmation: 'unMotDePasseSolide',
    });

    assert.deepEqual(resultat, { ok: true });

    const appel = fetch.appels[0];

    assert.equal(appel.url, `${API_URL}/auth/v1/user`);
    assert.equal(appel.options.method, 'PUT');
    assert.equal(
      appel.options.headers.Authorization,
      'Bearer jeton-de-session',
    );
    assert.deepEqual(JSON.parse(appel.options.body), {
      password: 'unMotDePasseSolide',
    });
  });

  test(
    'Une saisie invalide est refusée sans appeler l’API',
    async () => {
      const fetch = fauxFetch([]);

      const resultat = await soumettreMotDePasse({
        fetch,
        apiUrl: API_URL,
        apiKey: API_KEY,
        accessToken: 'jeton',
        motDePasse: 'court',
        confirmation: 'court',
      });

      assert.deepEqual(resultat, {
        ok: false,
        message: MESSAGES.motDePasseTropCourt,
      });
      assert.equal(fetch.appels.length, 0);
    },
  );

  test('Un refus de l’API remonte son message', async () => {
    const resultat = await soumettreMotDePasse({
      fetch: fauxFetch([
        { statut: 422, corps: { error_code: 'weak_password' } },
      ]),
      apiUrl: API_URL,
      apiKey: API_KEY,
      accessToken: 'jeton',
      motDePasse: 'motdepasse',
      confirmation: 'motdepasse',
    });

    assert.deepEqual(resultat, {
      ok: false,
      message: MESSAGES.motDePasseTropSimple,
    });
  });

  test('Une coupure réseau est annoncée comme telle', async () => {
    const resultat = await soumettreMotDePasse({
      fetch: fauxFetch([{ panneReseau: true }]),
      apiUrl: API_URL,
      apiKey: API_KEY,
      accessToken: 'jeton',
      motDePasse: 'motdepasse',
      confirmation: 'motdepasse',
    });

    assert.deepEqual(resultat, {
      ok: false,
      message: MESSAGES.reseau,
    });
  });
});

describe('Étanchéité vis-à-vis du jeton', () => {
  test(
    'Le jeton ne part que vers /auth/v1/verify, jamais ailleurs',
    async () => {
      const fetch = fauxFetch([
        { statut: 200, corps: { access_token: 'jeton-de-session' } },
        { statut: 200, corps: {} },
      ]);

      const vue = await demarrer({
        fragment: '#token_hash=secret-a-ne-pas-fuiter&type=recovery',
        fetch,
        apiUrl: API_URL,
        apiKey: API_KEY,
      });

      await soumettreMotDePasse({
        fetch,
        apiUrl: API_URL,
        apiKey: API_KEY,
        accessToken: vue.accessToken,
        motDePasse: 'unMotDePasseSolide',
        confirmation: 'unMotDePasseSolide',
      });

      for (const appel of fetch.appels) {
        assert.ok(
          !appel.url.includes('secret-a-ne-pas-fuiter'),
          'Le jeton ne doit jamais passer par l’URL : il finirait '
          + 'dans les journaux du serveur.',
        );
      }

      assert.ok(
        fetch.appels[0].options.body.includes(
          'secret-a-ne-pas-fuiter',
        ),
        'Il voyage dans le corps de la requête de vérification.',
      );
      assert.ok(
        !fetch.appels[1].options.body.includes(
          'secret-a-ne-pas-fuiter',
        ),
        'Et nulle part ailleurs.',
      );
    },
  );
});
