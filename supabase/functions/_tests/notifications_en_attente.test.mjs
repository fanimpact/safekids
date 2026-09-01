import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  composer,
  dateLisible,
  dejaTermine,
  envoyerNotificationsEnAttente,
  messageAccesSecours,
  messageDemandeAcces,
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
    MAINTENANT,
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
    const sansDate = messageAccesSecours('a@b.test', 'Noé', null, MAINTENANT);

    assert.match(sansDate.html, /dans l’application/);
    assert.ok(!sansDate.html.includes('NaN'));
  });

  test('Une date invalide ne rend rien plutot qu une date fausse', () => {
    assert.equal(dateLisible('pas-une-date'), null);
    assert.equal(dateLisible(null), null);
  });

  test('L’heure est celle de Paris, pas celle du serveur', () => {
    // Constate le 28/08/2026 sur le premier mail reel : une echeance
    // a 22h30 heure francaise s'affichait « 20h30 ». Sur un message
    // d'acces secours, un parent qui lit une heure fausse est un
    // defaut grave.
    assert.equal(dateLisible('2026-08-28T20:30:00.000Z'), '28/08 à 22h30');
  });

  test('La phrase dit « jusqu’au », pas « jusqu’le »', () => {
    // Le mail annoncait « jusqu'le 28/08 » tant que la date portait
    // son propre article.
    assert.ok(message.html.includes('jusqu’au 29/08'));
    assert.ok(!message.html.includes('jusqu’le'));
  });

  test('Il existe aussi en texte simple', () => {
    // Un message qui n'existe qu'en HTML est un signal de courrier
    // indesirable pour une partie des filtres.
    assert.ok(message.texte);
    assert.match(message.texte, /Théo/);
    assert.ok(!message.texte.includes('<p>'));
  });
});

describe('Composer un message', () => {
  test('Un accès secours devient un mail', async () => {
    const depot = fauxDepot();

    const message = await composer(depot, EVENEMENT, MAINTENANT);

    assert.ok(message);
    assert.equal(message.destinataire, 'parent@exemple.test');
  });

  test('Sans adresse parent, rien n’est composé', async () => {
    const depot = fauxDepot({ email: null });

    assert.equal(await composer(depot, EVENEMENT, MAINTENANT), null);
  });

  test('Sans prénom, rien n’est composé', async () => {
    // Un mail vague sur un enfant est pire que pas de mail du tout.
    const depot = fauxDepot({ prenom: null });

    assert.equal(await composer(depot, EVENEMENT, MAINTENANT), null);
  });

  test('Un type inconnu n’invente pas de texte', async () => {
    const depot = fauxDepot();

    const message = await composer(depot, {
      ...EVENEMENT,
      typeEvenement: 'type_qui_n_existe_pas',
    }, MAINTENANT);

    assert.equal(message, null);
  });

  test('Une échéance introuvable ne bloque pas l’envoi', async () => {
    // Le parent doit être prévenu même si le partage a disparu entre
    // le déclenchement et le passage du filet.
    const depot = fauxDepot({ acces: null });

    const message = await composer(depot, EVENEMENT, MAINTENANT);

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

// L'accès déjà terminé au moment de l'envoi (28/08/2026).
//
// Repéré par Fanny sur un mail de test. Le cas ne survient que si
// l'envoi immédiat a échoué ET que le filet horaire a échoué à son
// tour pendant plus de vingt-quatre heures — vingt-quatre échecs
// consécutifs. Rare, mais le message annoncerait une date passée sur
// le sujet le plus sensible du produit.
describe('Un accès déjà terminé se dit autrement', () => {
  const TERMINE = '2026-08-28T10:00:00.000Z';
  const EN_COURS = '2026-08-29T10:00:00.000Z';

  test('Il annonce la fin, pas une date passée', () => {
    const message = messageAccesSecours(
      'a@b.test',
      'Théo',
      TERMINE,
      MAINTENANT,
    );

    assert.match(message.html, /maintenant terminé/);
    assert.ok(!message.html.includes('jusqu’au'));
    assert.ok(!message.texte.includes('jusqu’au'));
  });

  test('Le prénom reste dans l’objet', () => {
    // Le parent doit toujours savoir de quel enfant on parle.
    const message = messageAccesSecours(
      'a@b.test',
      'Théo',
      TERMINE,
      MAINTENANT,
    );

    assert.match(message.sujet, /Théo/);
  });

  test('Un accès en cours garde sa date', () => {
    const message = messageAccesSecours(
      'a@b.test',
      'Théo',
      EN_COURS,
      MAINTENANT,
    );

    assert.match(message.html, /jusqu’au 29\/08/);
    assert.ok(!message.html.includes('terminé'));
  });

  test('Une échéance inconnue n’est pas déclarée terminée', () => {
    // On ne déclare pas fini ce qu'on ne sait pas situer dans le
    // temps : le parent irait vérifier pour rien.
    assert.equal(dejaTermine(null, MAINTENANT), false);
    assert.equal(dejaTermine('pas-une-date', MAINTENANT), false);
  });

  test('L’instant exact de la fin compte comme terminé', () => {
    assert.equal(
      dejaTermine(MAINTENANT.toISOString(), MAINTENANT),
      true,
    );
  });
});

// Le mail de demande d'accès (01/09/2026).
describe('Ce que le mail de demande a le droit de dire', () => {
  const message = messageDemandeAcces('parent@exemple.test', 'Théo');

  test('Il ne dit pas la raison saisie', () => {
    // Elle est écrite par une personne inconnue et pourrait contenir
    // n'importe quoi. Elle se lit dans l'application, nulle part
    // ailleurs.
    for (const bloc of [message.html, message.texte, message.sujet]) {
      assert.ok(!bloc.includes('raison'));
      assert.ok(!bloc.includes('Mamie'));
    }
  });

  test('Le prénom est là, le reste ne l’est pas', () => {
    // Sans lui, un parent de trois enfants ne saurait pas lequel est
    // concerné. Mais rien de plus : ni nom, ni donnée de santé.
    assert.match(message.sujet, /Théo/);

    for (const interdit of ['allergie', 'traitement', 'Dupont']) {
      assert.ok(!message.html.includes(interdit));
    }
  });

  test('Il dit que l’accès reste fermé sans réponse', () => {
    // Le silence du parent ne vaut jamais accord.
    assert.match(message.html, /l’accès reste/);
    assert.match(message.html, /fermé/);
  });

  test('Il existe aussi en texte simple', () => {
    assert.ok(message.texte);
    assert.ok(!message.texte.includes('<p>'));
  });

  test('Une demande devient un mail', async () => {
    const depot = fauxDepot();

    const compose = await composer(
      depot,
      { ...EVENEMENT, typeEvenement: 'demande_acces_partage' },
      MAINTENANT,
    );

    assert.ok(compose);
    assert.match(compose.sujet, /demande d’accès/);
  });
});
