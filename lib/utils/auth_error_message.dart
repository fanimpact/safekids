import '../auth/auth_provider.dart';

/// Traduit un échec d'authentification en message clair, en français,
/// pour l'utilisateur — corrections de l'audit passe 3 : l'app
/// affichait jusqu'ici l'exception brute (ex.
/// `AuthApiException(message: Email address "" is invalid,
/// statusCode: 400, code: email_address_invalid)`), quelle que soit
/// la cause du rejet.
///
/// Depuis le 23/08/2026, ce fichier ne connaît plus le SDK : il ne
/// travaille que sur [AuthFailure], que l'implémentation du
/// fournisseur produit. Tout ce qui n'est pas un [AuthFailure] — une
/// exception inattendue remontée d'ailleurs — reçoit le message
/// d'indisponibilité, comme avant.
String friendlyAuthErrorMessage(Object error) {
  if (error is! AuthFailure) {
    return 'Impossible de contacter le serveur. Vérifiez votre '
        'connexion.';
  }

  switch (error.code) {
    case AuthErrorCode.emailAddressInvalid:
      return 'Cette adresse email n’est pas valide.';
    case AuthErrorCode.emailAlreadyExists:
      return 'Un compte existe déjà avec cette adresse email.';
    case AuthErrorCode.tooManyAttempts:
      return 'Trop de tentatives en peu de temps. Réessayez dans '
          'quelques minutes.';
    case AuthErrorCode.weakPassword:
      return 'Ce mot de passe est trop simple. Choisissez-en un '
          'plus solide.';
    case AuthErrorCode.samePassword:
      return 'Le nouveau mot de passe doit être différent de '
          'l’ancien.';
    case AuthErrorCode.invalidCredentials:
      return 'Adresse email ou mot de passe incorrect.';
    case AuthErrorCode.signupDisabled:
      return 'La création de compte est momentanément '
          'indisponible.';
    case AuthErrorCode.network:
      return 'Impossible de contacter le serveur. Vérifiez votre '
          'connexion.';
    case AuthErrorCode.unknown:
      return 'Une erreur est survenue. Réessayez dans quelques '
          'instants.';
  }
}
