import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit une erreur de Supabase Auth en message clair, en français,
/// pour l'utilisateur — corrections de l'audit passe 3 : l'app
/// affichait jusqu'ici l'exception brute (ex.
/// `AuthApiException(message: Email address "" is invalid,
/// statusCode: 400, code: email_address_invalid)`), quelle que soit
/// la cause du rejet côté Supabase.
String friendlyAuthErrorMessage(Object error) {
  if (error is AuthApiException) {
    switch (error.code) {
      case 'email_address_invalid':
        return 'Cette adresse email n’est pas valide.';
      case 'email_exists':
      case 'user_already_exists':
        return 'Un compte existe déjà avec cette adresse email.';
      case 'over_email_send_rate_limit':
        return 'Trop de tentatives en peu de temps. Réessayez dans '
            'quelques minutes.';
      case 'weak_password':
        return 'Ce mot de passe est trop simple. Choisissez-en un '
            'plus solide.';
      case 'same_password':
        return 'Le nouveau mot de passe doit être différent de '
            'l’ancien.';
      case 'invalid_credentials':
        return 'Adresse email ou mot de passe incorrect.';
      case 'signup_disabled':
        return 'La création de compte est momentanément '
            'indisponible.';
      default:
        return 'Une erreur est survenue. Réessayez dans quelques '
            'instants.';
    }
  }

  return 'Impossible de contacter le serveur. Vérifiez votre '
      'connexion.';
}
