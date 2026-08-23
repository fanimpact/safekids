import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/auth/auth_provider.dart';
import 'package:kidsrelay/utils/auth_error_message.dart';

/// Corrigé (audit passe 3) : l'app affichait l'exception Supabase
/// brute (ex. `AuthApiException(message: Email address "" is
/// invalid, statusCode: 400, code: email_address_invalid)`) à
/// l'utilisateur. Ce test vérifie qu'un message clair, en français,
/// est toujours affiché à la place — jamais le texte de l'exception.
///
/// Réécrit le 23/08/2026 : la fonction ne connaît plus le SDK, elle
/// travaille sur `AuthFailure`. La traduction des codes Supabase vers
/// `AuthErrorCode` est faite par `SupabaseAuthProvider`, en amont.
void main() {
  test(
    'une adresse email invalide donne un message clair, pas '
    'l’exception brute',
    () {
      final message = friendlyAuthErrorMessage(
        const AuthFailure(
          AuthErrorCode.emailAddressInvalid,
          rawMessage: 'Email address "" is invalid',
        ),
      );

      expect(message, isNot(contains('AuthFailure')));
      expect(message, isNot(contains('Email address')));
      expect(message, contains('valide'));
    },
  );

  test('la limite d’envoi d’emails donne un message clair', () {
    final message = friendlyAuthErrorMessage(
      const AuthFailure(
        AuthErrorCode.tooManyAttempts,
        rawMessage: 'Email rate limit exceeded',
      ),
    );

    expect(message, isNot(contains('AuthFailure')));
    expect(message, contains('Réessayez'));
  });

  test(
    'un code d’erreur inconnu (nouveau côté fournisseur) reste un '
    'message générique, jamais l’exception brute',
    () {
      final message = friendlyAuthErrorMessage(
        const AuthFailure(
          AuthErrorCode.unknown,
          rawMessage: 'Something completely new',
        ),
      );

      expect(message, isNot(contains('AuthFailure')));
      expect(message, isNot(contains('Something completely new')));
    },
  );

  test(
    'une erreur qui n’est pas un AuthFailure (ex. pas de réseau) '
    'reste un message générique',
    () {
      final message = friendlyAuthErrorMessage(
        Exception('SocketException: Failed host lookup'),
      );

      expect(message, isNot(contains('SocketException')));
      expect(message, contains('connexion'));
    },
  );

  test(
    'un échec réseau traduit par le fournisseur donne le même '
    'message qu’une exception inattendue',
    () {
      expect(
        friendlyAuthErrorMessage(
          const AuthFailure(AuthErrorCode.network),
        ),
        equals(
          friendlyAuthErrorMessage(Exception('peu importe')),
        ),
      );
    },
  );

  test(
    'chaque cause a son message : aucune ne retombe par défaut sur '
    'une autre',
    () {
      final messages = <String>{};

      for (final code in AuthErrorCode.values) {
        messages.add(
          friendlyAuthErrorMessage(AuthFailure(code)),
        );
      }

      // network et unknown ont volontairement des messages distincts,
      // mais network partage le sien avec l'erreur inattendue.
      expect(
        messages.length,
        equals(AuthErrorCode.values.length),
        reason:
            'Deux causes différentes ne doivent pas donner le même '
            'message : le parent ne saurait pas quoi corriger.',
      );
    },
  );
}
