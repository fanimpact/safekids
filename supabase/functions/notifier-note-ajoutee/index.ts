// Edge Function "notifier-note-ajoutee"
//
// Appelee par l'app juste apres qu'un membre du personnel a enregistre
// une note rattachee a une activite ET a un enfant en particulier
// (jamais pour une note generale au groupe, enfant_id null : celle-ci
// n'est envoyee a personne). Retrouve cote serveur le prenom de
// l'enfant, le nom de l'etablissement et l'email du parent -- jamais
// transmis par le client, pour garantir qu'aucune donnee sensible ne
// peut etre injectee dans l'email envoye.
//
// Point d'entree unique pour toute notification parent (2026-08-19,
// demande de Fanny en preparation des notifications push, prevues au
// moment de la publication sur les stores) : chaque appel cree
// d'abord une ligne dans evenements_notification_parent (statut
// "en_attente"), envoie l'email, puis met a jour cette meme ligne
// ("envoye"/"echoue"). Quand le canal push sera branche, il lira/
// ecrira sur la meme table plutot que de dupliquer cette logique.
//
// Ce fichier ne contient que l'enveloppe. Les controles de droit,
// l'ordre des ecritures et le choix du statut journalise sont dans
// ../_logique/notification_note.mts, ou ils sont testes sans base.
//
// Necessite un appelant authentifie, membre actif de l'etablissement
// proprietaire de l'activite : deployee AVEC verification JWT (pas de
// --no-verify-jwt).
//   supabase functions deploy notifier-note-ajoutee
//
// Variables d'environnement requises (Supabase -> Project Settings ->
// Edge Functions -> Secrets) :
//   BREVO_API_KEY        cle API Brevo (jamais dans le code)
//   BREVO_SENDER_EMAIL   adresse expediteur verifiee dans Brevo
//   BREVO_SENDER_NAME    nom affiche comme expediteur (ex. "KidsRelay")
//   BREVO_REPLY_TO_EMAIL optionnelle : adresse de reponse si differente
//                        de l'expediteur (sinon, BREVO_SENDER_EMAIL
//                        sert aussi de reply-to)

import {
  enTeteAutorisation,
  estPreflight,
  lireCorpsJson,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import {
  lireConfigurationBase,
  lireConfigurationEmail,
} from '../_enveloppe/environnement.mts';

import {
  clientServiceRole,
  identifierAppelant,
} from '../_enveloppe/supabase.mts';

import { depotNotificationsSupabase } from '../_enveloppe/depot_notifications.mts';

import {
  envoyerParBrevo,
  messageNoteAjoutee,
} from '../_logique/emails.mts';

import { notifierNoteAjoutee } from '../_logique/notification_note.mts';

Deno.serve(async (req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  const base = lireConfigurationBase();
  const email = lireConfigurationEmail();

  if (!base || !email) {
    console.error(
      'Variable d’environnement manquante (Supabase ou Brevo).',
    );
    return reponseJson(
      { error: 'Configuration serveur incomplete.' },
      500,
    );
  }

  const autorisation = enTeteAutorisation(req);

  if (!autorisation) {
    return reponseJson({ error: 'Non authentifie.' }, 401);
  }

  const appelant = await identifierAppelant(base, autorisation);

  if (!appelant) {
    return reponseJson({ error: 'Non authentifie.' }, 401);
  }

  const corps = await lireCorpsJson(req);

  if (!corps) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  const enfantId = corps.enfantId;
  const activiteId = corps.activiteId;

  if (
    typeof enfantId !== 'string' ||
    typeof activiteId !== 'string'
  ) {
    return reponseJson({ error: 'Requete invalide.' }, 400);
  }

  const resultat = await notifierNoteAjoutee(
    depotNotificationsSupabase(clientServiceRole(base)),
    (destination) =>
      envoyerParBrevo(
        fetch,
        email,
        messageNoteAjoutee(
          destination.destinataire,
          destination.prenomEnfant,
          destination.nomEtablissement,
        ),
      ),
    {
      appelantId: appelant.id,
      enfantId,
      activiteId,
    },
    new Date(),
  );

  switch (resultat.statut) {
    case 'notifie':
      return reponseJson({ ok: true, notifie: true }, 200);

    case 'sansDestinataire':
      return reponseJson({ ok: true, notifie: false }, 200);

    case 'activiteIntrouvable':
      return reponseJson({ error: 'Activite introuvable.' }, 404);

    case 'enfantHorsActivite':
      return reponseJson(
        { error: 'Cet enfant ne fait pas partie de cette activite.' },
        400,
      );

    case 'pasMembre':
      return reponseJson(
        { error: 'Vous n’etes pas membre actif de cet etablissement.' },
        403,
      );

    case 'enfantIntrouvable':
      return reponseJson({ error: 'Enfant introuvable.' }, 404);

    case 'echecJournalisation':
      console.error(
        'Impossible de creer l’evenement de notification',
      );
      return reponseJson(
        { error: 'Impossible de journaliser la notification.' },
        500,
      );

    case 'echecEnvoi':
      console.error('Echec envoi Brevo', resultat.detail);
      return reponseJson(
        { error: 'Impossible d’envoyer la notification.' },
        502,
      );
  }
});
