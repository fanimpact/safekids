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

describe('La décision du verrou', () => {
  test('Aucun verrou posé : la première ouverture le pose', () => {
    assert.equal(
      decisionVerrou({
        empreinteStockee: null,
        verrouPoseLe: null,
        empreintePresentee: null,
        maintenant: MAINTENANT,
      }),
      'poser',
    );
  });

  test('Le même appareil repasse', () => {
    assert.equal(
      decisionVerrou({
        empreinteStockee: 'abc',
        verrouPoseLe: ilYA(60 * 24),
        empreintePresentee: 'abc',
        maintenant: MAINTENANT,
      }),
      'accepter',
    );
  });

  test('Un autre appareil, le lendemain, est refusé', () => {
    assert.equal(
      decisionVerrou({
        empreinteStockee: 'abc',
        verrouPoseLe: ilYA(60 * 24),
        empreintePresentee: 'xyz',
        maintenant: MAINTENANT,
      }),
      'refuser',
    );
  });

  test('Un appareil sans secret, le lendemain, est refusé', () => {
    // Le cas de quelqu'un à qui le lien a été transféré : il n'a
    // jamais rien reçu de nous.
    assert.equal(
      decisionVerrou({
        empreinteStockee: 'abc',
        verrouPoseLe: ilYA(60 * 24),
        empreintePresentee: null,
        maintenant: MAINTENANT,
      }),
      'refuser',
    );
  });

  describe('La fenêtre de tolérance', () => {
    // Elle absorbe le cas très courant du navigateur intégré d'un
    // client mail suivi de « ouvrir dans Chrome » : deux espaces de
    // stockage distincts, et le destinataire légitime se verrouille
    // dehors tout seul.

    test('Une minute après, le second appareil reprend le verrou', () => {
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: ilYA(1),
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'reprendre',
      );
    });

    test('À la minute exacte de la fenêtre, encore toléré', () => {
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: ilYA(TOLERANCE_MINUTES),
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'reprendre',
      );
    });

    test('Une minute plus tard, refusé', () => {
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: ilYA(TOLERANCE_MINUTES + 1),
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'refuser',
      );
    });

    test('La fenêtre est réglable, et le défaut est de quinze minutes',
      () => {
        assert.equal(TOLERANCE_MINUTES, 15);

        assert.equal(
          decisionVerrou({
            empreinteStockee: 'abc',
            verrouPoseLe: ilYA(3),
            empreintePresentee: null,
            maintenant: MAINTENANT,
            toleranceMinutes: 2,
          }),
          'refuser',
        );
      });
  });

  describe('Ce qui ne doit pas ouvrir la fenêtre', () => {
    test('Un verrou posé sans date n’est pas toléré', () => {
      // On ne tolère pas ce qu'on ne sait pas situer dans le temps.
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: null,
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'refuser',
      );
    });

    test('Une date de pose illisible n’est pas tolérée', () => {
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: 'pas une date',
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'refuser',
      );
    });

    test('Une pose dans le futur n’est pas tolérée', () => {
      // Horloges désaccordées : un écart d'horloge ne doit pas ouvrir
      // une fenêtre de quinze minutes.
      assert.equal(
        decisionVerrou({
          empreinteStockee: 'abc',
          verrouPoseLe: ilYA(-30),
          empreintePresentee: null,
          maintenant: MAINTENANT,
        }),
        'refuser',
      );
    });

    test('Un secret qui ne correspond pas ne passe jamais, même frais',
      () => {
        // Il reprend le verrou dans la fenêtre — ce qui est voulu —
        // mais il n'est jamais « accepté » comme étant le même
        // appareil.
        assert.notEqual(
          decisionVerrou({
            empreinteStockee: 'abc',
            verrouPoseLe: ilYA(1),
            empreintePresentee: 'xyz',
            maintenant: MAINTENANT,
          }),
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
