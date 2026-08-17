import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/activity_profile_pages/aquatic_activity_page.dart';
import 'package:safekids/activity_profile_pages/overnight_stay_page.dart';
import 'package:safekids/activity_profile_pages/safety_page.dart';
import 'package:safekids/activity_profile_pages/transport_page.dart';
import 'package:safekids/activity_profile_pages/walking_effort_page.dart';
import 'package:safekids/controllers/activity_profile_controller.dart';
import 'package:safekids/widgets/sk_yes_no_field.dart';

/// Vérifie que les questions filtres "Votre enfant a-t-il besoin
/// d'adaptations particulières pour X ?" ont bien disparu des sections
/// eau/baignade, transport, nuitée et sécurité du profil activités
/// (communication et transitions ont volontairement retrouvé une
/// question filtre depuis, voir
/// communication_transitions_filter_question_test.dart), et que les
/// questions détaillées de chaque section sont affichées directement,
/// sans qu'aucune réponse préalable soit nécessaire — même correction
/// que celle faite pour les facteurs déclenchants.
///
/// Corrige aussi une régression signalée par l'utilisatrice : sans
/// question filtre, chaque sous-question affichait "Non" présélectionné
/// par défaut (le champ du modèle valait `false` au lieu de "pas encore
/// répondu"), recréant le même risque qu'un parent valide "Non" sans y
/// penser — juste réparti question par question. Ces tests vérifient
/// qu'aucune réponse n'est présélectionnée, et qu'on ne peut pas
/// continuer sans avoir répondu à chaque question.
void main() {
  bool? yesNoValue(WidgetTester tester, String labelContains) {
    final field = tester.widget<SkYesNoField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SkYesNoField &&
            widget.label.contains(labelContains),
      ),
    );

    return field.value;
  }

  testWidgets(
    'Transport : aucune réponse présélectionnée, on ne peut pas '
    'continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransportPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières lors des transports',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant a-t-il le mal des transports ?',
        ),
        findsOneWidget,
      );
      expect(
        yesNoValue(tester, 'le mal des transports'),
        isNull,
        reason:
            'Aucune réponse ne doit être présélectionnée par défaut.',
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir continuer sans avoir répondu à '
            'chaque question.',
      );
      expect(find.byType(TransportPage), findsOneWidget);
    },
  );

  testWidgets(
    'Marche prolongée / effort physique : aucune réponse '
    'présélectionnée, on ne peut pas continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WalkingEffortPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        yesNoValue(tester, 'La marche prolongée'),
        isNull,
        reason:
            'Aucune réponse ne doit être présélectionnée par défaut.',
      );
      expect(
        yesNoValue(tester, 'Un effort physique intense'),
        isNull,
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir continuer sans avoir répondu à '
            'chaque question.',
      );
      expect(
        find.byType(WalkingEffortPage),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Nuitée : aucune réponse présélectionnée, on ne peut pas '
    'continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OvernightStayPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières lors d’un séjour avec nuitée',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant utilise-t-il un appareillage pendant la nuit ?',
        ),
        findsOneWidget,
      );
      expect(
        yesNoValue(tester, 'un appareillage pendant la nuit'),
        isNull,
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
      );
      expect(find.byType(OvernightStayPage), findsOneWidget);
    },
  );

  testWidgets(
    'Sécurité : aucune réponse présélectionnée sur les deux '
    'questions, on ne peut pas continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafetyPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières concernant sa sécurité',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant est-il susceptible de quitter brusquement le groupe ?',
        ),
        findsOneWidget,
        reason:
            'Doit être une vraie question Oui/Non, pas une case à '
            'cocher facultative.',
      );
      expect(
        find.text(
          'Votre enfant nécessite-t-il un équipement de sécurité particulier ?',
        ),
        findsOneWidget,
      );
      expect(
        yesNoValue(tester, 'quitter brusquement le groupe'),
        isNull,
      );
      expect(
        yesNoValue(tester, 'un équipement de sécurité'),
        isNull,
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
      );
      expect(find.byType(SafetyPage), findsOneWidget);
    },
  );

  testWidgets(
    'Eau / baignade : aucune réponse présélectionnée, on ne peut pas '
    'continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AquaticActivityPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières en présence d’un point d’eau',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant a-t-il besoin d’un adulte dédié à proximité d’un point d’eau pour assurer sa sécurité ?',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Votre enfant nécessite-t-il un équipement particulier ?',
        ),
        findsOneWidget,
      );
      expect(
        yesNoValue(tester, 'un adulte dédié à proximité'),
        isNull,
      );
      expect(
        yesNoValue(
          tester,
          'Votre enfant nécessite-t-il un équipement particulier',
        ),
        isNull,
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
      );
      expect(find.byType(AquaticActivityPage), findsOneWidget);
    },
  );
}
