import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  composer,
  dateLisible,
  envoyerNotificationsEnAttente,
  messageAccesSecours,
} from '../_logique/notifications_en_attente.mts';

// Les notifications parent qui attendaient d'être envoyées.
//
// `acces_secours_declenche` s'écrivait en base sans que personne ne le
// lise : le parent n'était prévenu de rien. Pour l'accès secours,
// c'est le pire endroit possible où avoir ce défaut.

const MAINTENANT = new Date('2026-08-28T14:00:00.000Z');

const EVENEMENT = {
  id: 'evt-1',
  parentId: 'parent-1',
  enfantId: 'enfant-1',
  typeEvenement: 'acces_secours_declenche',
  donnees: { partageId: 'partage-1' },
};

function fauxDepot(etat = {}) {
  const {
    evenements = [EVENEMENT],
    erreur = null,
    email = 'parent@exemple.test',
    prenom = 'Théo',
    acces = { expireLe: '2026-08-29T10:30:00.000Z' },
    envoiReussi = true,
  } = etat;

  const appels = [];

  return {
    appels,

    async evenementsEnAttente(limite) {
      appels.push({ nom: 'evenementsEnAttente', limite });
      return { evenements, erreur };
    },

    async emailParent(parentId) {
      appels.push({ nom: 'emailParent', parentId });
      return email;
    },

    async prenomEnfant(enfantId) {
      appels.push({ nom: 'prenomEnfant', enfantId });
      return prenom;
    },

    async accesSecours(partageId) {
      appels.push({ nom: 'accesSecours', partageId });
      return acces;
    },

    async envoyer(message) {
      appels.push({ nom: 'envoyer', message });
      return envoiReussi
        ? { envoye: true, statut: 201, detail: null }
        : { envoye: false, statut: 500, detail: 'refus' };
    },

    async marquerEnvoye(id, envoyeLe) {
      appels.push({ nom: 'marquerEnvoye', id, envoyeLe });
    },

    async marquerEchoue(id) {
      appels.push({ nom: 'marquerEchoue', id });
    },
  };
}

describe('Ce que le mail d’accès secours a le droit de dire', () => {
  const message = messageAccesSecours(
    'parent@exemple.test',
    'Théo',
    '2026-08-29T10:30:00.000Z',
  );

  test('Le prénom est dans l’objet', () => {
    // Sans lui, un parent de trois enfants ne saurait pas lequel est
    // concerné au moment précis où il doit le savoir.
    assert.match(message.sujet, /Théo/);
  });

  test('Il dit jusqu’à quand l’accès court', () => {
    assert.match(message.html, /29\/08/);
  });

  test('Il renvoie à l’application pour le reste', () => {
    // Qui a déclenché, avec quelle fonction, depuis quel
    // établissement : rien de tout cela ne transite par une boîte
    // mail. Le parent ouvre l'application.
    assert.match(message.html, /Ouvrez KidsRelay/);
  });

  test('Aucune donnée de santé, aucun nom de famille', () => {
    // Règle permanente de Fanny sur tous les mails, présents et à
    // venir : prénom seul au maximum.
    const interdits = [
      'allergie',
      'traitement',
      'pathologie',
      'médicament',
      'Dupont',
      'ATSEM',
      'École',
    ];

    for (const mot of interdits) {
      assert.ok(
        !message.html.includes(mot),
        `« ${mot} » n’a rien à faire dans un email`,
      );
    }
  });

  test('Une échéance illisible ne produit pas une date fausse', () => {
    const sansDate = messageAccesSecours('a@b.test', 'Noé', null);

    assert.match(sansDate.html, /dans l’application/);
    assert.ok(!sansDate.html.includes('NaN'));
  });

  test('Une date invalide non plus', () => {
    assert.match(dateLisible('pas-une-date'), /dans l’application/);
  });
});

