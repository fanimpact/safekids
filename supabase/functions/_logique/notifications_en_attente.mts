// Les notifications parent qui attendent d'être envoyées.
//
// Le trou que ce module bouche.
//
// `evenements_notification_parent` est le point de passage unique de
// toute notification parent. `notifier-note-ajoutee` y écrit ET envoie,
// parce que c'est l'application qui l'appelle. Mais deux événements
// s'écrivent **sans que personne ne les lise** :
//
//   - `acces_secours_declenche`, posé par la fonction en base quand un
//     professionnel appuie sur « L'enfant part avec les secours » ;
//   - toute notification à venir écrite depuis une fonction serveur.
//
// Autrement dit : le parent n'est prévenu de rien. Pour l'accès
// secours, c'est le pire endroit possible où avoir ce défaut.
//
// Ce module décide quoi envoyer et dans quel ordre marquer les lignes.
// Il ne connaît ni Supabase, ni Brevo, ni l'horloge : tout entre par le
// dépôt, et il se teste sans réseau.

import type { Message, ResultatEnvoi } from './emails.mts';

/// Une ligne en attente, réduite à ce dont la décision a besoin.
export interface EvenementEnAttente {
  id: string;
  parentId: string;
  enfantId: string;
  typeEvenement: string;
  donnees: Record<string, unknown> | null;
}

/// Ce qu'il faut savoir d'un accès secours pour en parler au parent.
///
/// Volontairement pauvre : ni le nom de la personne qui a déclenché, ni
/// sa fonction, ni l'établissement. Le mail dit qu'un accès est ouvert
/// et jusqu'à quand ; **le détail se lit dans l'application**. C'est la
/// même règle que pour le contenu d'une note.
export interface ContexteAccesSecours {
  expireLe: string | null;
}

export interface DepotNotifications {
  /// Les lignes dont l'email n'est pas encore parti.
  evenementsEnAttente(
    limite: number,
  ): Promise<{ evenements: EvenementEnAttente[]; erreur: unknown }>;

  emailParent(parentId: string): Promise<string | null>;

  /// Le prénom seul. Jamais le nom de famille — règle permanente sur
  /// le contenu des emails.
  prenomEnfant(enfantId: string): Promise<string | null>;

  accesSecours(
    partageId: string,
  ): Promise<ContexteAccesSecours | null>;

  envoyer(message: Message): Promise<ResultatEnvoi>;

  marquerEnvoye(id: string, envoyeLe: string): Promise<void>;

  /// Terminal : on ne retente pas indéfiniment. Une ligne qui échoue
  /// reste lisible en base pour qu'on sache qu'elle a échoué.
  marquerEchoue(id: string): Promise<void>;
}

export interface BilanEnvoi {
  traites: number;
  envoyes: number;
  echoues: number;

  /// Un type d'événement qu'on ne sait pas mettre en mots, ou une
  /// ligne à laquelle il manque de quoi écrire. Marquée échouée pour
  /// ne pas la reprendre toutes les cinq minutes jusqu'à la fin des
  /// temps.
  ignores: number;
}

/// Le fuseau dans lequel les dates sont écrites aux parents.
///
/// **Fixé, et pas celui du serveur.** Une fonction serveur tourne en
/// UTC : une échéance à 22h30 heure française s'affichait « 20h30 »
/// dans le mail. Sur un message d'accès secours, un parent qui lit une
/// heure fausse est un défaut grave — c'est exactement l'information
/// dont il a besoin pour savoir jusqu'à quand la fiche circule.
///
/// Constaté le 28/08/2026 sur le premier mail réel.
///
/// C'est une hypothèse assumée : KidsRelay s'adresse à des familles en
/// France. Un parent à l'étranger lirait l'heure française, ce qui
/// reste plus juste que l'heure UTC, et l'application affiche de toute
/// façon l'heure de son téléphone.
export const FUSEAU_PARENTS = 'Europe/Paris';

