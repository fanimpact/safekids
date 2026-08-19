import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/utils/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Corrigé (audit passe 3) : l'app affichait l'exception Supabase
/// brute (ex. `AuthApiException(message: Email address "" is
/// invalid, statusCode: 400, code: email_address_invalid)`) à
/// l'utilisateur. Ce test vérifie qu'un message clair, en français,
/// est toujours affiché à la place — jamais le texte de l'exception.
void main() {
  test(
    'une adresse email invalide donne un message clair, pas '
    'l’exception brute',
    () {
      final message = friendlyAuthErrorMessage(
        AuthApiException(
          'Email address "" is invalid',
          statusCode: '400',
          code: 'email_address_invalid',
        ),
      );

      expect(message, isNot(contains('AuthApiException')));
      expect(message, isNot(contains('statusCode')));
      expect(message, contains('valide'));
    },
  );

  test('la limite d’envoi d’emails donne un message clair', () {
    final message = friendlyAuthErrorMessage(
      AuthApiException(
        'Email rate limit exceeded',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      ),
    );

    expect(message, isNot(contains('AuthApiException')));
    expect(message, contains('Réessayez'));
  });

  test(
    'un code d’erreur inconnu (nouveau côté Supabase) reste un '
    'message générique, jamais l’exception brute',
    () {
      final message = friendlyAuthErrorMessage(
        AuthApiException(
          'Something completely new',
          statusCode: '500',
          code: 'un_code_jamais_vu',
        ),
      );

      expect(message, isNot(contains('AuthApiException')));
      expect(message, isNot(contains('un_code_jamais_vu')));
      expect(message, isNot(contains('Something completely new')));
    },
  );

  test(
    'une erreur qui n’est pas une AuthApiException (ex. pas de '
    'réseau) reste un message générique',
    () {
      final message = friendlyAuthErrorMessage(
        Exception('SocketException: Failed host lookup'),
      );

      expect(message, isNot(contains('SocketException')));
      expect(message, contains('connexion'));
    },
  );
}
