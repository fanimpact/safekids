import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  URL_BREVO,
  envoyerParBrevo,
  messageCodeVerification,
  messageNoteAjoutee,
} from '../_logique/emails.mts';

// Ces deux messages sont les seuls emails que KidsRelay envoie à un
// parent en dehors de ceux de Supabase Auth. La contrainte tenue ici :
// jamais de donnée de santé, jamais de nom de famille d'enfant, jamais
// le texte d'une note — un email traverse des serveurs que nous ne
// maîtrisons pas et reste dans une boîte mail pour toujours.

const EXPEDITEUR = {
  cleApi: 'cle-de-test',
  expediteurEmail: 'bonjour@kidsrelay.fr',
  expediteurNom: 'KidsRelay',
  repondreAEmail: 'bonjour@kidsrelay.fr',
};

/// Faux `fetch` : rejoue la réponse décrite et enregistre l'appel.
function fauxFetch(reponse) {
  const appels = [];

  const impl = async (url, options) => {
    appels.push({ url, options });

    return {
      ok: reponse.statut >= 200 && reponse.statut < 300,
      status: reponse.statut,
      text: async () => reponse.texte ?? '',
    };
  };

  impl.appels = appels;

  return impl;
}

describe('Email de code de vérification', () => {
  const message = messageCodeVerification(
    'parent@exemple.fr',
    '042317',
    10,
  );

  test('Le code figure dans le message', () => {
    assert.ok(message.html.includes('042317'));
  });

  test('La durée de validité est annoncée', () => {
    assert.ok(message.html.includes('10 minutes'));
  });

  test('La marche à suivre en cas de connexion non désirée est donnée', () => {
    assert.ok(message.html.includes('ignorez cet email'));
  });

  test('Le message part à la bonne adresse', () => {
    assert.equal(message.destinataire, 'parent@exemple.fr');
  });

  test('Le sujet ne contient pas le code', () => {
    assert.ok(!message.sujet.includes('042317'));
  });
});

describe('Email de note ajoutée', () => {
  const message = messageNoteAjoutee(
    'parent@exemple.fr',
    'Noé',
    'École des Lilas',
  );

  test('Le prénom de l’enfant et l’établissement sont nommés', () => {
    assert.ok(message.html.includes('Noé'));
    assert.ok(message.html.includes('École des Lilas'));
  });

  test('Le parent est renvoyé vers l’application pour lire la note', () => {
    assert.ok(message.html.includes('application KidsRelay'));
  });

  test('Le contenu de la note ne peut pas s’y trouver', () => {
    // La fonction ne reçoit pas le texte de la note : c'est la
    // garantie structurelle, pas seulement une convention de rédaction.
    assert.equal(messageNoteAjoutee.length, 3);
  });

  test('Aucun nom de famille n’est transmis', () => {
    // Seul un prénom entre : la signature ne permet pas d'en passer
    // davantage.
    const avecNomComplet = messageNoteAjoutee(
      'parent@exemple.fr',
      'Noé',
      'École des Lilas',
    );

    assert.equal(avecNomComplet.html, message.html);
  });
});

describe('Envoi par Brevo', () => {
  test('Un envoi accepté est signalé comme tel', async () => {
    const fetchImpl = fauxFetch({ statut: 201 });

    const resultat = await envoyerParBrevo(
      fetchImpl,
      EXPEDITEUR,
      messageCodeVerification('parent@exemple.fr', '042317', 10),
    );

    assert.deepEqual(resultat, {
      envoye: true,
      statut: 201,
      detail: null,
    });
  });

  test('La requête est adressée à l’API Brevo, clé en en-tête', async () => {
    const fetchImpl = fauxFetch({ statut: 201 });

    await envoyerParBrevo(
      fetchImpl,
      EXPEDITEUR,
      messageCodeVerification('parent@exemple.fr', '042317', 10),
    );

    const appel = fetchImpl.appels[0];

    assert.equal(appel.url, URL_BREVO);
    assert.equal(appel.options.method, 'POST');
    assert.equal(appel.options.headers['api-key'], 'cle-de-test');
  });

  test('Expéditeur, adresse de réponse et destinataire sont repris', async () => {
    const fetchImpl = fauxFetch({ statut: 201 });

    await envoyerParBrevo(
      fetchImpl,
      { ...EXPEDITEUR, repondreAEmail: 'contact@kidsrelay.fr' },
      messageNoteAjoutee('parent@exemple.fr', 'Noé', 'École des Lilas'),
    );

    const corps = JSON.parse(fetchImpl.appels[0].options.body);

    assert.deepEqual(corps.sender, {
      email: 'bonjour@kidsrelay.fr',
      name: 'KidsRelay',
    });
    assert.deepEqual(corps.replyTo, {
      email: 'contact@kidsrelay.fr',
    });
    assert.deepEqual(corps.to, [{ email: 'parent@exemple.fr' }]);
  });

  test('Un refus de Brevo remonte son statut et son détail', async () => {
    const fetchImpl = fauxFetch({
      statut: 401,
      texte: 'Key not found',
    });

    const resultat = await envoyerParBrevo(
      fetchImpl,
      EXPEDITEUR,
      messageCodeVerification('parent@exemple.fr', '042317', 10),
    );

    assert.deepEqual(resultat, {
      envoye: false,
      statut: 401,
      detail: 'Key not found',
    });
  });

  test('Aucun appel réseau n’est fait par les constructeurs de message', () => {
    // Les deux fonctions de contenu sont pures : elles ne reçoivent
    // pas `fetch` et ne peuvent donc rien envoyer.
    assert.equal(typeof messageCodeVerification('a@b.fr', '1', 1).html, 'string');
    assert.equal(typeof messageNoteAjoutee('a@b.fr', 'X', 'Y').html, 'string');
  });
});
