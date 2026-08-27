import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import {
  TOLERANCE_MINUTES,
  decisionVerrou,
  empreinteDuSecret,
} from '../_logique/verrou_partage.mts';

// Le verrouillage d'un lien de partage (27/08/2026).
//
// C'est lui qui a permis de libérer les durées : accès anonyme = risque
// à compenser, pas durée à plafonner. Ces tests décrivent exactement
// quand un appareil passe et quand il est refusé.

const MAINTENANT = new Date('2026-08-27T12:00:00.000Z');

/// Une date décalée de `minutes` par rapport à MAINTENANT.
function ilYA(minutes) {
  return new Date(
    MAINTENANT.getTime() - minutes * 60000,
  ).toISOString();
}

function place(empreinte, minutesAvant, id = 'place-1') {
  return {
    id,
    empreinte,
    pris_le: new Date(
      MAINTENANT.getTime() - minutesAvant * 60000,
    ).toISOString(),
  };
}

describe('La décision', () => {
  test('Aucune place occupée : la première ouverture en prend une', () => {
    assert.deepEqual(
      decisionVerrou({
        places: [],
        appareilsMax: 1,
        empreintePresentee: null,
        maintenant: MAINTENANT,
      }),
      { action: 'prendre' },
    );
  });

  test('Le même appareil repasse', () => {
    assert.deepEqual(
      decisionVerrou({
        places: [place('abc', 60 * 24)],
        appareilsMax: 1,
        empreintePresentee: 'abc',
        maintenant: MAINTENANT,
      }),
      { action: 'accepter' },
    );
  });

  test('Il repasse même quand toutes les places sont prises', () => {
    assert.deepEqual(
      decisionVerrou({
        places: [
          place('abc', 60 * 24, 'p1'),
          place('def', 60 * 24, 'p2'),
        ],
        appareilsMax: 2,
        empreintePresentee: 'def',
        maintenant: MAINTENANT,
      }),
      { action: 'accepter' },
    );
  });

  test('Un autre appareil, le lendemain, est refusé', () => {
    assert.deepEqual(
      decisionVerrou({
        places: [place('abc', 60 * 24)],
        appareilsMax: 1,
        empreintePresentee: 'xyz',
        maintenant: MAINTENANT,
      }),
      { action: 'refuser' },
    );
  });

  describe('L’ordre des trois règles', () => {
    // Remplacement d'abord, place libre ensuite, refus en dernier.
    // Decide par Fanny le 27/08/2026, et cet ordre n'est pas
    // interchangeable.

    test('Le remplacement passe AVANT la place libre', () => {
      // Le cas messagerie puis navigateur, avec deux places. Dans
      // l'autre ordre, la grand-mere consommerait les deux places a
      // elle seule et le grand-pere serait refuse le surlendemain.
      assert.deepEqual(
        decisionVerrou({
          places: [place('abc', 1)],
          appareilsMax: 2,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'remplacer', placeId: 'place-1' },
      );
    });

    test('Hors fenêtre, une place libre est prise', () => {
      // La grand-mere mardi, le grand-pere jeudi.
      assert.deepEqual(
        decisionVerrou({
          places: [place('abc', 60 * 48)],
          appareilsMax: 2,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'prendre' },
      );
    });

    test('Hors fenêtre et sans place libre, refus', () => {
      assert.deepEqual(
        decisionVerrou({
          places: [
            place('abc', 60 * 48, 'p1'),
            place('def', 60 * 48, 'p2'),
          ],
          appareilsMax: 2,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'refuser' },
      );
    });

    test('C’est la place la plus récente qui est remplacée', () => {
      const decision = decisionVerrou({
        places: [
          place('ancienne', 60 * 48, 'p1'),
          place('recente', 2, 'p2'),
        ],
        appareilsMax: 5,
        empreintePresentee: null,
        maintenant: MAINTENANT,
      });

      assert.deepEqual(decision, {
        action: 'remplacer',
        placeId: 'p2',
      });
    });
  });

  describe('La fenêtre de tolérance', () => {
    test('À la minute exacte de la fenêtre, encore tolérée', () => {
      assert.equal(
        decisionVerrou({
          places: [place('abc', TOLERANCE_MINUTES)],
          appareilsMax: 1,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }).action,
        'remplacer',
      );
    });

    test('Une minute plus tard, refusé', () => {
      assert.deepEqual(
        decisionVerrou({
          places: [place('abc', TOLERANCE_MINUTES + 1)],
          appareilsMax: 1,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'refuser' },
      );
    });

    test('Le défaut est de quinze minutes, et la fenêtre est réglable',
      () => {
        assert.equal(TOLERANCE_MINUTES, 15);

        assert.deepEqual(
          decisionVerrou({
            places: [place('abc', 3)],
            appareilsMax: 1,
            empreintePresentee: null,
            maintenant: MAINTENANT,
            toleranceMinutes: 2,
          }),
          { action: 'refuser' },
        );
      });

    test('Elle se mesure sur la PREMIÈRE occupation de la place', () => {
      // Le defaut corrige : `pris_le` n'est jamais reecrit, donc un
      // remplacement ne repousse pas l'echeance. Sans cela, la
      // tolerance etait renouvelable sans fin — constate en production
      // le 27/08/2026.
      assert.deepEqual(
        decisionVerrou({
          places: [place('remplacee-plusieurs-fois', 60)],
          appareilsMax: 1,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'refuser' },
      );
    });
  });

  describe('Ce qui n’ouvre pas la fenêtre', () => {
    test('Une date de prise illisible', () => {
      assert.deepEqual(
        decisionVerrou({
          places: [{ id: 'p1', empreinte: 'abc', pris_le: 'pas une date' }],
          appareilsMax: 1,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'refuser' },
      );
    });

    test('Une prise dans le futur', () => {
      // Horloges desaccordees : un ecart d'horloge ne doit pas ouvrir
      // une fenetre.
      assert.deepEqual(
        decisionVerrou({
          places: [place('abc', -30)],
          appareilsMax: 1,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        { action: 'refuser' },
      );
    });

    test('Un secret qui ne correspond pas ne vaut jamais « accepter »',
      () => {
        assert.notEqual(
          decisionVerrou({
            places: [place('abc', 1)],
            appareilsMax: 1,
            empreintePresentee: 'xyz',
            maintenant: MAINTENANT,
          }).action,
          'accepter',
        );
      });
  });
});

describe('L’empreinte du secret', () => {
  test('C’est bien un SHA-256 en hexadécimal', async () => {
    const empreinte = await empreinteDuSecret('secret');

    assert.equal(empreinte.length, 64);
    assert.match(empreinte, /^[0-9a-f]{64}$/);
  });

  test('Le même secret donne toujours la même empreinte', async () => {
    assert.equal(
      await empreinteDuSecret('secret'),
      await empreinteDuSecret('secret'),
    );
  });

  test('Deux secrets voisins donnent des empreintes sans rapport',
    async () => {
      const a = await empreinteDuSecret('secret');
      const b = await empreinteDuSecret('secrer');

      assert.notEqual(a, b);
    });

  test('L’empreinte ne contient pas le secret', async () => {
    // C'est l'empreinte qui est stockée : une fuite de la table ne
    // donnerait à personne de quoi rouvrir un lien.
    const secret = 'unsecretbienreconnaissable';
    const empreinte = await empreinteDuSecret(secret);

    assert.equal(empreinte.includes(secret), false);
  });
});
