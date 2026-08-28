/// Où l'application s'ouvre au démarrage.
///
/// **Le défaut que cela corrige.** Jusqu'au 28/08/2026, l'application
/// affichait l'écran de connexion à chaque démarrage, même quand la
/// session était parfaitement valide — rien dans l'interface ne
/// consultait `hasSession`. Or le moment où un parent ouvre cette
/// application en urgence est exactement celui où il ne retrouve pas
/// son mot de passe.
///
/// Fonction pure : la règle se teste sans session, sans base et sans
/// écran.
library;

enum DestinationDemarrage {
  /// Pas de session exploitable : le parcours d'entrée habituel.
  concept,

  /// Un parent, avec au moins un enfant enregistré.
  accueilParent,

  /// Un compte professionnel, membre d'au moins un établissement.
  accueilProfessionnel,

  /// Une session valide, mais rien qui dise de quel espace il s'agit.
  /// La personne choisit.
  choixEspace,
}

/// Décide, sans rien lire ni écrire.
///
/// [anonyme] compte autant que l'absence de session : `signInAnonymously`
/// existe dans l'application, et une session anonyme ne donne accès à
/// aucun profil. L'ouvrir sur un accueil montrerait une page vide.
///
/// Un compte qui possède **les deux** ouvre sur l'espace parent : c'est
/// celui qui porte les données de ses propres enfants, et donc celui
/// qu'on ouvre en urgence. Le passage à l'espace professionnel reste à
/// un geste.
DestinationDemarrage destinationDemarrage({
  required bool session,
  required bool anonyme,
  required int enfants,
  required int etablissements,
}) {
  if (!session || anonyme) {
    return DestinationDemarrage.concept;
  }

  if (enfants > 0) {
    return DestinationDemarrage.accueilParent;
  }

  if (etablissements > 0) {
    return DestinationDemarrage.accueilProfessionnel;
  }

  return DestinationDemarrage.choixEspace;
}
