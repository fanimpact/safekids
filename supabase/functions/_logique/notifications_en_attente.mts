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

/// La date telle qu'un parent la lit, en heure locale du serveur.
///
/// Pas d'`Intl` : le fuseau d'une fonction serveur n'est pas celui du
/// parent, et une bibliothèque de formatage ne changerait rien à ce
/// problème. On écrit une date simple, et l'application reste la
/// référence pour l'heure exacte.
export function dateLisible(iso: string | null): string {
  if (!iso) {
    return 'une date que vous retrouverez dans l’application';
  }

  const date = new Date(iso);

  if (Number.isNaN(date.getTime())) {
    return 'une date que vous retrouverez dans l’application';
  }

  const jour = String(date.getUTCDate()).padStart(2, '0');
  const mois = String(date.getUTCMonth() + 1).padStart(2, '0');
  const heure = String(date.getUTCHours()).padStart(2, '0');
  const minute = String(date.getUTCMinutes()).padStart(2, '0');

  return `le ${jour}/${mois} à ${heure}h${minute}`;
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
export function messageAccesSecours(
  destinataire: string,
  prenomEnfant: string,
  expireLe: string | null,
): Message {
  return {
    destinataire,
    sujet: `Accès secours ouvert pour ${prenomEnfant}`,
    html:
      `<p>L’accès secours vient d’être ouvert pour ` +
      `<strong>${prenomEnfant}</strong>.</p>` +
      `<p>Les informations pour les secours — et rien d’autre — ` +
      `peuvent être consultées jusqu’${dateLisible(expireLe)}.</p>` +
      `<p>Ouvrez KidsRelay pour voir d’où vient cet accès, ` +
      `et le couper si vous le souhaitez.</p>`,
  };
}

/// Compose le message d'un événement, ou `null` si on ne sait pas.
///
/// Rendre `null` plutôt que d'inventer un texte : un mail vague sur un
/// enfant est pire que pas de mail du tout.
export async function composer(
  depot: DepotNotifications,
  evenement: EvenementEnAttente,
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
    );
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

    const message = await composer(depot, evenement);

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
