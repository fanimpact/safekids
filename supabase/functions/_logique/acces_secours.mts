// Le déclenchement d'un accès secours, par le détenteur d'un lien.
//
// Ce que cela règle, et que rien d'autre ne réglait : ce n'est pas la
// maîtresse qui accompagne l'enfant dans l'ambulance. Elle ne peut pas
// quitter sa classe. C'est l'ATSEM qui monte, et elle n'a aucun accès.
// Le parent est prévenu mais il conduit. La demande d'accès pour un
// tiers ne sert à rien ici : elle attend une réponse.
//
// D'où un geste qui **n'attend pas le parent**, ouvert seulement si
// celui-ci l'a préautorisé à froid, à la création du partage.
//
// Ce que ce module ne fait pas, et c'est délibéré : il ne décide pas de
// ce que l'accès dérivé contient ni de combien de temps il vit. Ces
// règles sont dans `declencher_acces_secours`, en base, parce qu'elles
// doivent tenir même si un jour un autre appelant s'adresse à la même
// table.
//
// Ce module vérifie **qui a le droit de déclencher**, et rien de plus.

import { decisionVerrou } from './verrou_partage.mts';
import { empreinteDuSecret } from './verrou_partage.mts';

import type { PlacePartage } from './verrou_partage.mts';

/// Le partage d'origine, tel que la décision en a besoin.
export interface PartageSource {
  id: string;
  enfant_id: string;
  date_expiration: string | null;
  permanent: boolean;
  revoque_le: string | null;
  declenche_en_secours: boolean;
}

export interface AccesSecoursCree {
  token: string;
  expireLe: string;
}

/// Ce dont la logique a besoin, et rien de plus.
export interface DepotAccesSecours {
  partageParToken(
    token: string,
  ): Promise<{ partage: PartageSource | null; erreur: unknown }>;

  placesDuPartage(
    partageId: string,
  ): Promise<{ places: PlacePartage[]; erreur: unknown }>;

  /// La preautorisation, portee par l'ENFANT et non par le partage :
  /// le parent la donne une fois, apres le questionnaire sante, et
  /// elle vaut pour tous les partages de cet enfant. Sur chaque
  /// partage, il aurait fallu y penser a chaque fois — et le jour de
  /// l'oubli serait le jour de l'accident.
  accesSecoursAutorise(
    enfantId: string,
  ): Promise<{ autorise: boolean; erreur: unknown }>;

  /// Crée l'accès dérivé. Les règles de contenu et de durée sont en
  /// base, pas ici.
  creerAccesSecours(
    partageId: string,
  ): Promise<{ acces: AccesSecoursCree | null; erreur: unknown }>;

  /// Prévient le parent. Notifié, jamais consulté.
  notifierParent(
    partageId: string,
    enfantId: string,
  ): Promise<void>;
}

export type ResultatDeclenchement =
  | { statut: 'ok'; acces: AccesSecoursCree }
  | { statut: 'tokenAbsent' }
  | { statut: 'tokenInconnu' }
  | { statut: 'lienFini' }
  /// Le parent n'a pas donné la préautorisation. Ce n'est pas une
  /// erreur de l'appelant : c'est un choix du parent, et le message
  /// doit le dire ainsi.
  | { statut: 'nonAutorise' }
  /// Celui qui demande ne détient pas ce partage. Sans ce contrôle,
  /// n'importe qui connaissant l'adresse déclencherait un accès
  /// secours sur l'enfant d'un autre.
  | { statut: 'pasDetenteur' }
  | { statut: 'erreurBase' };

export async function declencherAccesSecours(
  depot: DepotAccesSecours,
  token: string | null,
  secretPresente: string | null,
  maintenant: Date,
): Promise<ResultatDeclenchement> {
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

  // Un lien mort ne déclenche rien. Révoqué et expiré se répondent
  // pareil : rien ne doit laisser deviner que le parent a coupé.
  if (partage.revoque_le) {
    return { statut: 'lienFini' };
  }

  if (!partage.permanent) {
    const expiration = partage.date_expiration
      ? new Date(partage.date_expiration)
      : null;

    if (
      !expiration ||
      Number.isNaN(expiration.getTime()) ||
      expiration.getTime() < maintenant.getTime()
    ) {
      return { statut: 'lienFini' };
    }
  }

  // Un accès secours n'en déclenche pas un autre. La base le refuse
  // aussi ; on le dit ici pour rendre le refus lisible plutôt que de
  // laisser remonter une exception.
  if (partage.declenche_en_secours) {
    return { statut: 'nonAutorise' };
  }

  const { autorise, erreur: erreurAutorisation } =
    await depot.accesSecoursAutorise(partage.enfant_id);

  if (erreurAutorisation) {
    return { statut: 'erreurBase' };
  }

  if (!autorise) {
    return { statut: 'nonAutorise' };
  }

  // **Le contrôle qui compte.** Celui qui déclenche doit détenir une
  // place sur ce partage — c'est-à-dire l'avoir ouvert. Sans lui,
  // quiconque devine ou intercepte une adresse ouvrirait un accès
  // secours de 24 heures sur l'enfant d'un autre.
  const { places, erreur: erreurPlaces } = await depot.placesDuPartage(
    partage.id,
  );

  if (erreurPlaces) {
    return { statut: 'erreurBase' };
  }

  const empreintePresentee = secretPresente
    ? await empreinteDuSecret(secretPresente)
    : null;

  const decision = decisionVerrou({
    places,
    // Le déclenchement ne prend pas de place et n'en libère pas : on
    // demande seulement « ce secret est-il l'un des nôtres ? ».
    appareilsMax: places.length,
    empreintePresentee,
    maintenant,
  });

  if (decision.action !== 'accepter') {
    return { statut: 'pasDetenteur' };
  }

  const { acces, erreur: erreurCreation } =
    await depot.creerAccesSecours(partage.id);

  if (erreurCreation || !acces) {
    return { statut: 'erreurBase' };
  }

  // Après la création, jamais avant : un parent prévenu d'un accès qui
  // n'existe pas irait chercher dans sa liste quelque chose
  // d'introuvable. L'échec d'envoi ne remet pas l'accès en cause —
  // c'est une urgence, elle passe avant la notification.
  await depot.notifierParent(partage.id, partage.enfant_id);

  return { statut: 'ok', acces };
}
