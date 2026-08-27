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

/// Quinze minutes après la première ouverture, un second appareil
/// prend le verrou au lieu d'être refusé.
///
/// Le cas « webview puis navigateur » se produit toujours dans la
/// minute ; quelqu'un qui reçoit le lien le lendemain, jamais. La
/// fenêtre absorbe le premier sans rien ouvrir au second.
export const TOLERANCE_MINUTES = 15;

export type ActionVerrou =
  /// Aucun verrou encore posé : première ouverture.
  | 'poser'
  /// Le secret présenté correspond : c'est le même appareil.
  | 'accepter'
  /// Un autre appareil, mais dans la fenêtre de tolérance : il prend
  /// le verrou. Le parent en est informé quand même.
  | 'reprendre'
  /// Un autre appareil, hors fenêtre : refusé.
  | 'refuser';

/// Décide, sans rien lire ni écrire.
///
/// Prend des empreintes déjà calculées et non les secrets : le hachage
/// est asynchrone, cette décision ne l'est pas, et la garder pure la
/// rend lisible d'un coup d'œil.
export function decisionVerrou(entree: {
  empreinteStockee: string | null;
  verrouPoseLe: string | null;
  empreintePresentee: string | null;
  maintenant: Date;
  toleranceMinutes?: number;
}): ActionVerrou {
  const {
    empreinteStockee,
    verrouPoseLe,
    empreintePresentee,
    maintenant,
  } = entree;

  const tolerance = entree.toleranceMinutes ?? TOLERANCE_MINUTES;

  if (!empreinteStockee) {
    return 'poser';
  }

  if (empreintePresentee && empreintePresentee === empreinteStockee) {
    return 'accepter';
  }

  // Un verrou posé sans date de pose ne peut pas être daté : on ne
  // tolère pas ce qu'on ne sait pas situer dans le temps.
  if (!verrouPoseLe) {
    return 'refuser';
  }

  const pose = new Date(verrouPoseLe);

  if (Number.isNaN(pose.getTime())) {
    return 'refuser';
  }

  const minutesEcoulees =
    (maintenant.getTime() - pose.getTime()) / 60000;

  // Négatif : la pose est dans le futur, horloges désaccordées. On ne
  // tolère pas — un écart d'horloge ne doit pas ouvrir une fenêtre.
  if (minutesEcoulees < 0) {
    return 'refuser';
  }

  return minutesEcoulees <= tolerance ? 'reprendre' : 'refuser';
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
