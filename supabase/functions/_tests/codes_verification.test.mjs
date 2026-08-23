import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  CODE_VALIDE_MINUTES,
  TENTATIVES_MAX,
  dateExpiration,
  genererCode,
  hacher,
  jetonAppareilValide,
  verifierCode,
} from '../_logique/codes_verification.mts';

// Code de vérification envoyé quand un compte est utilisé depuis un
// appareil inconnu : c'est le dernier verrou avant qu'un mot de passe
// volé donne accès aux profils d'enfants. D'où cette couverture, qui
// décrit chaque façon dont un code peut être refusé.

const JETON = 'a'.repeat(64);
const MAINTENANT = new Date('2026-08-23T12:00:00.000Z');

/// Faux dépôt : enregistre les appels reçus, et rejoue la ligne
/// décrite par le test.
function fauxDepot({ ligne = null, erreur = null, erreurs = {} } = {}) {
  const appels = [];

  return {
    appels,

    async enregistrerCode(entree) {
      appels.push({ nom: 'enregistrerCode', entree });
      return { erreur: erreurs.enregistrerCode ?? null };
    },

    async dernierCodeNonUtilise(userId, jetonAppareilHash) {
      appels.push({
        nom: 'dernierCodeNonUtilise',
        userId,
        jetonAppareilHash,
      });
      return { ligne, erreur };
    },

    async incrementerTentatives(id, tentatives) {
      appels.push({ nom: 'incrementerTentatives', id, tentatives });
    },

    async marquerUtilise(id, horodatage) {
      appels.push({ nom: 'marquerUtilise', id, horodatage });
      return { erreur: erreurs.marquerUtilise ?? null };
    },

    async enregistrerAppareil(entree) {
      appels.push({ nom: 'enregistrerAppareil', entree });
      return { erreur: erreurs.enregistrerAppareil ?? null };
    },
  };
}

async function ligneValide(code, surcharges = {}) {
  return {
    id: 'ligne-1',
    code_hash: await hacher(code),
    expire_le: '2026-08-23T12:05:00.000Z',
    tentatives: 0,
    ...surcharges,
  };
}

describe('Génération du code', () => {
  test('Toujours six chiffres', () => {
    assert.equal(genererCode(() => 123456).length, 6);
    assert.equal(genererCode(() => 999999).length, 6);
  });

  test('Les zéros de tête sont conservés', () => {
    assert.equal(genererCode(() => 42), '000042');
    assert.equal(genererCode(() => 0), '000000');
  });

  test('Une valeur au-delà de six chiffres est ramenée dans la plage', () => {
    assert.equal(genererCode(() => 4_294_967_295), '967295');
  });
});

describe('Empreinte du code', () => {
  test('Le code n’apparaît jamais dans son empreinte', async () => {
    const empreinte = await hacher('123456');

    assert.ok(!empreinte.includes('123456'));
    assert.equal(empreinte.length, 64);
  });

  test('Deux codes différents donnent deux empreintes différentes', async () => {
    assert.notEqual(await hacher('123456'), await hacher('123457'));
  });

  test('Le même code donne toujours la même empreinte', async () => {
    assert.equal(await hacher('000042'), await hacher('000042'));
  });
});

describe('Jeton d’appareil', () => {
  test('Un jeton court est refusé', () => {
    assert.equal(jetonAppareilValide('trop-court'), false);
    assert.equal(jetonAppareilValide('a'.repeat(31)), false);
  });

  test('Un jeton de 32 caractères ou plus est accepté', () => {
    assert.equal(jetonAppareilValide('a'.repeat(32)), true);
  });

  test('Ce qui n’est pas une chaîne est refusé', () => {
    assert.equal(jetonAppareilValide(null), false);
    assert.equal(jetonAppareilValide(123456), false);
    assert.equal(jetonAppareilValide({}), false);
  });
});

describe('Expiration', () => {
  test('Le code expire dix minutes après sa création', () => {
    assert.equal(
      dateExpiration(MAINTENANT),
      '2026-08-23T12:10:00.000Z',
    );
    assert.equal(CODE_VALIDE_MINUTES, 10);
  });
});

describe('Vérification du code', () => {
  test('Le bon code est accepté et l’appareil enregistré', async () => {
    const depot = fauxDepot({ ligne: await ligneValide('123456') });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: 'iPhone de Fanny',
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'accepte' });

    const noms = depot.appels.map((a) => a.nom);

    // Le code est marqué utilisé AVANT l'enregistrement de
    // l'appareil : un code ne doit jamais pouvoir servir deux fois,
    // même si l'enregistrement échoue ensuite.
    assert.deepEqual(noms, [
      'dernierCodeNonUtilise',
      'marquerUtilise',
      'enregistrerAppareil',
    ]);

    const appareil = depot.appels.at(-1).entree;

    assert.equal(appareil.jetonHash, JETON);
    assert.equal(appareil.nomAppareil, 'iPhone de Fanny');
  });

  test('Un code faux est refusé et incrémente le compteur', async () => {
    const depot = fauxDepot({ ligne: await ligneValide('123456') });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '000000',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'refuse' });

    const incrementation = depot.appels.find(
      (a) => a.nom === 'incrementerTentatives',
    );

    assert.equal(incrementation.tentatives, 1);
    assert.ok(!depot.appels.some((a) => a.nom === 'enregistrerAppareil'));
  });

  test('Un code expiré est refusé sans incrémenter le compteur', async () => {
    const depot = fauxDepot({
      ligne: await ligneValide('123456', {
        expire_le: '2026-08-23T11:59:59.000Z',
      }),
    });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'refuse' });
    assert.deepEqual(depot.appels.map((a) => a.nom), [
      'dernierCodeNonUtilise',
    ]);
  });

  test('Le bon code est refusé une fois le plafond de tentatives atteint', async () => {
    const depot = fauxDepot({
      ligne: await ligneValide('123456', {
        tentatives: TENTATIVES_MAX,
      }),
    });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'refuse' });
    assert.ok(!depot.appels.some((a) => a.nom === 'marquerUtilise'));
  });

  test('Aucun code en cours : refusé', async () => {
    const depot = fauxDepot({ ligne: null });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'refuse' });
  });

  test('Le code est cherché pour cet utilisateur ET cet appareil', async () => {
    const depot = fauxDepot({ ligne: await ligneValide('123456') });

    await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    const recherche = depot.appels[0];

    assert.equal(recherche.userId, 'user-1');
    assert.equal(recherche.jetonAppareilHash, JETON);
  });

  test('Une panne de base ne se fait pas passer pour un code faux', async () => {
    const depot = fauxDepot({ erreur: new Error('base injoignable') });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'erreurBase' });
  });

  test('Un échec d’enregistrement de l’appareil est distinct d’un code refusé', async () => {
    const depot = fauxDepot({
      ligne: await ligneValide('123456'),
      erreurs: { enregistrerAppareil: new Error('conflit') },
    });

    const resultat = await verifierCode(
      depot,
      {
        userId: 'user-1',
        code: '123456',
        jetonAppareilHash: JETON,
        nomAppareil: null,
      },
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'echecAppareil' });

    // Le code a bien été consommé : il ne doit pas rester utilisable
    // parce que l'étape suivante a échoué.
    assert.ok(depot.appels.some((a) => a.nom === 'marquerUtilise'));
  });
});
