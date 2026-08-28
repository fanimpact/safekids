import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { declencherAccesSecours } from '../_logique/acces_secours.mts';
import { empreinteDuSecret } from '../_logique/verrou_partage.mts';

// Le déclenchement d'un accès secours (28/08/2026).
//
// Ce geste n'attend pas le parent : c'est tout son intérêt, et c'est
// aussi ce qui le rend délicat. Ces tests décrivent exactement qui peut
// le déclencher, et sur quoi.

const MAINTENANT = new Date('2026-08-28T14:00:00.000Z');

const SOURCE = {
  id: 'partage-1',
  enfant_id: 'enfant-1',
  date_expiration: '2026-08-29T14:00:00.000Z',
  permanent: false,
  revoque_le: null,
  acces_secours_autorise: true,
  declenche_en_secours: false,
};

function fauxDepot(etat = {}) {
  const {
    partage = SOURCE,
    erreurPartage = null,
    places = [],
    erreurCreation = null,
  } = etat;

  const appels = [];

  return {
    appels,

    async partageParToken(token) {
      appels.push({ nom: 'partageParToken', token });
      return { partage, erreur: erreurPartage };
    },

    async placesDuPartage(partageId) {
      appels.push({ nom: 'placesDuPartage', partageId });
      return { places, erreur: null };
    },

    async creerAccesSecours(partageId) {
      appels.push({ nom: 'creerAccesSecours', partageId });

      return erreurCreation
        ? { acces: null, erreur: erreurCreation }
        : {
            acces: {
              token: 'jeton-secours',
              expireLe: '2026-08-29T14:00:00.000Z',
            },
            erreur: null,
          };
    },

    async notifierParent(partageId, enfantId) {
      appels.push({ nom: 'notifierParent', partageId, enfantId });
    },
  };
}

/// Une place détenue par le porteur du secret donné.
async function placeDe(secret) {
  return {
    id: 'place-1',
    empreinte: await empreinteDuSecret(secret),
    pris_le: '2026-08-28T13:00:00.000Z',
  };
}

describe('Qui peut déclencher', () => {
  test('Le détenteur du lien, préautorisé, y arrive', async () => {
    const depot = fauxDepot({ places: [await placeDe('le-mien')] });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.acces.token, 'jeton-secours');
  });

  test('Quelqu’un qui ne détient pas le lien est refusé', async () => {
    // Le contrôle qui compte : sans lui, quiconque intercepte une
    // adresse ouvrirait 24 heures d'accès sur l'enfant d'un autre.
    const depot = fauxDepot({ places: [await placeDe('le-mien')] });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'pas-le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'pasDetenteur' });
    assert.equal(
      depot.appels.some((a) => a.nom === 'creerAccesSecours'),
      false,
      'rien ne doit être créé pour quelqu’un qui n’a pas le lien',
    );
  });

  test('Sans secret du tout, refusé', async () => {
    const depot = fauxDepot({ places: [await placeDe('le-mien')] });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      null,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'pasDetenteur' });
  });

  test('Sur un partage que personne n’a encore ouvert, refusé', async () => {
    // Aucune place occupée : personne ne détient ce lien, donc
    // personne ne peut déclencher.
    const depot = fauxDepot({ places: [] });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'un-secret',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'pasDetenteur' });
  });
});

describe('Ce qui n’autorise pas le déclenchement', () => {
  test('Sans la préautorisation du parent', async () => {
    const depot = fauxDepot({
      partage: { ...SOURCE, acces_secours_autorise: false },
      places: [await placeDe('le-mien')],
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'nonAutorise' });
  });

  test('Un accès secours n’en déclenche pas un autre', async () => {
    const depot = fauxDepot({
      partage: { ...SOURCE, declenche_en_secours: true },
      places: [await placeDe('le-mien')],
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'nonAutorise' });
  });

  test('Un lien révoqué', async () => {
    const depot = fauxDepot({
      partage: { ...SOURCE, revoque_le: '2026-08-28T10:00:00.000Z' },
      places: [await placeDe('le-mien')],
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienFini' });
  });

  test('Un lien expiré', async () => {
    const depot = fauxDepot({
      partage: {
        ...SOURCE,
        date_expiration: '2026-08-28T13:00:00.000Z',
      },
      places: [await placeDe('le-mien')],
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienFini' });
  });

  test('Révoqué et expiré se répondent pareil', async () => {
    // Rien ne doit laisser deviner que le parent a coupé l'accès.
    const revoque = await declencherAccesSecours(
      fauxDepot({
        partage: { ...SOURCE, revoque_le: '2026-08-28T10:00:00.000Z' },
        places: [await placeDe('le-mien')],
      }),
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    const expire = await declencherAccesSecours(
      fauxDepot({
        partage: {
          ...SOURCE,
          date_expiration: '2026-08-28T13:00:00.000Z',
        },
        places: [await placeDe('le-mien')],
      }),
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(revoque, expire);
  });

  test('Un lien permanent, lui, déclenche', async () => {
    // Pas de date d'expiration à comparer : seule la révocation
    // l'arrête.
    const depot = fauxDepot({
      partage: {
        ...SOURCE,
        permanent: true,
        date_expiration: null,
      },
      places: [await placeDe('le-mien')],
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
  });

  test('Un jeton inconnu', async () => {
    const depot = fauxDepot({ partage: null });

    const resultat = await declencherAccesSecours(
      depot,
      'token-inconnu',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'tokenInconnu' });
  });

  test('Aucun jeton', async () => {
    const depot = fauxDepot();

    const resultat = await declencherAccesSecours(
      depot,
      null,
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'tokenAbsent' });
    assert.equal(depot.appels.length, 0);
  });
});

describe('Le parent est prévenu', () => {
  test('Après la création, jamais avant', async () => {
    // Un parent prévenu d'un accès qui n'existe pas irait chercher
    // dans sa liste quelque chose d'introuvable.
    const depot = fauxDepot({ places: [await placeDe('le-mien')] });

    await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    const noms = depot.appels.map((a) => a.nom);

    assert.ok(
      noms.indexOf('creerAccesSecours') < noms.indexOf('notifierParent'),
    );
  });

  test('Il porte le partage et l’enfant concernés', async () => {
    const depot = fauxDepot({ places: [await placeDe('le-mien')] });

    await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    const notification = depot.appels.find(
      (a) => a.nom === 'notifierParent',
    );

    assert.equal(notification.partageId, 'partage-1');
    assert.equal(notification.enfantId, 'enfant-1');
  });

  test('Un échec de création ne prévient personne', async () => {
    const depot = fauxDepot({
      places: [await placeDe('le-mien')],
      erreurCreation: new Error('base'),
    });

    const resultat = await declencherAccesSecours(
      depot,
      'token-1',
      'le-mien',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'erreurBase' });
    assert.equal(
      depot.appels.some((a) => a.nom === 'notifierParent'),
      false,
    );
  });
});
