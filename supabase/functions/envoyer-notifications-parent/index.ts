// Edge Function "envoyer-notifications-parent"
//
// Envoie les notifications parent qui attendent dans
// `evenements_notification_parent`.
//
// POURQUOI ELLE EXISTE
//
// Cette table est le point de passage unique de toute notification
// parent. `notifier-note-ajoutee` y ecrit ET envoie, parce que c'est
// l'application qui l'appelle. Mais `acces_secours_declenche` est pose
// par la fonction en base, quand un professionnel appuie sur
// « L'enfant part avec les secours » — et personne ne le lisait.
//
// Autrement dit : le parent n'etait prevenu de rien. Pour l'acces
// secours, c'est le pire endroit possible ou avoir ce defaut.
//
// QUI L'APPELLE
//
// Une tache planifiee chez OVH, toutes les cinq minutes. Choix de
// Fanny (28/08/2026) : le planificateur de Supabase reposerait sur
// deux extensions Postgres et une cle rangee dans le coffre de la
// base, ce qui pese sur son dossier d'hebergement de donnees de sante.
// Chez OVH, rien n'entre dans la base et la cle reste dehors.
//
// C'est un FILET, pas le canal principal : les fonctions qui creent un
// evenement envoient dans la foulee. Le passage periodique rattrape ce
// qui serait tombe — une panne reseau, une application fermee au
// mauvais moment.
//
// COMMENT ELLE SE PROTEGE
//
// Une cle partagee, dediee au planificateur, dans l'en-tete
// `x-cle-planificateur`. Ce n'est PAS la cle de service : si le
// serveur OVH etait compromis, ce qui fuiterait ne donnerait aucun
// acces a la base — seulement le droit de declencher un envoi de
// messages deja prets.
//
// Deployee SANS verification de jeton, puisque l'appelant n'est pas un
// utilisateur connecte :
//   supabase functions deploy envoyer-notifications-parent \
//     --no-verify-jwt
//
// Variables d'environnement requises (Supabase -> Project Settings ->
// Edge Functions -> Secrets) :
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   BREVO_API_KEY, BREVO_SENDER_EMAIL, BREVO_SENDER_NAME
//   BREVO_REPLY_TO_EMAIL   optionnelle
//   CLE_PLANIFICATEUR      la cle partagee avec la tache OVH

import {
  estPreflight,
  reponseJson,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import {
  lireConfigurationBaseServiceSeul,
  lireConfigurationEmail,
} from '../_enveloppe/environnement.mts';

import { clientServiceRole } from '../_enveloppe/supabase.mts';

import { depotNotificationsEnAttenteSupabase } from '../_enveloppe/depot_notifications_en_attente.mts';

import { envoyerNotificationsEnAttente } from '../_logique/notifications_en_attente.mts';

/// Combien de messages au maximum par passage.
///
/// Cinquante : bien au-dela du volume reel, et assez bas pour qu'un
/// passage ne depasse jamais le temps alloue a une fonction serveur.
/// Ce qui reste part au passage suivant, cinq minutes plus tard.
const LIMITE_PAR_PASSAGE = 50;

Deno.serve(async (requete) => {
  if (estPreflight(requete)) {
    return reponsePreflight();
  }

  if (requete.method !== 'POST') {
    return reponseJson({ error: 'Methode non autorisee.' }, 405);
  }

  const cleAttendue = Deno.env.get('CLE_PLANIFICATEUR');

  if (!cleAttendue) {
    console.error('CLE_PLANIFICATEUR manquante.');
    return reponseJson({ error: 'Configuration incomplete.' }, 500);
  }

  // Message volontairement muet : un appelant qui se trompe de cle
  // n'apprend rien de plus qu'un refus.
  if (requete.headers.get('x-cle-planificateur') !== cleAttendue) {
    return reponseJson({ error: 'Refuse.' }, 401);
  }

  const base = lireConfigurationBaseServiceSeul();
  const email = lireConfigurationEmail();

  if (!base || !email) {
    console.error(
      'SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY ou BREVO_* manquant.',
    );
    return reponseJson({ error: 'Configuration incomplete.' }, 500);
  }

  const bilan = await envoyerNotificationsEnAttente(
    depotNotificationsEnAttenteSupabase(
      clientServiceRole(base),
      email,
    ),
    new Date(),
    LIMITE_PAR_PASSAGE,
  );

  // Le bilan est rendu pour que la tache planifiee puisse le
  // journaliser. Il ne contient aucun prenom, aucune adresse : des
  // compteurs, et rien d'autre.
  return reponseJson(bilan, 200);
});
