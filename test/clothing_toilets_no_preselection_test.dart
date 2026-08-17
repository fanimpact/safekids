import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/activity_profile_pages/clothing_page.dart';
import 'package:safekids/activity_profile_pages/toilets_page.dart';
import 'package:safekids/controllers/activity_profile_controller.dart';
import 'package:safekids/widgets/sk_yes_no_field.dart';

/// Aligne les sections "Habillage" et "Toilettes" du profil activités
/// sur le même principe que les autres sections (voir
/// activity_profile_no_filter_question_test.dart) : aucune réponse
/// présélectionnée par défaut, et impossible de continuer sans avoir
/// répondu.
void main() {
  bool? yesNoValue(WidgetTester tester) {
    final field = tester.widget<SkYesNoField>(
      find.byType(SkYesNoField),
    );

    return field.value;
  }

  testWidgets(
    'Habillage : aucune réponse présélectionnée, on ne peut pas '
    'continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ClothingPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Votre enfant nécessite-t-il qu’un adulte dédié l’aide lors d’un changement de tenue, par rapport à un enfant de son âge ?',
        ),
        findsOneWidget,
      );
      expect(yesNoValue(tester), isNull);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir continuer sans avoir répondu.',
      );
      expect(find.byType(ClothingPage), findsOneWidget);
    },
  );

  testWidgets(
    'Toilettes : aucune réponse présélectionnée, on ne peut pas '
    'continuer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ToiletsPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Votre enfant nécessite-t-il qu’un adulte dédié l’accompagne aux toilettes, par rapport à un enfant de son âge ?',
        ),
        findsOneWidget,
      );
      expect(yesNoValue(tester), isNull);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir continuer sans avoir répondu.',
      );
      expect(find.byType(ToiletsPage), findsOneWidget);
    },
  );
}
