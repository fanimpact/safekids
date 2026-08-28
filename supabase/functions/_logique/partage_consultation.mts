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

import {
  decisionVerrou,
  empreinteDuSecret,
} from './verrou_partage.mts';

import type { PlacePartage } from './verrou_partage.mts';

import {
  TYPE_RECOMMANDATIONS,
  enfantPourFiche,
  profilActivitesPourFiche,
  profilSantePourFiche,
} from './fiche_partagee.mts';

export const LIEN_INVALIDE = 'Lien expiré ou invalide.';

/// Message du lien deja pris par un autre appareil.
///
/// Volontairement distinct de LIEN_INVALIDE : celui qui tient le lien
/// n'a rien fait de mal, et doit comprendre quoi faire. « Lien
/// invalide » l'aurait laisse croire a une panne, et il aurait
/// reessaye au lieu de rappeler le parent.
export const LIEN_VERROUILLE =
  'Ce lien a déjà été ouvert depuis un autre appareil et ne peut plus ' +
  'servir ailleurs. Demandez un nouveau lien au parent.';

/// Un code à scanner vaut cinq minutes. Passé ce délai sans avoir
/// servi, il ne mène plus nulle part.
///
/// Distinct du lien expiré : là, c'est l'accès lui-même qui a pris
/// fin et il n'y a rien à demander. Ici le parent est à côté, il
/// lui suffit de rafficher un code — et le dire évite un appel.
export const CODE_EXPIRE =
  'Ce code à scanner n’est plus valable. Demandez au parent, qui ' +
  'est à côté de vous, d’en afficher un nouveau.';

export { TYPE_RECOMMANDATIONS };

export interface Partage {
  id: string;
  enfant_id: string;
  type_fiche: string;

  /// Nulle si et seulement si le lien est permanent.
  date_expiration: string | null;

  contenu_fige: unknown;
  destinataire: string | null;

  /// Renseignee = le parent a revoque. L'acces est coupe, meme si la
  /// date d'expiration n'est pas atteinte.
  revoque_le: string | null;

  /// Lien sans date de fin. Seule la revocation l'arrete.
  permanent: boolean;

  /// Nombre d'appareils autorises : 1, 2 ou 5, choisi par le parent.
  appareils_max: number;

  /// Cette ligne EST un acces secours derive. Elle n'en declenche pas
  /// un autre.
  declenche_en_secours: boolean;

  /// Jusqu'a quand ce code peut etre scanne pour la PREMIERE fois.
  ///
  /// Nulle pour un lien ordinaire, qui n'a pas de fenetre. Sans
  /// rapport avec `date_expiration`, qui porte la duree de l'acces
  /// une fois accorde : les deux durees ne se melangent jamais,
  /// parce qu'elles ne sont pas dans la meme colonne.
  utilisable_jusqu_a: string | null;
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

  /// Les places deja occupees sur ce partage.
  placesDuPartage(
    partageId: string,
  ): Promise<{ places: PlacePartage[]; erreur: unknown }>;

  /// Occupe une place libre. `prisLe` est sa date de premiere
  /// occupation, et ne sera plus jamais reecrite.
  prendrePlace(
    partageId: string,
    empreinte: string,
    prisLe: string,
  ): Promise<{ erreur: unknown }>;

  /// Remplace l'empreinte d'une place, **sans toucher a sa date**.
  /// C'est ce qui empeche la fenetre de tolerance de glisser.
  remplacerPlace(
    placeId: string,
    empreinte: string,
  ): Promise<{ erreur: unknown }>;

  /// Une ouverture depuis un autre appareil. `toleree` distingue la
  /// reprise dans la fenetre des quinze minutes d'un vrai refus : le
  /// parent voit les deux, mais pas de la meme facon.
  journaliserTentative(entree: {
    partageId: string;
    tenteeLe: string;
    toleree: boolean;

    /// La personne a demandé à reprendre l'accès. Le parent ne lit
    /// pas la même chose selon qu'un lien a été rouvert tout seul
    /// dans le quart d'heure ou que quelqu'un a repris la main des
    /// heures après.
    reprise?: boolean;
  }): Promise<void>;

  /// Prévient le parent qu'un autre appareil a repris l'accès.
  ///
  /// C'est elle qui rend la reprise acceptable : sans notification,
  /// ce serait un affaiblissement muet. Le parent reste maître — il
  /// coupe d'un geste depuis sa liste.
  notifierRepriseAcces(
    partageId: string,
    enfantId: string,
  ): Promise<void>;

  /// La preautorisation de l'acces secours, portee par l'enfant.
  accesSecoursAutorise(
    enfantId: string,
  ): Promise<{ autorise: boolean; erreur: unknown }>;

