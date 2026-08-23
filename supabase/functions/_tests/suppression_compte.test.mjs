import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  DELAI_GRACE_JOURS,
  formaterDateFr,
  lireDateEffacement,
  messageSuppressionDemandee,
} from '../_logique/suppression_compte.mts';

// Email envoyé au moment où un parent demande la suppression de son
// compte. C'est le seul endroit où la date d'effacement définitif sort
// de l'application : s'il ferme l'app et oublie, c'est tout ce qui lui
// reste.

const EFFACEMENT = new Date('2026-08-31T12:00:00.000Z');

describe('Date lue depuis la requête', () => {
  test('Une date ISO est acceptée', () => {
    assert.equal(
      lireDateEffacement('2026-08-31T12:00:00.000Z')?.toISOString(),
      '2026-08-31T12:00:00.000Z',
    );
  });

  test('Ce qui n’est pas une date est refusé', () => {
    // Plutôt que d'envoyer un email annonçant « Invalid Date ».
    assert.equal(lireDateEffacement('pas une date'), null);
    assert.equal(lireDateEffacement(''), null);
    assert.equal(lireDateEffacement(null), null);
    assert.equal(lireDateEffacement(undefined), null);
    assert.equal(lireDateEffacement(1756641600000), null);
    assert.equal(lireDateEffacement({}), null);
  });
});

describe('Mise en forme de la date', () => {
  test('Format français, sans heure', () => {
    // L'heure exacte n'aide pas, et donnerait une fausse précision sur
    // le passage d'une tâche qui tourne une fois par jour.
    assert.equal(formaterDateFr(EFFACEMENT), '31/08/2026');
  });

  test('Les jours et mois à un chiffre sont complétés', () => {
    assert.equal(
      formaterDateFr(new Date('2026-01-05T09:00:00.000Z')),
      '05/01/2026',
    );
  });
});

describe('Contenu de l’email', () => {
  const message = messageSuppressionDemandee(
    'parent@exemple.fr',
    EFFACEMENT,
  );

  test('Il part à la bonne adresse', () => {
    assert.equal(message.destinataire, 'parent@exemple.fr');
  });

  test('La date d’effacement définitif y figure', () => {
    assert.ok(message.html.includes('31/08/2026'));
  });

  test('Le sujet annonce ce dont il s’agit', () => {
    assert.ok(message.sujet.includes('supprim'));
  });

  test('Le moyen d’annuler est expliqué', () => {
    // Un délai de grâce dont on ne sait pas sortir n'en est pas un.
    assert.ok(message.html.includes('application KidsRelay'));
    assert.ok(message.html.includes('annuler'));
  });

  test('Ce qui se passe en cas d’inaction est dit', () => {
    // Le silence ne doit pas être interprétable.
    assert.ok(message.html.includes('Si vous ne faites rien'));
  });

  test('Le compte est annoncé comme déjà inaccessible', () => {
    assert.ok(
      message.html.includes('n’est déjà plus accessible'),
    );
  });

  test('Le cas d’une demande non désirée est couvert', () => {
    assert.ok(
      message.html.includes('n’êtes pas à l’origine de cette demande'),
    );
  });
});

describe('Ce que l’email ne contient pas', () => {
  const message = messageSuppressionDemandee(
    'parent@exemple.fr',
    EFFACEMENT,
  );

  test('Aucun lien cliquable', () => {
    // L'annulation se fait dans l'application, où le parent est déjà
    // authentifié. Un lien d'annulation dans un email serait un moyen
    // supplémentaire de détourner un compte.
    assert.ok(!message.html.includes('<a '));
    assert.ok(!message.html.includes('http'));
  });

  test('Aucune donnée d’enfant ne peut y entrer', () => {
    // La fonction ne reçoit qu'une adresse et une date : c'est une
    // garantie de structure, pas une convention de rédaction.
    assert.equal(messageSuppressionDemandee.length, 2);
  });
});

describe('Le délai annoncé', () => {
  test('Sept jours, comme en base', () => {
    assert.equal(DELAI_GRACE_JOURS, 7);
  });
});
