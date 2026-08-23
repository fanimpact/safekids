import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/auth/auth_provider.dart';
import 'package:kidsrelay/auth/supabase_auth_provider.dart';
import 'package:kidsrelay/utils/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les deux traductions écrites à la main dans `SupabaseAuthProvider`
/// le 23/08/2026, quand la dépendance à Supabase a été isolée derrière
/// `AuthProvider`.
///
/// Elles n'étaient couvertes par aucun test : la vérification reposait
/// entièrement sur un contrôle manuel (voir `a_verifier_sur_mobile.md`).
/// Or ce sont exactement les endroits où une erreur passe inaperçue :
///
///   - le filtre d'évènements décide si l'écran de nouveau mot de passe
///     s'ouvre. Trop strict, RIEN ne se passe et rien ne le signale ;
///   - la table des codes d'erreur décide du message français affiché.
///     Fausse, la personne lit un message qui ne correspond pas à son
///     problème.
void main() {
  group('Filtre des évènements de session', () {
    test(
      'Les trois évènements que l’app traite sont laissés passer',
      () {
        const attendus = {
          AuthChangeEvent.passwordRecovery:
              AuthSessionEvent.passwordRecovery,
          AuthChangeEvent.signedIn: AuthSessionEvent.signedIn,
          AuthChangeEvent.signedOut: AuthSessionEvent.signedOut,
        };

        for (final entry in attendus.entries) {
          expect(
            SupabaseAuthProvider.toSessionEventForTesting(
              AuthState(entry.key, null),
            ),
            equals(entry.value),
            reason: '${entry.key.name} doit être transmis.',
          );
        }
      },
    );

    test(
      'passwordRecovery passe — c’est lui qui ouvre l’écran de '
      'nouveau mot de passe',
      () {
        expect(
          SupabaseAuthProvider.toSessionEventForTesting(
            const AuthState(AuthChangeEvent.passwordRecovery, null),
          ),
          equals(AuthSessionEvent.passwordRecovery),
          reason:
              'Si ce filtre le rejetait, le lien "mot de passe oublié" '
              'n’afficherait rien du tout, sans erreur visible.',
        );
      },
    );

    test(
      'Tous les autres évènements du SDK sont filtrés',
      () {
        const transmis = {
          AuthChangeEvent.passwordRecovery,
          AuthChangeEvent.signedIn,
          AuthChangeEvent.signedOut,
        };

        final filtres = AuthChangeEvent.values
            .where((event) => !transmis.contains(event))
            .toList();

        expect(
          filtres,
          isNotEmpty,
          reason: 'Le SDK émet plus que les trois évènements traités.',
        );

        for (final event in filtres) {
          expect(
            SupabaseAuthProvider.toSessionEventForTesting(
              AuthState(event, null),
            ),
            isNull,
            reason:
                '${event.name} n’est pas traité par l’app : le laisser '
                'passer exposerait le vocabulaire du SDK sans rien '
                'apporter.',
          );
        }
      },
    );

    test(
      'Un nouvel évènement ajouté par une future version du SDK est '
      'ignoré, pas transmis par erreur',
      () {
        // Vérifié sur toutes les valeurs connues à ce jour : aucune
        // hors des trois traitées ne remonte. Le `default` du filtre
        // couvre donc aussi celles qui n'existent pas encore.
        final transmises = AuthChangeEvent.values
            .where(
              (event) =>
                  SupabaseAuthProvider.toSessionEventForTesting(
                    AuthState(event, null),
                  ) !=
                  null,
            )
            .toList();

        expect(transmises.length, equals(3));
      },
    );
  });

  group('Traduction des codes d’erreur', () {
    test('Chaque code Supabase connu a sa cause applicative', () {
      const attendus = {
        'email_address_invalid': AuthErrorCode.emailAddressInvalid,
        'email_exists': AuthErrorCode.emailAlreadyExists,
        'user_already_exists': AuthErrorCode.emailAlreadyExists,
        'over_email_send_rate_limit': AuthErrorCode.tooManyAttempts,
        'weak_password': AuthErrorCode.weakPassword,
        'same_password': AuthErrorCode.samePassword,
        'invalid_credentials': AuthErrorCode.invalidCredentials,
        'signup_disabled': AuthErrorCode.signupDisabled,
      };

      for (final entry in attendus.entries) {
        expect(
          SupabaseAuthProvider.toErrorCodeForTesting(entry.key),
          equals(entry.value),
          reason: 'Code Supabase "${entry.key}".',
        );
      }
    });

    test(
      'Deux codes Supabase distincts peuvent mener à la même cause',
      () {
        // email_exists et user_already_exists disent la même chose au
        // parent : un compte existe déjà.
        expect(
          SupabaseAuthProvider.toErrorCodeForTesting('email_exists'),
          equals(
            SupabaseAuthProvider.toErrorCodeForTesting(
              'user_already_exists',
            ),
          ),
        );
      },
    );

    test(
      'Un code inconnu ou absent devient unknown, jamais une cause '
      'prise au hasard',
      () {
        for (final code in [
          null,
          '',
          'un_code_jamais_vu',
          'EMAIL_EXISTS',
        ]) {
          expect(
            SupabaseAuthProvider.toErrorCodeForTesting(code),
            equals(AuthErrorCode.unknown),
            reason:
                'Code "$code" : mieux vaut un message générique qu’un '
                'message précis et faux.',
          );
        }
      },
    );
  });

  group('De bout en bout : code Supabase vers message français', () {
    test(
      'Un mot de passe erroné donne bien le message attendu',
      () {
        final message = friendlyAuthErrorMessage(
          AuthFailure(
            SupabaseAuthProvider.toErrorCodeForTesting(
              'invalid_credentials',
            ),
          ),
        );

        expect(
          message,
          equals('Adresse email ou mot de passe incorrect.'),
          reason:
              'C’est la chaîne complète qui est vérifiée ici : code '
              'Supabase → AuthErrorCode → message. Chaque maillon '
              'était testé séparément, jamais ensemble.',
        );
      },
    );

    test(
      'Une adresse déjà utilisée donne bien le message attendu',
      () {
        for (final code in ['email_exists', 'user_already_exists']) {
          expect(
            friendlyAuthErrorMessage(
              AuthFailure(
                SupabaseAuthProvider.toErrorCodeForTesting(code),
              ),
            ),
            equals('Un compte existe déjà avec cette adresse email.'),
            reason: 'Code "$code".',
          );
        }
      },
    );

    test(
      'Aucun code connu ne retombe sur le message générique',
      () {
        const codesConnus = [
          'email_address_invalid',
          'email_exists',
          'user_already_exists',
          'over_email_send_rate_limit',
          'weak_password',
          'same_password',
          'invalid_credentials',
          'signup_disabled',
        ];

        const messageGenerique =
            'Une erreur est survenue. Réessayez dans quelques '
            'instants.';

        for (final code in codesConnus) {
          expect(
            friendlyAuthErrorMessage(
              AuthFailure(
                SupabaseAuthProvider.toErrorCodeForTesting(code),
              ),
            ),
            isNot(equals(messageGenerique)),
            reason:
                'Le code "$code" est connu : il doit donner un message '
                'qui dit quoi corriger, pas le message fourre-tout.',
          );
        }
      },
    );
  });
}
