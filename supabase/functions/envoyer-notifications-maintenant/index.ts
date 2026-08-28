// Edge Function "envoyer-notifications-maintenant"
//
// Demande que les notifications en attente partent tout de suite,
// sans attendre le passage horaire du filet.
//
// POURQUOI ELLE EXISTE
//
// L'accès secours déclenché **depuis l'application** est le seul cas
// où la ligne de notification est écrite par la base, dans la même
// transaction que l'accès — et non par une fonction serveur qui
// pourrait envoyer dans la foulée.
//
// Sans elle, ce déclenchement-là attendrait le passage de l'heure.
// Dire à un parent que son enfant part avec les pompiers cinquante
// minutes plus tard n'est pas acceptable.
//
// POURQUOI ELLE EST DISTINCTE DE `envoyer-notifications-parent`
//
// L'autre est appelée par la tâche planifiée d'OVH et se protège par
// une clé partagée. Une application installée ne peut pas garder de
// clé : ce qui est dans l'application est public. Celle-ci se protège
// donc autrement — par le compte de la personne connectée.
//
// CE QU'ELLE PERMET, ET CE QU'ELLE NE PERMET PAS
//
// Elle ne rend aucune donnée : des compteurs, rien d'autre. Elle
// n'écrit rien de nouveau. Tout ce qu'elle fait, c'est avancer l'envoi
// de messages **déjà préparés** par la base. Un appel de trop ne
// révèle rien et ne fait rien partir qui n'allait pas partir.
//
// Déployée AVEC vérification du jeton — c'est le compte connecté qui
// l'autorise, et la plateforme s'en charge avant nous :
//   supabase functions deploy envoyer-notifications-maintenant

import {
  enTeteAutorisation,
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

/// Celui qu'on vient d'écrire, et de quoi rattraper quelques
/// retardataires. Assez bas pour qu'un appel ne déclenche jamais un
/// travail sans bornes.
const LIMITE = 5;

Deno.serve(async (requete) => {
  if (estPreflight(requete)) {
    return reponsePreflight();
  }

  if (requete.method !== 'POST') {
    return reponseJson({ error: 'Methode non autorisee.' }, 405);
  }

  // Ceinture et bretelles : la plateforme a déjà refusé les appels
  // sans jeton valide, mais une fonction ne doit pas dépendre d'un
  // drapeau de déploiement pour être sûre.
  if (!enTeteAutorisation(requete)) {
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
    LIMITE,
  );

  return reponseJson(bilan, 200);
});