/// La date telle qu'un parent la lit, ou `null` si on ne sait pas.
///
/// Rendue **sans article** : c'est la phrase qui l'accueille qui
/// décide de dire « le » ou « au ». Le mail annonçait « jusqu'le
/// 28/08 » tant que cette fonction portait son propre « le ».
export function dateLisible(iso: string | null): string | null {
  if (!iso) {
    return null;
  }

  const date = new Date(iso);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  const parties = new Intl.DateTimeFormat('fr-FR', {
    timeZone: FUSEAU_PARENTS,
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);

  const valeur = (type: string) =>
    parties.find((partie) => partie.type === type)?.value ?? '';

  return `${valeur('day')}/${valeur('month')} à ` +
    `${valeur('hour')}h${valeur('minute')}`;
}

/// L'accès est-il déjà terminé au moment où l'on écrit ?
///
/// Une échéance illisible ou absente rend `false` : on ne déclare
/// pas terminé ce qu'on ne sait pas situer dans le temps.
export function dejaTermine(
  expireLe: string | null,
  maintenant: Date,
): boolean {
  if (!expireLe) {
    return false;
  }

  const fin = new Date(expireLe);

  if (Number.isNaN(fin.getTime())) {
    return false;
  }

  return fin.getTime() <= maintenant.getTime();
}

/// L'accès secours vient d'être ouvert.
///
/// Le prénom seul dans l'objet, décision de Fanny du 28/08/2026 : sans
/// lui, un parent de trois enfants ne saurait pas lequel est concerné
/// au moment précis où il doit le savoir.
///
/// Ni nom de famille, ni donnée de santé, ni qui a déclenché. Le
/// parent ouvre l'application pour le reste — c'est ce qui garantit
/// qu'une information sur son enfant ne traîne pas dans une boîte
/// mail.
///
/// [maintenant] sert à une seule chose : savoir si l'accès est
/// **déjà terminé** au moment de l'envoi. Ce cas n'arrive que si
/// l'envoi immédiat a échoué et que le filet horaire a échoué à son
/// tour pendant plus de vingt-quatre heures — vingt-quatre échecs
/// consécutifs. Rare, mais le message annoncerait alors une date
/// passée sur le sujet le plus sensible du produit.
///
/// Repéré le 28/08/2026 par Fanny, sur un mail de test dont la date
/// était effectivement dépassée.
export function messageAccesSecours(
  destinataire: string,
  prenomEnfant: string,
  expireLe: string | null,
  maintenant: Date,
): Message {
  const fin = dateLisible(expireLe);
  const termine = dejaTermine(expireLe, maintenant);

  const echeance = fin
    ? `jusqu’au ${fin}`
    : 'jusqu’à une échéance que vous retrouverez dans l’application';

  return {
    destinataire,
    sujet: `Accès secours ouvert pour ${prenomEnfant}`,
    html:
      `<p>L’accès secours vient d’être ouvert pour ` +
      `<strong>${prenomEnfant}</strong>.</p>` +
      (termine
        ? `<p>Cet accès est <strong>maintenant terminé</strong> : ` +
          `les informations pour les secours ne sont plus ` +
          `consultables.</p>`
        : `<p>Les informations pour les secours — et rien ` +
          `d’autre — peuvent être consultées ${echeance}.</p>`) +
      `<p>Ouvrez KidsRelay pour voir d’où vient cet accès, ` +
      `et le couper si vous le souhaitez.</p>`,
    // Un message qui n'existe qu'en HTML est un signal de courrier
    // indésirable pour une partie des filtres. Le doubler en texte
    // simple ne coûte rien et enlève ce reproche.
    texte:
      `L’accès secours vient d’être ouvert pour ${prenomEnfant}.\n\n` +
      (termine
        ? `Cet accès est maintenant terminé : les informations ` +
          `pour les secours ne sont plus consultables.\n\n`
        : `Les informations pour les secours — et rien d’autre — ` +
          `peuvent être consultées ${echeance}.\n\n`) +
      `Ouvrez KidsRelay pour voir d’où vient cet accès, ` +
      `et le couper si vous le souhaitez.`,
  };
}

/// Une demande d'accès attend la réponse du parent.
///
/// **La raison saisie n'y figure pas.** Elle est écrite par une
/// personne inconnue et pourrait contenir n'importe quoi ; la règle
/// permanente interdit toute donnée de santé ou nom de famille dans
/// un email. Elle se lit dans l'application, et nulle part ailleurs.
///
/// Le prénom, lui, reste dans l'objet : sans lui, un parent de trois
/// enfants ne saurait pas lequel est concerné. Même règle que pour
/// l'accès secours.
export function messageDemandeAcces(
  destinataire: string,
  prenomEnfant: string,
): Message {
  return {
    destinataire,
    sujet: `Une demande d’accès attend votre réponse — ${prenomEnfant}`,
    html:
      `<p>Quelqu’un demande à ouvrir la fiche de ` +
      `<strong>${prenomEnfant}</strong> sur un appareil de plus.</p>` +
      `<p>Ouvrez KidsRelay pour voir qui c’est, et autoriser ou non ` +
      `cet appareil. Tant que vous ne répondez pas, l’accès reste ` +
      `fermé.</p>`,
    texte:
      `Quelqu’un demande à ouvrir la fiche de ${prenomEnfant} sur ` +
      `un appareil de plus.

` +
      `Ouvrez KidsRelay pour voir qui c’est, et autoriser ou non ` +
      `cet appareil. Tant que vous ne répondez pas, l’accès reste ` +
      `fermé.`,
  };
}

/// Compose le message d'un événement, ou `null` si on ne sait pas.
///
/// Rendre `null` plutôt que d'inventer un texte : un mail vague sur un
/// enfant est pire que pas de mail du tout.
export async function composer(
  depot: DepotNotifications,
  evenement: EvenementEnAttente,
  maintenant: Date,
): Promise<Message | null> {
  const destinataire = await depot.emailParent(evenement.parentId);

  if (!destinataire) {
    return null;
  }

  if (evenement.typeEvenement === 'acces_secours_declenche') {
    const prenom = await depot.prenomEnfant(evenement.enfantId);

    if (!prenom) {
      return null;
    }

    const partageId = evenement.donnees?.partageId;

    const contexte =
      typeof partageId === 'string'
        ? await depot.accesSecours(partageId)
        : null;

    return messageAccesSecours(
      destinataire,
      prenom,
      contexte?.expireLe ?? null,
      maintenant,
    );
  }

  if (evenement.typeEvenement === 'demande_acces_partage') {
    const prenom = await depot.prenomEnfant(evenement.enfantId);

    if (!prenom) {
      return null;
    }

    return messageDemandeAcces(destinataire, prenom);
  }

  return null;
}

/// Envoie ce qui attend, et marque chaque ligne.
///
/// **Une ligne à la fois, séquentiellement.** Le débit n'est pas
/// l'enjeu — quelques mails par jour — et un envoi en parallèle
/// rendrait deux passages simultanés capables d'envoyer deux fois le
/// même message.
///
/// **Marquer après l'envoi, jamais avant.** Une ligne marquée envoyée
/// dont le mail n'est pas parti est perdue pour toujours ; une ligne
/// envoyée deux fois est seulement désagréable. Entre les deux, le
/// choix est vite fait.
export async function envoyerNotificationsEnAttente(
  depot: DepotNotifications,
  maintenant: Date,
  limite = 50,
): Promise<BilanEnvoi> {
  const bilan: BilanEnvoi = {
    traites: 0,
    envoyes: 0,
    echoues: 0,
    ignores: 0,
  };

  const { evenements, erreur } = await depot.evenementsEnAttente(limite);

  if (erreur) {
    return bilan;
  }

  for (const evenement of evenements) {
    bilan.traites++;

    const message = await composer(depot, evenement, maintenant);

    if (!message) {
      bilan.ignores++;
      await depot.marquerEchoue(evenement.id);
      continue;
    }

    const resultat = await depot.envoyer(message);

    if (resultat.envoye) {
      bilan.envoyes++;
      await depot.marquerEnvoye(evenement.id, maintenant.toISOString());
    } else {
      bilan.echoues++;
      await depot.marquerEchoue(evenement.id);
    }
  }

  return bilan;
}
