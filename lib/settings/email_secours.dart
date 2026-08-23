/// Validation de l'adresse email de secours.
///
/// Fonctions pures, sans dépendance : la règle se teste sans base et
/// sans écran.
///
/// À quoi sert cette adresse : uniquement à recontacter le parent s'il
/// perd l'accès à son compte — adresse principale fermée, changement
/// d'employeur, boîte pleine. Elle ne reçoit aucun envoi automatique.
/// C'est pour cela qu'elle est facultative, et qu'aucun écran n'insiste
/// pour l'obtenir.
library;

/// `null` si l'adresse est acceptable, sinon le message à afficher.
///
/// Volontairement permissive : la seule vérification qui vaille est
/// qu'un email arrive, et nous n'en envoyons pas ici. Refuser une
/// adresse valide mais inhabituelle serait plus gênant qu'accepter une
/// faute de frappe — le parent est le seul à savoir laquelle est la
/// bonne.
String? erreurEmailSecours(String saisie) {
  final valeur = saisie.trim();

  if (valeur.isEmpty) {
    // Le champ est facultatif : vide est une réponse valable, et
    // enregistrer un champ vide efface l'adresse précédente.
    return null;
  }

  if (valeur.contains(' ')) {
    return 'Une adresse email ne contient pas d’espace.';
  }

  final arobases = '@'.allMatches(valeur).length;

  if (arobases != 1) {
    return 'Cette adresse ne ressemble pas à une adresse email.';
  }

  final parties = valeur.split('@');
  final avant = parties.first;
  final apres = parties.last;

  if (avant.isEmpty || apres.isEmpty) {
    return 'Cette adresse ne ressemble pas à une adresse email.';
  }

  if (!apres.contains('.') ||
      apres.startsWith('.') ||
      apres.endsWith('.')) {
    return 'Le nom de domaine de cette adresse semble incomplet.';
  }

  return null;
}

/// Ce qui doit être enregistré pour une saisie donnée : l'adresse
/// nettoyée, ou `null` si le parent a vidé le champ.
String? valeurAEnregistrer(String saisie) {
  final valeur = saisie.trim();

  return valeur.isEmpty ? null : valeur;
}

/// Mise en garde affichée quand l'adresse de secours est la même que
/// l'adresse principale.
///
/// Ce n'est pas une erreur — le parent a le droit — mais une adresse de
/// secours identique à celle qu'il vient de perdre ne le secourra pas.
bool memeAdresseQuePrincipale(
  String saisie,
  String? emailPrincipal,
) {
  final valeur = saisie.trim().toLowerCase();

  if (valeur.isEmpty || emailPrincipal == null) {
    return false;
  }

  return valeur == emailPrincipal.trim().toLowerCase();
}
