import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import { notifierNoteAjoutee } from '../_logique/notification_note.mts';

// Une note ajoutée par un établissement déclenche un email au parent.
// Deux choses se jouent ici : qu'un membre du personnel ne puisse pas
// notifier le parent d'un enfant qui n'est pas le sien, et que la trace
// de la notification existe même quand l'envoi échoue — c'est elle qui
// servira au canal push le jour où il sera branché.

const MAINTENANT = new Date('2026-08-23T12:00:00.000Z');

const ENTREE = {
  appelantId: 'membre-1',
  enfantId: 'enfant-1',
  activiteId: 'activite-1',
};

/// Faux dépôt : décrit l'état de la base, enregistre les écritures.
function fauxDepot(etat = {}) {
  const {
    activite = {
      etablissement_id: 'etab-1',
      enfants_ids: ['enfant-1', 'enfant-2'],
    },
    membreActif = true,
    enfant = { prenom: 'Noé', parent_id: 'parent-1' },
    nomEtablissement = 'École des Lilas',
    emailParent = 'parent@exemple.fr',
    evenementId = 'evenement-1',
    erreurEvenement = null,
  } = etat;

  const ecritures = [];

  return {
    ecritures,

    async activite() {
      return activite;
    },

    async estMembreActif() {
      return membreActif;
    },

    async enfant() {
      return enfant;
    },

    async nomEtablissement() {
      return nomEtablissement;
    },

    async emailParent() {
      return emailParent;
    },

    async creerEvenement(entree) {
      ecritures.push({ nom: 'creerEvenement', entree });
      return { id: evenementId, erreur: erreurEvenement };
    },

    async marquerEvenement(id, statut, envoyeLe) {
      ecritures.push({ nom: 'marquerEvenement', id, statut, envoyeLe });
    },
  };
}

/// Faux envoi : rejoue le résultat décrit, enregistre ce qu'il reçoit.
function fauxEnvoi(resultat = { envoye: true, statut: 201, detail: null }) {
  const appels = [];

  const impl = async (destination) => {
    appels.push(destination);
    return resultat;
  };

  impl.appels = appels;

  return impl;
}

describe('Contrôles de droit', () => {
  // Le service_role contourne le RLS : ces contrôles sont le seul
  // rempart restant.

  test('Une activité inconnue est refusée', async () => {
    const depot = fauxDepot({ activite: null });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'activiteIntrouvable' });
    assert.equal(envoi.appels.length, 0);
    assert.equal(depot.ecritures.length, 0);
  });

  test('Une activité sans établissement est refusée', async () => {
    const depot = fauxDepot({
      activite: { etablissement_id: null, enfants_ids: ['enfant-1'] },
    });

    const resultat = await notifierNoteAjoutee(
      depot,
      fauxEnvoi(),
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'activiteIntrouvable' });
  });

  test('Un enfant qui ne participe pas à l’activité est refusé', async () => {
    const depot = fauxDepot({
      activite: {
        etablissement_id: 'etab-1',
        enfants_ids: ['enfant-2', 'enfant-3'],
      },
    });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'enfantHorsActivite' });
    assert.equal(envoi.appels.length, 0);
  });

  test('Une liste d’enfants absente ou malformée est refusée', async () => {
    for (const enfantsIds of [null, undefined, 'enfant-1', {}]) {
      const depot = fauxDepot({
        activite: { etablissement_id: 'etab-1', enfants_ids: enfantsIds },
      });

      const resultat = await notifierNoteAjoutee(
        depot,
        fauxEnvoi(),
        ENTREE,
        MAINTENANT,
      );

      assert.deepEqual(resultat, { statut: 'enfantHorsActivite' });
    }
  });

  test('Un appelant qui n’est pas membre actif est refusé', async () => {
    const depot = fauxDepot({ membreActif: false });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'pasMembre' });
    assert.equal(envoi.appels.length, 0);
    assert.equal(depot.ecritures.length, 0);
  });

  test('Un enfant sans parent rattaché est refusé', async () => {
    const depot = fauxDepot({
      enfant: { prenom: 'Noé', parent_id: null },
    });

    const resultat = await notifierNoteAjoutee(
      depot,
      fauxEnvoi(),
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'enfantIntrouvable' });
  });
});

