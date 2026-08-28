// Le verrouillage d'un lien de partage à sa première ouverture.
//
// Pourquoi il existe.
//
// Un lien de partage est un jeton porteur : qui l'a, l'ouvre. Le
// plafond de 7 jours essayait de compenser cela en limitant la durée,
// et c'était la mauvaise réponse — le rattachement à un établissement
// propose déjà un calendrier libre, parce que le professionnel y est
// identifié. La règle retenue le 27/08/2026 : **accès anonyme = risque
// à compenser, pas durée à plafonner.** Le verrou est cette
// compensation, et c'est lui qui a permis de libérer les durées.
//
// Comment l'appareil est identifié — et comment il ne l'est pas.
//
// **Aucune empreinte de navigateur.** Ni adresse IP, ni User-Agent, ni
// langue, ni résolution. La fonction serveur ne les lit même pas, et
// c'est une décision déjà tenue ailleurs (voir `depot_partages.mts`,
// journalisation des ouvertures). Collecter une empreinte sur un
// accompagnant anonyme pour protéger les données d'un enfant serait un
// mauvais échange — et fragile en plus : un changement de réseau change
// l'adresse IP.
//
// À la place : **un secret opaque que nous fabriquons nous-mêmes.** À
// la première ouverture, le serveur tire un aléa, en stocke le
// hachage, et renvoie le secret en clair à la page, qui le garde dans
// `localStorage`. Chaque ouverture suivante le renvoie. Nous ne lisons
// rien sur l'appareil : nous y déposons une valeur sans signification,
// que nous avons créée.
//
// Ce que cette méthode ne sait pas faire, et qu'il faut savoir :
//
//   - **navigateur intégré d'un client mail, puis « ouvrir dans
//     Chrome »** : deux espaces de stockage distincts, et le
//     destinataire légitime se verrouille dehors tout seul. C'est le
//     cas le plus courant, et c'est ce que la fenêtre de tolérance
//     absorbe ;
//   - **navigation privée** : le secret meurt avec la fenêtre ;
//   - **effacement des données de site** : même effet ;
//   - **téléphone puis ordinateur** : refusé, ce qui est l'intention,
//     mais touche aussi un usage légitime ;
//   - **changement de réseau, 4G ↔ wifi** : aucun effet, et c'est
//     l'avantage décisif sur l'empreinte.
//
// Les deux amortisseurs, décidés avec Fanny : la fenêtre de tolérance
// ci-dessous, et le déverrouillage par le parent depuis sa liste.

/// La fenêtre de tolérance, en minutes.
///
/// Un appareil qui se présente sans secret reconnu **remplace** la
/// place occupée le plus récemment, si elle l'a été il y a moins de ce
/// délai. Le cas « webview puis navigateur » se produit toujours dans
/// la minute ; quelqu'un qui reçoit le lien le lendemain, jamais.
export const TOLERANCE_MINUTES = 15;

/// Une place occupée sur un partage : un appareil.
///
/// [pris_le] est la date de **première** occupation, et n'est jamais
/// réécrite. Un remplacement change l'empreinte, pas la date — sans
/// quoi la fenêtre glisserait et deviendrait renouvelable sans fin.
/// C'est le défaut constaté en production le 27/08/2026.
export interface PlacePartage {
  id: string;
  empreinte: string;
  pris_le: string;
}

export type ActionVerrou =
  /// Le secret présenté correspond à une place : même appareil.
  | { action: 'accepter' }
  /// Un autre appareil, dans la fenêtre : il remplace cette place-là
  /// au lieu d'en consommer une nouvelle.
  ///
  /// [reprise] distingue le remplacement **demandé** de celui qui se
  /// fait tout seul dans le quart d'heure : le premier doit prévenir
  /// le parent, le second est une commodité silencieuse.
  | { action: 'remplacer'; placeId: string; reprise?: true }
  /// Une place est libre : il la prend.
  | { action: 'prendre' }
  /// Toutes les places sont prises, hors fenêtre.
  | { action: 'refuser' };