  /// Une ligne par ouverture, jamais ecrasee — a la difference de
  /// [marquerConsulte], qui ne garde que la derniere.
  ///
  /// Ce qui y entre : l'enfant, le partage, le type de fiche, la date.
  /// Rien d'autre. Pas d'adresse IP, pas d'empreinte de navigateur.
  journaliserOuverture(entree: {
    enfantId: string;
    partageId: string;
    typeFiche: string;
    ouvertLe: string;
  }): Promise<void>;
}

export interface FichePartagee {
  type_fiche: string;
  destinataire: string;
  enfant: unknown;
  profil_sante: unknown | null;
  profil_activites: unknown | null;
  contenu_fige: unknown | null;

  /// Vrai si le detenteur peut ouvrir un acces secours depuis cette
  /// fiche. La page s'en sert pour montrer le bouton ou le taire :
  /// afficher un geste qui sera refuse ne sert personne, et en
  /// situation d'urgence c'est pire qu'inutile.
  acces_secours_disponible: boolean;

  /// Vrai si cette fiche EST un acces secours. La page affiche alors
  /// son bandeau d'explication.
  est_acces_secours: boolean;

  /// Quand cet acces prend fin. Nul pour un partage permanent.
  expire_le: string | null;
}

export type ResultatConsultation =
  | { statut: 'ok'; fiche: FichePartagee; secret?: string }
  | { statut: 'tokenAbsent' }
  | { statut: 'tokenInconnu' }
  | { statut: 'lienExpire' }
  | { statut: 'lienRevoque' }
  | { statut: 'lienVerrouille' }
  | { statut: 'codeExpire' }
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
  verrou: OptionsVerrou = {},
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

  // La revocation passe avant tout : un lien revoque ne s'ouvre pas,
  // meme si sa date d'expiration est encore loin, meme s'il est
  // permanent.
  if (partage.revoque_le) {
    return { statut: 'lienRevoque' };
  }

  if (
    !lienEncoreValide(
      partage.date_expiration,
      maintenant,
      partage.permanent,
    )
  ) {
    return { statut: 'lienExpire' };
  }

  // Le verrou, apres la validite et avant toute lecture de donnees :
  // un appareil refuse ne doit charger aucune fiche.
  const secretPresente = verrou.secretPresente ?? null;

  const { places, erreur: erreurPlaces } = await depot.placesDuPartage(
    partage.id,
  );

  if (erreurPlaces) {
    return { statut: 'erreurBase' };
  }

  // La fenetre du code a scanner, apres les places et avant le
  // verrou : elle ne vaut que tant que PERSONNE n'a scanne.
  //
  // Des qu'une place est prise, elle ne compte plus — l'acces vit
  // sur sa propre echeance, celle que le parent a choisie. Sans ce
  // « et personne n'a scanne », le destinataire perdrait son acces
  // cinq minutes apres l'avoir recu.
  if (
    places.length === 0 &&
    !fenetreEncoreOuverte(partage.utilisable_jusqu_a, maintenant)
  ) {
    return { statut: 'codeExpire' };
  }

  const decision = decisionVerrou({
    places,
    appareilsMax: partage.appareils_max,
    empreintePresentee: secretPresente
      ? await empreinteDuSecret(secretPresente)
      : null,
    maintenant,
    toleranceMinutes: verrou.toleranceMinutes,
    repriseDemandee: verrou.repriseDemandee,
  });

  if (decision.action === 'refuser') {
    await depot.journaliserTentative({
      partageId: partage.id,
      tenteeLe: maintenant.toISOString(),
      toleree: false,
    });

    return { statut: 'lienVerrouille' };
  }

  let secretADonner: string | undefined;

  if (decision.action !== 'accepter') {
    const nouveauSecret = (verrou.genererSecret ?? genererSecretParDefaut)();
    const empreinte = await empreinteDuSecret(nouveauSecret);

    const { erreur: erreurPlace } =
      decision.action === 'remplacer'
        ? await depot.remplacerPlace(decision.placeId, empreinte)
        : await depot.prendrePlace(
            partage.id,
            empreinte,
            maintenant.toISOString(),
          );

    if (erreurPlace) {
      return { statut: 'erreurBase' };
    }

    secretADonner = nouveauSecret;

    // Le remplacement est enregistre : sans cela, la fenetre de
    // tolerance serait un trou invisible pour le parent. Marque
    // tolere — information, pas refus.
    if (decision.action === 'remplacer') {
      await depot.journaliserTentative({
        partageId: partage.id,
        tenteeLe: maintenant.toISOString(),
        toleree: true,
        reprise: decision.reprise === true,
      });

      // Apres la reprise, jamais avant : un parent prevenu d'une
      // reprise qui a echoue chercherait dans sa liste quelque
      // chose d'introuvable.
      if (decision.reprise) {
        await depot.notifierRepriseAcces(partage.id, partage.enfant_id);
      }
    }
  }

  const { enfant, erreur: erreurEnfant } = await depot.enfant(
    partage.enfant_id,
  );

  if (erreurEnfant || !enfant) {
    return { statut: 'enfantIntrouvable' };
  }

  let profilSante: unknown | null = null;

  if (partage.type_fiche !== TYPE_RECOMMANDATIONS) {
    profilSante = profilSantePourFiche(
      await depot.profilSante(partage.enfant_id),
      partage.type_fiche,
    );
  }

  const horodatage = maintenant.toISOString();

  // Deux ecritures, deux usages. `marquerConsulte` ne garde que la
  // derniere ouverture, et sert a afficher "consulte le ..." a cote du
  // lien. La journalisation, elle, garde chaque ouverture : c'est ce
  // que le parent lit dans la tracabilite de son enfant.
  //
  // Ni l'une ni l'autre ne doit empecher de rendre la fiche a
  // l'accompagnant : une trace perdue est regrettable, une fiche non
  // rendue peut mettre un enfant en danger.
  await depot.marquerConsulte(partage.id, horodatage);

  try {
    await depot.journaliserOuverture({
      enfantId: partage.enfant_id,
      partageId: partage.id,
      typeFiche: partage.type_fiche,
      ouvertLe: horodatage,
    });
  } catch (_) {
    // Volontairement avale.
  }

  // Lue ici et non plus haut : inutile d'interroger la base pour
  // quelqu'un que le verrou va refuser.
  const { autorise: accesSecoursAutorise } =
    await depot.accesSecoursAutorise(partage.enfant_id);

  return {
    statut: 'ok',
    fiche: {
      type_fiche: partage.type_fiche,
      destinataire: partage.destinataire ?? DESTINATAIRE_PAR_DEFAUT,
      enfant: enfantPourFiche(enfant),
      profil_sante: profilSante,
      profil_activites: profilActivitesPourFiche(),
      contenu_fige: partage.contenu_fige ?? null,
      // Un acces secours n'en ouvre pas un autre : le bouton ne doit
      // pas apparaitre sur une fiche qui en est deja un.
      acces_secours_disponible:
        accesSecoursAutorise && !partage.declenche_en_secours,
      est_acces_secours: partage.declenche_en_secours,
      expire_le: partage.date_expiration,
    },
    secret: secretADonner,
  };
}

