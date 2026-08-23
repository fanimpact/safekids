// Notification envoyée au parent quand un établissement ajoute une
// note rattachée à son enfant.
//
// Aucun import Deno, aucun SDK, aucun appel réseau direct : les accès
// base entrent par `DepotNotifications`, l'envoi par `EnvoiEmail`,
// l'horloge par `maintenant`.
//
// Deux règles tiennent ici et nulle part ailleurs :
//
//   - Le service_role contourne le RLS. Tout contrôle de droit que le
//     RLS assurait doit donc être refait explicitement : que l'enfant
//     fasse partie de l'activité, et que l'appelant soit membre actif
//     de l'établissement propriétaire.
//
//   - La ligne d'événement est créée AVANT toute tentative d'envoi,
//     qu'un email exploitable existe ou non. C'est elle qui fait foi de
//     « cette notification a été déclenchée », indépendamment du canal.
//     Quand le canal push sera branché, il lira et écrira sur la même
//     table plutôt que de dupliquer cette logique.

export interface Activite {
  etablissement_id: string | null;
  enfants_ids: unknown;
}

export interface Enfant {
  prenom: string | null;
  parent_id: string | null;
}

/// Ce dont la logique a besoin de la base, et rien de plus.
export interface DepotNotifications {
  activite(activiteId: string): Promise<Activite | null>;

  estMembreActif(
    etablissementId: string,
    userId: string,
  ): Promise<boolean>;

  enfant(enfantId: string): Promise<Enfant | null>;

  nomEtablissement(
    etablissementId: string,
  ): Promise<string | null>;

  emailParent(parentId: string): Promise<string | null>;

  creerEvenement(entree: {
    parentId: string;
    enfantId: string;
    typeEvenement: string;
    donnees: Record<string, unknown>;
  }): Promise<{ id: string | null; erreur: unknown }>;

  marquerEvenement(
    id: string,
    statut: 'envoye' | 'echoue',
    envoyeLe: string | null,
  ): Promise<void>;
}

/// L'envoi effectif, injecté pour que les tests décrivent la réponse du
/// service d'email sans réseau.
export type EnvoiEmail = (entree: {
  destinataire: string;
  prenomEnfant: string;
  nomEtablissement: string;
}) => Promise<{ envoye: boolean; statut: number; detail: string | null }>;

export type ResultatNotification =
  | { statut: 'notifie' }
  | { statut: 'sansDestinataire' }
  | { statut: 'activiteIntrouvable' }
  | { statut: 'enfantHorsActivite' }
  | { statut: 'pasMembre' }
  | { statut: 'enfantIntrouvable' }
  | { statut: 'echecJournalisation' }
  | { statut: 'echecEnvoi'; detail: string | null };

/// Repli quand l'établissement n'a pas de nom renseigné : un email qui
/// dit « par l'établissement » vaut mieux qu'un email qui dit « par
/// null », et mieux qu'un email non envoyé.
const ETABLISSEMENT_SANS_NOM = 'l’établissement';
const ENFANT_SANS_PRENOM = 'Votre enfant';

export async function notifierNoteAjoutee(
  depot: DepotNotifications,
  envoyer: EnvoiEmail,
  entree: {
    appelantId: string;
    enfantId: string;
    activiteId: string;
  },
  maintenant: Date,
): Promise<ResultatNotification> {
  const activite = await depot.activite(entree.activiteId);

  if (!activite?.etablissement_id) {
    return { statut: 'activiteIntrouvable' };
  }

  const enfantsIds = activite.enfants_ids;

  if (
    !Array.isArray(enfantsIds) ||
    !enfantsIds.includes(entree.enfantId)
  ) {
    return { statut: 'enfantHorsActivite' };
  }

  const membre = await depot.estMembreActif(
    activite.etablissement_id,
    entree.appelantId,
  );

  if (!membre) {
    return { statut: 'pasMembre' };
  }

  const enfant = await depot.enfant(entree.enfantId);

  if (!enfant?.parent_id) {
    return { statut: 'enfantIntrouvable' };
  }

  const nomEtablissement = await depot.nomEtablissement(
    activite.etablissement_id,
  );

  const emailParent = await depot.emailParent(enfant.parent_id);

  const { id: evenementId, erreur } = await depot.creerEvenement({
    parentId: enfant.parent_id,
    enfantId: entree.enfantId,
    typeEvenement: 'note_ajoutee',
    donnees: {
      activiteId: entree.activiteId,
      etablissementId: activite.etablissement_id,
    },
  });

  if (erreur || !evenementId) {
    return { statut: 'echecJournalisation' };
  }

  if (!emailParent) {
    await depot.marquerEvenement(evenementId, 'echoue', null);

    // Rien à notifier, mais la note reste bien enregistrée côté base
    // (déjà fait avant cet appel) : ce n'est pas une erreur bloquante.
    return { statut: 'sansDestinataire' };
  }

  const resultat = await envoyer({
    destinataire: emailParent,
    prenomEnfant: enfant.prenom ?? ENFANT_SANS_PRENOM,
    nomEtablissement: nomEtablissement ?? ETABLISSEMENT_SANS_NOM,
  });

  if (!resultat.envoye) {
    await depot.marquerEvenement(evenementId, 'echoue', null);

    return { statut: 'echecEnvoi', detail: resultat.detail };
  }

  await depot.marquerEvenement(
    evenementId,
    'envoye',
    maintenant.toISOString(),
  );

  return { statut: 'notifie' };
}