describe('Composer un message', () => {
  test('Un accès secours devient un mail', async () => {
    const depot = fauxDepot();

    const message = await composer(depot, EVENEMENT);

    assert.ok(message);
    assert.equal(message.destinataire, 'parent@exemple.test');
  });

  test('Sans adresse parent, rien n’est composé', async () => {
    const depot = fauxDepot({ email: null });

    assert.equal(await composer(depot, EVENEMENT), null);
  });

  test('Sans prénom, rien n’est composé', async () => {
    // Un mail vague sur un enfant est pire que pas de mail du tout.
    const depot = fauxDepot({ prenom: null });

    assert.equal(await composer(depot, EVENEMENT), null);
  });

  test('Un type inconnu n’invente pas de texte', async () => {
    const depot = fauxDepot();

    const message = await composer(depot, {
      ...EVENEMENT,
      typeEvenement: 'type_qui_n_existe_pas',
    });

    assert.equal(message, null);
  });

  test('Une échéance introuvable ne bloque pas l’envoi', async () => {
    // Le parent doit être prévenu même si le partage a disparu entre
    // le déclenchement et le passage du filet.
    const depot = fauxDepot({ acces: null });

    const message = await composer(depot, EVENEMENT);

    assert.ok(message);
    assert.match(message.html, /dans l’application/);
  });
});

describe('Le passage qui envoie ce qui attend', () => {
  test('Il envoie, puis il marque', async () => {
    // Marquer avant l'envoi perdrait la ligne pour toujours si
    // l'envoi échouait.
    const depot = fauxDepot();

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    const noms = depot.appels.map((a) => a.nom);

    assert.ok(noms.indexOf('envoyer') < noms.indexOf('marquerEnvoye'));

    assert.deepEqual(bilan, {
      traites: 1,
      envoyes: 1,
      echoues: 0,
      ignores: 0,
    });
  });

  test('Un envoi refusé marque la ligne échouée', async () => {
    const depot = fauxDepot({ envoiReussi: false });

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.equal(bilan.echoues, 1);
    assert.ok(depot.appels.some((a) => a.nom === 'marquerEchoue'));
  });

  test('Un type inconnu est marqué, pas repris sans fin', async () => {
    // Sans cela, la même ligne serait relue toutes les cinq minutes
    // jusqu'à la fin des temps.
    const depot = fauxDepot({
      evenements: [{ ...EVENEMENT, typeEvenement: 'inconnu' }],
    });

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.equal(bilan.ignores, 1);
    assert.ok(depot.appels.some((a) => a.nom === 'marquerEchoue'));
    assert.ok(!depot.appels.some((a) => a.nom === 'envoyer'));
  });

  test('Une erreur de lecture ne marque rien', async () => {
    // On ne sait pas ce qu'on n'a pas lu : marquer serait perdre.
    const depot = fauxDepot({ erreur: new Error('base indisponible') });

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.deepEqual(bilan, {
      traites: 0,
      envoyes: 0,
      echoues: 0,
      ignores: 0,
    });

    assert.ok(!depot.appels.some((a) => a.nom === 'marquerEchoue'));
  });

  test('Rien à envoyer n’est pas une erreur', async () => {
    const depot = fauxDepot({ evenements: [] });

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.equal(bilan.traites, 0);
  });

  test('Un envoi qui échoue n’empêche pas les suivants', async () => {
    // Le passage suivant est dans cinq minutes : une ligne bloquante
    // retarderait tout le reste d'autant.
    let appel = 0;

    const depot = fauxDepot({
      evenements: [
        EVENEMENT,
        { ...EVENEMENT, id: 'evt-2' },
        { ...EVENEMENT, id: 'evt-3' },
      ],
    });

    const envoyerOrigine = depot.envoyer;

    depot.envoyer = async (message) => {
      appel++;

      if (appel === 2) {
        return { envoye: false, statut: 500, detail: 'refus' };
      }

      return envoyerOrigine(message);
    };

    const bilan = await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.equal(bilan.traites, 3);
    assert.equal(bilan.envoyes, 2);
    assert.equal(bilan.echoues, 1);
  });

  test('Les envois sont séquentiels', async () => {
    // Deux passages simultanés enverraient sinon deux fois le même
    // message.
    let enCours = 0;
    let simultanes = 0;

    const depot = fauxDepot({
      evenements: [EVENEMENT, { ...EVENEMENT, id: 'evt-2' }],
    });

    depot.envoyer = async () => {
      enCours++;
      simultanes = Math.max(simultanes, enCours);
      await new Promise((r) => setTimeout(r, 5));
      enCours--;
      return { envoye: true, statut: 201, detail: null };
    };

    await envoyerNotificationsEnAttente(depot, MAINTENANT);

    assert.equal(simultanes, 1);
  });

  test('La limite est passée au dépôt', async () => {
    const depot = fauxDepot();

    await envoyerNotificationsEnAttente(depot, MAINTENANT, 10);

    const lecture = depot.appels.find(
      (a) => a.nom === 'evenementsEnAttente',
    );

    assert.equal(lecture.limite, 10);
  });
});
