import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/auth/app_auth.dart';
import 'package:kidsrelay/auth/auth_provider.dart';
import 'package:kidsrelay/auth/set_new_password_page.dart';
import 'package:kidsrelay/concept_page.dart';
import 'package:kidsrelay/main.dart';
import 'package:kidsrelay/welcome_page.dart';

import 'support/fake_auth_provider.dart';

/// Câblage d'authentification de l'app, jusqu'ici vérifié uniquement à
/// la main (voir `a_verifier_sur_mobile.md`, chantier du 23/08/2026).
///
/// Deux comportements y sont couverts :
///
///   - l'ouverture d'une session anonyme au démarrage, et surtout le
///     fait qu'une session existante n'en déclenche pas une seconde ;
///   - la réaction de l'app à un évènement `passwordRecovery`, qui
///     ouvre l'écran de nouveau mot de passe. Son échec serait
///     silencieux : rien ne s'afficherait, et rien ne le signalerait.
void main() {
  group('Ouverture de session au démarrage', () {
    test(
      'Sans session, une session anonyme est ouverte',
      () async {
        final auth = FakeAuthProvider.sansSession();

        expect(auth.hasSession, isFalse);

        await ensureSignedIn(authProvider: auth);

        expect(auth.operations, equals(['signInAnonymously']));
        expect(auth.hasSession, isTrue);
        expect(
          auth.isAnonymous,
          isTrue,
          reason:
              'C’est cette session qui porte les enfants enregistrés '
              'avant toute création de compte.',
        );
      },
    );

    test(
      'Avec une session anonyme déjà ouverte, l’identité ne change pas',
      () async {
        final auth = FakeAuthProvider.sessionAnonyme();
        final identiteAvant = auth.currentUserId;

        await ensureSignedIn(authProvider: auth);

        expect(
          auth.currentUserId,
          equals(identiteAvant),
          reason:
              'Une nouvelle session anonyme changerait auth.uid() et '
              'ferait perdre les enfants déjà enregistrés.',
        );
      },
    );

    test(
      'Avec un compte réel connecté, il n’est pas remplacé par une '
      'session anonyme',
      () async {
        final auth = FakeAuthProvider.compteReel();

        await ensureSignedIn(authProvider: auth);

        expect(auth.currentUserId, equals('utilisateur-reel'));
        expect(auth.isAnonymous, isFalse);
        expect(auth.currentUserEmail, equals('parent@exemple.fr'));
      },
    );
  });

  group('Réaction aux évènements de session', () {
    testWidgets(
      'passwordRecovery ouvre l’écran de nouveau mot de passe',
      (tester) async {
        final auth = FakeAuthProvider.sessionAnonyme();
        addTearDown(auth.dispose);

        await tester.pumpWidget(KidsRelayApp(authProvider: auth));
        await tester.pump();

        expect(find.byType(WelcomePage), findsOneWidget);
        expect(find.byType(SetNewPasswordPage), findsNothing);

        // WelcomePage bascule seule sur ConceptPage apres 2 s : on
        // laisse ce minuteur se declencher, sinon il resterait en
        // attente a la fin du test.
        await tester.pumpAndSettle(const Duration(seconds: 3));

        auth.emettre(AuthSessionEvent.passwordRecovery);
        await tester.pumpAndSettle();

        expect(
          find.byType(SetNewPasswordPage),
          findsOneWidget,
          reason:
              'C’est ce qui doit se produire quand l’app est ouverte '
              'par le lien "mot de passe oublié". Si rien ne s’affiche, '
              'la personne reste bloquée hors de son compte sans '
              'message d’erreur.',
        );
      },
    );

    testWidgets(
      'Les autres évènements n’ouvrent aucun écran',
      (tester) async {
        final auth = FakeAuthProvider.sessionAnonyme();
        addTearDown(auth.dispose);

        await tester.pumpWidget(KidsRelayApp(authProvider: auth));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        for (final event in [
          AuthSessionEvent.signedIn,
          AuthSessionEvent.signedOut,
        ]) {
          auth.emettre(event);
          await tester.pumpAndSettle();

          expect(
            find.byType(SetNewPasswordPage),
            findsNothing,
            reason:
                'Ouvrir l’écran de nouveau mot de passe sur '
                '${event.name} interromprait la personne sans raison.',
          );
        }

        // WelcomePage a cédé la place à ConceptPage après ses 2 s :
        // l'app est restée sur son parcours normal, aucun écran n'a
        // été poussé par-dessus.
        expect(find.byType(ConceptPage), findsOneWidget);
      },
    );

    testWidgets(
      'Deux évènements passwordRecovery n’empilent pas deux écrans',
      (tester) async {
        final auth = FakeAuthProvider.sessionAnonyme();
        addTearDown(auth.dispose);

        await tester.pumpWidget(KidsRelayApp(authProvider: auth));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        auth.emettre(AuthSessionEvent.passwordRecovery);
        await tester.pumpAndSettle();

        auth.emettre(AuthSessionEvent.passwordRecovery);
        await tester.pumpAndSettle();

        expect(
          find.byType(SetNewPasswordPage),
          findsOneWidget,
          reason:
              'Deux écrans superposés obligeraient à valider deux fois '
              'pour revenir en arrière.',
        );
      },
    );

    testWidgets(
      'L’abonnement est fermé quand l’app est démontée',
      (tester) async {
        final auth = FakeAuthProvider.sessionAnonyme();
        addTearDown(auth.dispose);

        await tester.pumpWidget(KidsRelayApp(authProvider: auth));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Émettre après démontage ne doit rien déclencher ni lever.
        auth.emettre(AuthSessionEvent.passwordRecovery);
        await tester.pumpAndSettle();

        expect(find.byType(SetNewPasswordPage), findsNothing);
      },
    );
  });
}
