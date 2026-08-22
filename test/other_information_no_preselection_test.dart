import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_profile_pages/other_information_page.dart';
import 'package:kidsrelay/controllers/activity_profile_controller.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Corrigé (19/08/2026) : dernière page du questionnaire activités,
/// seule à ne pas avoir reçu le nettoyage "aucune réponse
/// présélectionnée" appliqué partout ailleurs le 16/08 (voir
/// clothing_toilets_no_preselection_test.dart) — "Non" s'affichait
/// coché dès l'ouverture, et "Terminer" ne bloquait jamais si la
/// question n'était pas répondue.
void main() {
  bool? yesNoValue(WidgetTester tester) {
    final field = tester.widget<SkYesNoField>(
      find.byType(SkYesNoField),
    );

    return field.value;
  }

  testWidgets(
    'Autres informations : aucune réponse présélectionnée, on ne '
    'peut pas terminer sans répondre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtherInformationPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Y a-t-il une autre information importante concernant l'accompagnement de votre enfant que nous n'avons pas abordée ?",
        ),
        findsOneWidget,
      );
      expect(yesNoValue(tester), isNull);

      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('avant de continuer'),
        findsOneWidget,
        reason:
            'On ne doit pas pouvoir terminer sans avoir répondu.',
      );
      expect(
        find.byType(OtherInformationPage),
        findsOneWidget,
      );
    },
  );
}