/// Décide, sans rien lire ni écrire.
///
/// **L'ordre des trois règles est décidé, pas accidentel** (Fanny,
/// 27/08/2026) : remplacement d'abord, place libre ensuite, refus en
/// dernier.
///
/// Dans l'autre ordre, la grand-mère qui ouvre le partage depuis sa
/// messagerie puis dans son navigateur consommerait **deux** places au
/// lieu d'une, et le grand-père serait refusé le surlendemain sans que
/// personne comprenne pourquoi.
export function decisionVerrou(entree: {
  places: PlacePartage[];
  appareilsMax: number;
  empreintePresentee: string | null;
  maintenant: Date;
  toleranceMinutes?: number;

  /// La personne a appuyé sur « c'est moi ». Elle ne change rien
  /// aux trois premières règles : la reprise n'intervient qu'à la
  /// place du refus, jamais avant.
  repriseDemandee?: boolean;
}): ActionVerrou {
  const { places, appareilsMax, empreintePresentee, maintenant } = entree;

  const tolerance = entree.toleranceMinutes ?? TOLERANCE_MINUTES;

  // 1. Le même appareil repasse.
  if (empreintePresentee) {
    const connue = places.find(
      (place) => place.empreinte === empreintePresentee,
    );

    if (connue) {
      return { action: 'accepter' };
    }
  }

  // 2. La place la plus récemment occupée, si elle est encore dans la
  //    fenêtre. Avant la recherche d'une place libre, délibérément.
  const derniere = placeLaPlusRecente(places);

  if (derniere) {
    const minutes = minutesEcoulees(derniere.pris_le, maintenant);

    if (minutes !== null && minutes >= 0 && minutes <= tolerance) {
      return { action: 'remplacer', placeId: derniere.id };
    }
  }

  // 3. Une place libre.
  if (places.length < appareilsMax) {
    return { action: 'prendre' };
  }

  // 4. La reprise demandée, à la place du refus (28/08/2026).
  //
  // Le secret vit dans le `localStorage` du navigateur qui a ouvert
  // la fiche, et ce cloisonnement n'est pas le nôtre : c'est celui
  // du système. Un lecteur de QR qui ouvre la page dans son propre
  // navigateur intégré y range le secret, et la même personne se
  // présente ensuite comme une inconnue depuis Safari.
  //
  // Elle ne peut pas le deviner, et le moment où elle le découvre
  // est le pire : une maîtresse qui rouvre la fiche parce qu'il se
  // passe quelque chose avec l'enfant.
  //
  // Ce n'est pas un affaiblissement en trompe-l'oeil : la règle 2
  // permet **déjà** cette reprise dans les quinze minutes, et en
  // silence. Ce qui change ici, c'est que le parent est prévenu.
  if (entree.repriseDemandee && derniere) {
    return { action: 'remplacer', placeId: derniere.id, reprise: true };
  }

  return { action: 'refuser' };
}

/// `null` si la date est illisible — on ne tolère pas ce qu'on ne sait
/// pas situer dans le temps. Négatif si la pose est dans le futur :
/// un écart d'horloge ne doit pas ouvrir une fenêtre.
function minutesEcoulees(
  date: string,
  maintenant: Date,
): number | null {
  const pose = new Date(date);

  if (Number.isNaN(pose.getTime())) {
    return null;
  }

  return (maintenant.getTime() - pose.getTime()) / 60000;
}

function placeLaPlusRecente(
  places: PlacePartage[],
): PlacePartage | null {
  let derniere: PlacePartage | null = null;
  let meilleure = Number.NEGATIVE_INFINITY;

  for (const place of places) {
    const instant = new Date(place.pris_le).getTime();

    if (Number.isNaN(instant)) {
      continue;
    }

    if (instant > meilleure) {
      meilleure = instant;
      derniere = place;
    }
  }

  return derniere;
}

/// Le hachage d'un secret, en hexadécimal.
///
/// `crypto.subtle` est une API web standard, disponible aussi bien
/// dans Deno que dans Node : ce module reste sans import, et se teste
/// sans réseau ni base.
///
/// C'est l'empreinte qui est stockée, jamais le secret : une fuite de
/// la table ne donnerait à personne de quoi rouvrir un lien.
export async function empreinteDuSecret(
  secret: string,
): Promise<string> {
  const octets = new TextEncoder().encode(secret);
  const condense = await crypto.subtle.digest('SHA-256', octets);

  return Array.from(new Uint8Array(condense))
    .map((octet) => octet.toString(16).padStart(2, '0'))
    .join('');
}
