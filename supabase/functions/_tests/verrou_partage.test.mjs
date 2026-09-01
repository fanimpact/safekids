import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  decisionVerrou,
  empreinteDuSecret,
} from '../_logique/verrou_partage.mts';

// Trois places par partage, comptées au retour du navigateur
// (01/09/2026).
//
// Ce que ces tests protègent, et pourquoi.
//
// Le stockage local est cloisonné par navigateur, et ce cloisonnement
// n'est pas le nôtre : c'est celui du système. Un lecteur de QR ouvre
// souvent la page dans sa propre fenêtre intégrée, qu'on referme et
// qu'on ne rouvre jamais. Un seul téléphone fournissait donc deux
// places, et une maîtresse avec téléphone, tablette et ordinateur en
// atteignait six sans rien faire d'anormal.
//
// On ne peut pas deviner si un navigateur va rester — aucune détection
// n'est fiable, et Apple rend ses fenêtres intégrées indiscernables de
// Safari. On attend donc de voir s'il revient.

async function place(secret, { confirme = true, prisLe } = {}) {
  return {
    id: `place-${secret}`,
    empreinte: await empreinteDuSecret(secret),
    pris_le: prisLe ?? '2026-09-01T08:00:00.000Z',
    confirme,
  };
}

function decider(places, empreintePresentee, appareilsMax = 3) {
  return decisionVerrou({ places, appareilsMax, empreintePresentee });
}

describe('Reconnaître le navigateur qui revient', () => {
  test('Une place confirmée : il entre, sans nouveau secret', async () => {
    const mienne = await place('le-mien');

    const decision = decider([mienne], mienne.empreinte);

    assert.deepEqual(decision, { action: 'accepter' });
  });

  test('Une place non confirmée : le retour la confirme', async () => {
    // C'est tout le mécanisme : la première visite ne comptait pas,
    // la seconde compte.
    const mienne = await place('le-mien', { confirme: false });

    const decision = decider([mienne], mienne.empreinte);

    assert.deepEqual(decision, {
      action: 'confirmer',
      placeId: 'place-le-mien',
    });
  });

  test('Il est reconnu même si le plafond est atteint entre-temps',
    async () => {
      // Décision de Fanny : il avait commencé avant que le plafond
      // soit atteint, et bloquer quelqu'un qui a déjà lu la fiche une
      // fois est incompréhensible de son point de vue.
      const mienne = await place('le-mien', { confirme: false });

      const places = [
        mienne,
        await place('un'),
        await place('deux'),
        await place('trois'),
      ];

      const decision = decider(places, mienne.empreinte);

      assert.equal(decision.action, 'confirmer');
    });
});

describe('La fenêtre du lecteur de QR ne consomme rien', () => {
  test('Une place non confirmée ne compte pas dans le plafond',
    async () => {
      // Trois fenêtres ouvertes une fois et jamais rouvertes : le
      // quatrième navigateur entre quand même.
      const places = [
        await place('webview-1', { confirme: false }),
        await place('webview-2', { confirme: false }),
        await place('webview-3', { confirme: false }),
      ];

      assert.deepEqual(decider(places, null), { action: 'prendre' });
    });

  test('Trois places confirmées ferment la porte', async () => {
    const places = [
      await place('un'),
      await place('deux'),
      await place('trois'),
    ];

    assert.deepEqual(decider(places, null), { action: 'demander' });
  });

  test('Le mélange se compte sur les seules confirmées', async () => {
    const places = [
      await place('un'),
      await place('deux'),
      await place('passage', { confirme: false }),
    ];

    assert.deepEqual(decider(places, null), { action: 'prendre' });
  });
});

describe('Un inconnu de trop', () => {
  test('Il est arrêté dès sa PREMIÈRE visite', async () => {
    // Sinon il lirait la fiche une fois avant d'être arrêté, ce qui
    // viderait la règle de son sens.
    const places = [
      await place('un'),
      await place('deux'),
      await place('trois'),
    ];

    assert.deepEqual(decider(places, null), { action: 'demander' });
  });

  test('Un secret inconnu ne vaut pas mieux qu’aucun', async () => {
    const places = [
      await place('un'),
      await place('deux'),
      await place('trois'),
    ];

    const etranger = await empreinteDuSecret('pas-le-mien');

    assert.deepEqual(decider(places, etranger), { action: 'demander' });
  });

  test('Le plafond relevé par le parent le laisse entrer', async () => {
    // « Autoriser cet appareil » monte le plafond d'une unité.
    const places = [
      await place('un'),
      await place('deux'),
      await place('trois'),
    ];

    assert.deepEqual(decider(places, null, 4), { action: 'prendre' });
  });
});

describe('Ce que la décision ne fait plus', () => {
  test('Aucune fenêtre de tolérance', async () => {
    // Elle n'existait que pour absorber le cas « messagerie puis
    // navigateur ». Le comptage au retour le règle mieux et sans
    // délai — et la garder laissait un inconnu REMPLACER la place la
    // plus récente, donc voler celle de quelqu'un.
    const recente = await place('un', {
      prisLe: new Date().toISOString(),
    });

    const places = [recente, await place('deux'), await place('trois')];

    const decision = decider(places, null);

    assert.equal(decision.action, 'demander');
    assert.notEqual(decision.action, 'remplacer');
  });

  test('Aucun remplacement, jamais', async () => {
    // Une place prise ne se prend plus à personne : elle se libère
    // par le parent, ou elle ne se libère pas.
    const places = [
      await place('un'),
      await place('deux'),
      await place('trois'),
    ];

    for (const presente of [null, await empreinteDuSecret('inconnu')]) {
      assert.notEqual(decider(places, presente).action, 'remplacer');
    }
  });
});

describe('L’empreinte du secret', () => {
  test('Le même secret donne toujours la même empreinte', async () => {
    assert.equal(
      await empreinteDuSecret('abc'),
      await empreinteDuSecret('abc'),
    );
  });

  test('Deux secrets voisins donnent des empreintes sans rapport',
    async () => {
      assert.notEqual(
        await empreinteDuSecret('abc'),
        await empreinteDuSecret('abd'),
      );
    });

  test('L’empreinte ne contient pas le secret', async () => {
    // C'est l'empreinte qui est stockée, jamais le secret : une fuite
    // de la table ne donnerait à personne de quoi rouvrir un lien.
    const empreinte = await empreinteDuSecret('mon-secret');

    assert.ok(!empreinte.includes('mon-secret'));
    assert.equal(empreinte.length, 64);
  });
});
