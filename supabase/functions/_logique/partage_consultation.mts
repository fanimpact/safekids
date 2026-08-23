// Consultation d'un lien de partage, par un accompagnant qui n'est pas
// authentifié — c'est tout l'intérêt du lien.
//
// Aucun import Deno, aucun SDK : les accès base entrent par
// `DepotPartages`, l'horloge par `maintenant`.
//
// Trois règles tiennent ici et nulle part ailleurs :
//
//   - L'identifiant de l'enfant n'est JAMAIS lu depuis la requête. Il
//     vient de la ligne `partages` trouvée par le token, et de nulle
//     part ailleurs. Fournir un autre identifiant ne donne accès à
//     rien.
//
//   - Token inconnu et token expiré donnent le même message. Distinguer
//     les deux reviendrait à confirmer qu'un token a existé.
//
//   - `recommandations_activite` est une photo figée au moment du
//     partage : jamais recalculée ici, le moteur de recommandations
//     n'existe qu'en Dart. Les profils ne sont donc pas chargés pour ce
//     type de fiche — c'est aussi une donnée de santé qui ne quitte pas
//     la base sans nécessité.

export const LIEN_INVALIDE = 'Lien expiré ou invalide.';

export const TYPE_RECOMMANDATIONS = 'recommandations_activite';

export interface Partage {
  id: string;
  enfant_id: string;
  type_fiche: string;
  date_expiration: string;
  contenu_fige: unknown;
  destinataire: string | null;
}

/// Ce dont la logique a besoin de la base, et rien de plus.
export interface DepotPartages {
  partageParToken(
    token: string,
  ): Promise<{ partage: Partage | null; erreur: unknown }>;

  enfant(
    enfantId: string,
  ): Promise<{ enfant: unknown | null; erreur: unknown }>;

  profilSante(enfantId: string): Promise<unknown | null>;

  profilActivites(enfantId: string): Promise<unknown | null>;

  marquerConsulte(
    partageId: string,
    horodatage: string,
  ): Promise<{ erreur: unknown }>;
}

export interface FichePartagee {
  type_fiche: string;
  destinataire: string;
  enfant: unknown;
  profil_sante: unknown | null;
  profil_activites: unknown | null;
  contenu_fige: unknown | null;
}

export type ResultatConsultation =
  | { statut: 'ok'; fiche: FichePartagee }
  | { statut: 'tokenAbsent' }
  | { statut: 'tokenInconnu' }
  | { statut: 'lienExpire' }
  | { statut: 'enfantIntrouvable' }
  | { statut: 'erreurBase' };

/// Un partage sans destinataire enregistré est traité comme un partage
/// à un particulier : c'est le cas le plus restrictif pour la mention
/// accolée aux traitements (« selon les indications du parent » plutôt
/// que « selon le PAI »).
const DESTINATAIRE_PAR_DEFAUT = 'particulier';

export async function consulterPartage(
  depot: DepotPartages,
  token: string | null,
  maintenant: Date,
): Promise<ResultatConsultation> {
  if (!token) {
    return { statut: 'tokenAbsent' };
  }

  const { partage, erreur } = await depot.partageParToken(token);

  if (erreur) {
    return { statut: 'erreurBase' };
  }

  if (!partage) {
    return { statut: 'tokenInconnu' };
  }

  if (!lienEncoreValide(partage.date_expiration, maintenant)) {
    return { statut: 'lienExpire' };
  }

  const { enfant, erreur: erreurEnfant } = await depot.enfant(
    partage.enfant_id,
  );

  if (erreurEnfant || !enfant) {
    return { statut: 'enfantIntrouvable' };
  }

  let profilSante: unknown | null = null;
  let profilActivites: unknown | null = null;

  if (partage.type_fiche !== TYPE_RECOMMANDATIONS) {
    profilSante =
      (await depot.profilSante(partage.enfant_id)) ?? null;
    profilActivites =
      (await depot.profilActivites(partage.enfant_id)) ?? null;
  }

  // Une erreur ici ne doit pas empêcher de renvoyer la fiche à
  // l'accompagnant : la date de consultation est une commodité pour le
  // parent, la fiche est ce dont dépend la sécurité de l'enfant.
  await depot.marquerConsulte(partage.id, maintenant.toISOString());

  return {
    statut: 'ok',
    fiche: {
      type_fiche: partage.type_fiche,
      destinataire: partage.destinataire ?? DESTINATAIRE_PAR_DEFAUT,
      enfant,
      profil_sante: profilSante,
      profil_activites: profilActivites,
      contenu_fige: partage.contenu_fige ?? null,
    },
  };
}

/// Une date d'expiration illisible vaut expirée : un lien dont on ne
/// sait pas dire s'il est encore valable ne doit pas s'ouvrir.
export function lienEncoreValide(
  dateExpiration: string,
  maintenant: Date,
): boolean {
  const expiration = new Date(dateExpiration);

  if (Number.isNaN(expiration.getTime())) {
    return false;
  }

  return expiration.getTime() >= maintenant.getTime();
}
