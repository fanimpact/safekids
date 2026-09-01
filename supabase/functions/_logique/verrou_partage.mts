// Le verrouillage d'un lien de partage.
//
// POURQUOI IL EXISTE
//
// Un lien de partage est un jeton porteur : qui l'a, l'ouvre. Le
// plafond de 7 jours essayait de compenser cela en limitant la durée,
// et c'était la mauvaise réponse — le rattachement à un établissement
// propose déjà un calendrier libre, parce que le professionnel y est
// identifié. La règle retenue le 27/08/2026 : **accès anonyme = risque
// à compenser, pas durée à plafonner.** Le verrou est cette
// compensation, et c'est lui qui a permis de libérer les durées.
//
// COMMENT L'APPAREIL EST IDENTIFIÉ — ET COMMENT IL NE L'EST PAS
//
// **Aucune empreinte de navigateur.** Ni adresse IP, ni User-Agent, ni
// langue, ni résolution. La fonction serveur ne les lit même pas.
// Collecter une empreinte sur un accompagnant anonyme pour protéger
// les données d'un enfant serait un mauvais échange — et fragile en
// plus : un changement de réseau change l'adresse IP.
//
// À la place : **un secret opaque que nous fabriquons nous-mêmes.** À
// la première ouverture, le serveur tire un aléa, en stocke le
// hachage, et renvoie le secret en clair à la page, qui le garde dans
// `localStorage`. Chaque ouverture suivante le renvoie. Nous ne lisons
// rien sur l'appareil : nous y déposons une valeur sans signification,
// que nous avons créée.
//
// TROIS PLACES, ET ELLES NE SE COMPTENT QU'AU RETOUR (01/09/2026)
//
// Le stockage local est cloisonné **par navigateur**, et ce
// cloisonnement n'est pas le nôtre : c'est celui du système. Un
// lecteur de QR ouvre souvent la page dans sa propre fenêtre intégrée,
// qu'on referme et qu'on ne rouvre jamais. Un seul téléphone
// fournissait donc deux places, et une maîtresse avec téléphone,
// tablette et ordinateur en atteignait six sans rien faire d'anormal.
//
// On ne peut pas **deviner** si un navigateur va rester : aucune
// détection n'est fiable, et Apple rend volontairement ses fenêtres
// intégrées indiscernables de Safari. **On attend donc de voir s'il
// revient.**
//
//   - première visite : la place est créée, elle ne compte pas ;
//   - deuxième visite du même navigateur : elle est confirmée.
//
// La fenêtre de tolérance de quinze minutes a disparu le même jour :
// elle n'existait que pour absorber ce cas, le comptage au retour le
// règle mieux et sans délai. La garder aurait été pire que l'enlever —
// elle laissait un navigateur inconnu **remplacer** la place la plus
// récente, donc voler celle de quelqu'un.
//
// CE QUE CETTE MÉTHODE NE SAIT TOUJOURS PAS FAIRE
//
//   - **navigation privée** : le secret meurt avec la fenêtre, et la
//     place ne se confirme jamais ;
//   - **effacement des données de site** : même effet ;
//   - **un lien transféré à vingt personnes qui lisent chacune une
//     fois** : aucune place confirmée, aucun signal. Angle mort assumé
//     — c'est le prix du comptage au retour ;
//   - **changement de réseau, 4G ↔ wifi** : aucun effet, et c'est
//     l'avantage décisif sur l'empreinte.

/// Une place occupée sur un partage : un appareil.
///
/// [pris_le] est la date de **première** occupation, et n'est jamais
/// réécrite.
///
/// [confirme] dit si le navigateur est revenu. Une place non confirmée
/// existe — on garde son secret pour la reconnaître — mais elle ne
/// compte pas dans le plafond.
export interface PlacePartage {
  id: string;
  empreinte: string;
  pris_le: string;
  confirme: boolean;
}

export type ActionVerrou =
  /// Le secret présenté correspond à une place déjà confirmée.
  | { action: 'accepter' }
  /// Le navigateur revient : sa place se confirme et compte désormais.
  ///
  /// **Même si le plafond est atteint entre-temps.** Il avait commencé
  /// avant qu'il le soit, et bloquer quelqu'un qui a déjà lu la fiche
  /// une fois est incompréhensible de son point de vue (décision de
  /// Fanny, 01/09/2026). Le dépassement est d'au plus un ou deux, et
  /// le parent le voit dans sa liste.
  | { action: 'confirmer'; placeId: string }
  /// Un navigateur inconnu, et il reste de la place : il en prend une,
  /// non confirmée. Elle ne comptera qu'à son retour.
  | { action: 'prendre' }
  /// Un navigateur inconnu, et les places confirmées sont toutes
  /// prises. La personne est arrêtée et le parent décide.
  ///
  /// **Dès la première visite**, et non à la seconde : sinon un
  /// inconnu lirait la fiche une fois avant d'être arrêté, ce qui
  /// viderait la règle de son sens.
  | { action: 'demander' };

/// Décide, sans rien lire ni écrire.
///
/// **L'ordre des règles est décidé, pas accidentel.** Reconnaître
/// d'abord, puis chercher de la place, puis demander. Dans l'autre
/// ordre, un navigateur déjà connu serait envoyé demander une
/// autorisation qu'il a déjà.
export function decisionVerrou(entree: {
  places: PlacePartage[];
  appareilsMax: number;
  empreintePresentee: string | null;
}): ActionVerrou {
  const { places, appareilsMax, empreintePresentee } = entree;

  // 1. Ce navigateur, on le connaît.
  if (empreintePresentee) {
    const connue = places.find(
      (place) => place.empreinte === empreintePresentee,
    );

    if (connue) {
      return connue.confirme
        ? { action: 'accepter' }
        : { action: 'confirmer', placeId: connue.id };
    }
  }

  // 2. Un inconnu, et il reste de la place. Seules les places
  //    confirmées comptent : la fenêtre d'un lecteur de QR qui ne
  //    reviendra jamais n'en occupe aucune.
  const confirmees = places.filter((place) => place.confirme).length;

  if (confirmees < appareilsMax) {
    return { action: 'prendre' };
  }

  // 3. Un inconnu de trop.
  return { action: 'demander' };
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