describe('Journalisation', () => {
  test('L’événement est créé avant toute tentative d’envoi', async () => {
    const depot = fauxDepot();
    const envoi = fauxEnvoi();

    await notifierNoteAjoutee(depot, envoi, ENTREE, MAINTENANT);

    assert.equal(depot.ecritures[0].nom, 'creerEvenement');
  });

  test('L’événement porte le parent, l’enfant et le contexte', async () => {
    const depot = fauxDepot();

    await notifierNoteAjoutee(depot, fauxEnvoi(), ENTREE, MAINTENANT);

    assert.deepEqual(depot.ecritures[0].entree, {
      parentId: 'parent-1',
      enfantId: 'enfant-1',
      typeEvenement: 'note_ajoutee',
      donnees: {
        activiteId: 'activite-1',
        etablissementId: 'etab-1',
      },
    });
  });

  test('Le texte de la note n’est jamais journalisé', async () => {
    const depot = fauxDepot();

    await notifierNoteAjoutee(depot, fauxEnvoi(), ENTREE, MAINTENANT);

    // La logique ne recoit jamais le texte de la note : elle prend un
    // identifiant d'enfant et un identifiant d'activite, rien d'autre.
    // Ce que la ligne journalisee contient est donc borne par sa
    // signature, pas par une convention de redaction.
    assert.deepEqual(Object.keys(depot.ecritures[0].entree.donnees), [
      'activiteId',
      'etablissementId',
    ]);
  });

  test('Un échec de journalisation arrête tout : aucun email ne part', async () => {
    const depot = fauxDepot({ erreurEvenement: new Error('base') });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'echecJournalisation' });
    assert.equal(envoi.appels.length, 0);
  });

  test('Un événement sans identifiant retourné est traité comme un échec', async () => {
    const depot = fauxDepot({ evenementId: null });

    const resultat = await notifierNoteAjoutee(
      depot,
      fauxEnvoi(),
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'echecJournalisation' });
  });
});

describe('Envoi', () => {
  test('Le chemin nominal notifie et marque l’événement envoyé', async () => {
    const depot = fauxDepot();
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'notifie' });

    assert.deepEqual(envoi.appels[0], {
      destinataire: 'parent@exemple.fr',
      prenomEnfant: 'Noé',
      nomEtablissement: 'École des Lilas',
    });

    assert.deepEqual(depot.ecritures.at(-1), {
      nom: 'marquerEvenement',
      id: 'evenement-1',
      statut: 'envoye',
      envoyeLe: '2026-08-23T12:00:00.000Z',
    });
  });

  test('Un parent sans email : événement marqué échoué, mais pas une erreur', async () => {
    const depot = fauxDepot({ emailParent: null });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    // La note reste enregistrée côté base : ne pas pouvoir prévenir
    // n'annule pas ce que l'établissement a écrit.
    assert.deepEqual(resultat, { statut: 'sansDestinataire' });
    assert.equal(envoi.appels.length, 0);

    assert.deepEqual(depot.ecritures.at(-1), {
      nom: 'marquerEvenement',
      id: 'evenement-1',
      statut: 'echoue',
      envoyeLe: null,
    });
  });

  test('Un refus du service d’email marque l’événement échoué', async () => {
    const depot = fauxDepot();
    const envoi = fauxEnvoi({
      envoye: false,
      statut: 401,
      detail: 'Key not found',
    });

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, {
      statut: 'echecEnvoi',
      detail: 'Key not found',
    });

    assert.equal(depot.ecritures.at(-1).statut, 'echoue');
  });

  test('Un établissement sans nom ne bloque pas l’envoi', async () => {
    const depot = fauxDepot({ nomEtablissement: null });
    const envoi = fauxEnvoi();

    const resultat = await notifierNoteAjoutee(
      depot,
      envoi,
      ENTREE,
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'notifie' });
    assert.equal(envoi.appels[0].nomEtablissement, 'l’établissement');
  });

  test('Un enfant sans prénom ne bloque pas l’envoi', async () => {
    const depot = fauxDepot({
      enfant: { prenom: null, parent_id: 'parent-1' },
    });
    const envoi = fauxEnvoi();

    await notifierNoteAjoutee(depot, envoi, ENTREE, MAINTENANT);

    assert.equal(envoi.appels[0].prenomEnfant, 'Votre enfant');
  });

  test('Le nom de famille de l’enfant ne peut pas être transmis', async () => {
    // Le dépôt ne lit que le prénom : même si la table en contenait un,
    // la logique n'y a pas accès.
    const depot = fauxDepot({
      enfant: { prenom: 'Noé', parent_id: 'parent-1' },
    });
    const envoi = fauxEnvoi();

    await notifierNoteAjoutee(depot, envoi, ENTREE, MAINTENANT);

    assert.deepEqual(Object.keys(envoi.appels[0]), [
      'destinataire',
      'prenomEnfant',
      'nomEtablissement',
    ]);
  });
});