/// Les entrees du verrou, groupees pour ne pas allonger la signature
/// de `consulterPartage` a chaque ajout.
export interface OptionsVerrou {
  /// Ce que l'appareil a presente, lu dans sa memoire locale.
  secretPresente?: string | null;

  /// Injectee pour les tests. En production, un alea du navigateur.
  genererSecret?: () => string;

  toleranceMinutes?: number;

  /// La personne a appuye sur « c'est moi, reprendre l'acces ».
  ///
  /// Jamais deduit : c'est un geste explicite, demande par la page
  /// apres un refus. Sans cela, un simple rechargement suffirait a
  /// prendre la place de quelqu'un d'autre sans que personne le veuille.
  repriseDemandee?: boolean;
}

/// Un alea de 256 bits, en hexadecimal.
///
/// `crypto.randomUUID` ne suffirait pas : 122 bits d'aleatoire, et un
/// format devinable. Ici le secret n'a aucune structure.
function genererSecretParDefaut(): string {
  const octets = new Uint8Array(32);

  crypto.getRandomValues(octets);

  return Array.from(octets)
    .map((octet) => octet.toString(16).padStart(2, '0'))
    .join('');
}

/// Une date d'expiration illisible vaut expirée : un lien dont on ne
/// sait pas dire s'il est encore valable ne doit pas s'ouvrir.
///
/// La fenêtre d'un code à scanner est-elle encore ouverte ?
///
/// **Nulle vaut ouverte.** Un lien ordinaire n'a pas de fenêtre, et
/// les lignes créées avant le 28/08/2026 non plus : les traiter comme
/// fermées couperait tous les partages existants.
export function fenetreEncoreOuverte(
  utilisableJusquA: string | null,
  maintenant: Date,
): boolean {
  if (!utilisableJusquA) {
    return true;
  }

  const fin = new Date(utilisableJusquA);

  if (isNaN(fin.getTime())) {
    return true;
  }

  return fin.getTime() > maintenant.getTime();
}

/// Un lien **permanent** n'a pas de date et ne se compare a rien : il
/// est valide tant qu'il n'est pas revoque, ce qui est verifie avant.
/// Sans ce cas, une date nulle serait lue comme illisible et tous les
/// liens permanents seraient refuses.
export function lienEncoreValide(
  dateExpiration: string | null,
  maintenant: Date,
  permanent = false,
): boolean {
  if (permanent) {
    return true;
  }

  if (dateExpiration === null) {
    // Pas permanent et sans date : la contrainte en base l'interdit.
    // Si cela arrive quand meme, on refuse.
    return false;
  }

  const expiration = new Date(dateExpiration);

  if (Number.isNaN(expiration.getTime())) {
    return false;
  }

  return expiration.getTime() >= maintenant.getTime();
}
