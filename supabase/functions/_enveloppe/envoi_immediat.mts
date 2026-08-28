// Envoyer sans attendre le passage de l'heure.
//
// La tâche planifiée d'OVH est un **filet**, pas le canal normal :
// elle ne passe qu'une fois par heure, et c'est une limite de
// l'hébergement mutualisé, pas un choix. Attendre l'heure pour dire à
// un parent que son enfant part avec les pompiers serait absurde.
//
// Ce module est donc appelé par les fonctions qui viennent d'écrire un
// événement, juste après leur réponse.
//
// **Après la réponse, et c'est tout l'enjeu.** La personne qui
// déclenche un accès secours attend son code à l'écran : elle ne doit
// pas patienter pendant qu'un email part. `EdgeRuntime.waitUntil`
// laisse la fonction rendre sa réponse et poursuivre le travail
// derrière.

import {
  lireConfigurationBaseServiceSeul,
  lireConfigurationEmail,
} from './environnement.mts';

import { clientServiceRole } from './supabase.mts';

import { depotNotificationsEnAttenteSupabase } from './depot_notifications_en_attente.mts';

import { envoyerNotificationsEnAttente } from '../_logique/notifications_en_attente.mts';

/// Combien d'événements au maximum par envoi immédiat.
///
/// Cinq : celui qu'on vient d'écrire, et de quoi rattraper au passage
/// quelques retardataires. Assez bas pour qu'une requête utilisateur
/// ne déclenche jamais un travail sans bornes.
const LIMITE_IMMEDIATE = 5;

/// Type minimal du global fourni par la plateforme Supabase.
declare const EdgeRuntime:
  | { waitUntil(promesse: Promise<unknown>): void }
  | undefined;

/// Lance l'envoi en tâche de fond, sans jamais faire échouer l'appelant.
///
/// **Un échec d'envoi ne remet rien en cause.** L'accès secours est
/// ouvert, la personne a son code : c'est une urgence, elle passe
/// avant la notification. Le filet horaire reprendra ce qui n'est pas
/// parti — c'est exactement ce pour quoi il existe.
export function envoyerNotificationsEnFond(): void {
  const base = lireConfigurationBaseServiceSeul();
  const email = lireConfigurationEmail();

  if (!base || !email) {
    console.error(
      'Envoi immédiat impossible : configuration incomplète.',
    );
    return;
  }

  const travail = envoyerNotificationsEnAttente(
    depotNotificationsEnAttenteSupabase(
      clientServiceRole(base),
      email,
    ),
    new Date(),
    LIMITE_IMMEDIATE,
  ).catch((erreur) => {
    console.error('Envoi immédiat échoué', erreur);
  });

  // Sans `waitUntil`, la plateforme peut interrompre la fonction dès
  // sa réponse rendue, et l'envoi mourrait au milieu. Le repli attend
  // le travail : plus lent pour l'appelant, mais jamais muet.
  if (typeof EdgeRuntime !== 'undefined' && EdgeRuntime) {
    EdgeRuntime.waitUntil(travail);
  }
}
