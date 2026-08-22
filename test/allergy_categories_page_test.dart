import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/transmission_pages/diagnosed_pathologies_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Saisie du type d'allergie (22/08/2026). Le champ libre unique
/// "À quoi votre enfant est-il allergique ?" a disparu : chaque case
/// cochée ouvre sa propre sous-question, et c'est elle qui porte la
/// précision — pour que le parent ne saisisse pas deux fois la même
/// information.
void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    TransmissionController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosedPathologiesPage(
          transmissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> answerYesNo(
    WidgetTester tester,
    String labelContains,
    bool value,
  ) async {
    final finder = find.byWidgetPredicate(
      (widget) =>
          widget is SkYesNoField &&
          widget.label.contains(labelContains),
    );

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    tester.widget<SkYesNoField>(finder).onChanged(value);
    await tester.pumpAndSettle();
  }

  Finder categoryCheckbox(String label) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is CheckboxListTile &&
          widget.title is Text &&
          (widget.title as Text).data == label,
    );
  }

  Future<void> tickCategory(
    WidgetTester tester,
    String label, {
    bool value = true,
  }) async {
    final finder = categoryCheckbox(label);

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    tester.widget<CheckboxListTile>(finder).onChanged!(value);
    await tester.pumpAndSettle();
  }

  Finder detailField(String labelContains) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is SkTextField &&
          widget.label.contains(labelContains),
    );
  }

  testWidgets(
    'L’ancien champ libre unique a disparu, les cinq types sont '
    'proposés',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(tester, 'une ou plusieurs allergies', true);

      expect(
        find.textContaining('À quoi votre enfant est-il allergique'),
        findsNothing,
        reason:
            'La précision est désormais portée par la sous-question '
            'du type coché.',
      );

      expect(
        find.text('De quel type est cette allergie ?'),
        findsOneWidget,
      );

      for (final label in [
        'Alimentaire',
        'Médicamenteuse',
        "Piqûre d'insecte",
        'Contact ou environnement',
        'Autre',
      ]) {
        expect(
          categoryCheckbox(label),
          findsOneWidget,
          reason: 'Le type "$label" doit être proposé.',
        );
      }
    },
  );

  testWidgets(
    'Aucun type n’est coché par défaut',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(tester, 'une ou plusieurs allergies', true);

      for (final label in [
        'Alimentaire',
        'Médicamenteuse',
        "Piqûre d'insecte",
        'Contact ou environnement',
        'Autre',
      ]) {
        expect(
          tester.widget<CheckboxListTile>(categoryCheckbox(label)).value,
          isFalse,
          reason:
              'Une présélection ferait valider "$label" sans y penser.',
        );
      }
    },
  );

  testWidgets(
    'Chaque case cochée ouvre sa propre sous-question, et elle seule',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(tester, 'une ou plusieurs allergies', true);

      expect(
        detailField('À quoi ?'),
        findsNothing,
        reason: 'Rien coché, donc aucune sous-question.',
      );

      await tickCategory(tester, 'Alimentaire');

      expect(detailField('À quoi ?'), findsOneWidget);
      expect(detailField('À quel médicament ?'), findsNothing);
      expect(detailField('Quel insecte ?'), findsNothing);

      await tickCategory(tester, "Piqûre d'insecte");

      expect(detailField('Quel insecte ?'), findsOneWidget);
      expect(detailField('À quel médicament ?'), findsNothing);
    },
  );

  testWidgets(
    'La précision saisie est enregistrée sous son type',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(tester, 'une ou plusieurs allergies', true);
      await tickCategory(tester, 'Alimentaire');

      await tester.enterText(detailField('À quoi ?'), 'Arachide');
      await tester.pumpAndSettle();

      final allergy = controller.formData.allergies.single;

      expect(allergy.categories, equals({AllergyCategory.food}));
      expect(
        allergy.details[AllergyCategory.food],
        equals('Arachide'),
      );
      expect(allergy.label, equals('Arachide'));
    },
  );

  testWidgets(
    'Décocher un type efface la précision qu’il portait',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(tester, 'une ou plusieurs allergies', true);
      await tickCategory(tester, 'Alimentaire');

      await tester.enterText(detailField('À quoi ?'), 'Arachide');
      await tester.pumpAndSettle();

      await tickCategory(tester, 'Alimentaire', value: false);

      final allergy = controller.formData.allergies.single;

      expect(allergy.categories, isEmpty);
      expect(
        allergy.details,
        isEmpty,
        reason:
            'La réponse d’une sous-question retirée de l’écran ne doit '
            'pas survivre en arrière-plan.',
      );
    },
  );

  testWidgets(
    'On ne peut pas continuer avec une allergie sans type',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(
        tester,
        'pathologies diagnostiquées par un professionnel',
        false,
      );
      await answerYesNo(tester, 'une ou plusieurs allergies', true);

      final continueButton = find.widgetWithText(
        FilledButton,
        'Continuer',
      );

      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Indiquez le type de chaque allergie avant de continuer.',
        ),
        findsOneWidget,
      );

      expect(
        find.byType(DiagnosedPathologiesPage),
        findsOneWidget,
        reason: 'On doit rester sur la page tant que le type manque.',
      );
    },
  );

  testWidgets(
    'Une fois le type coché, on peut continuer',
    (tester) async {
      final controller = TransmissionController();
      await pumpPage(tester, controller);

      await answerYesNo(
        tester,
        'pathologies diagnostiquées par un professionnel',
        false,
      );
      await answerYesNo(tester, 'une ou plusieurs allergies', true);
      await tickCategory(tester, 'Alimentaire');

      await tester.enterText(detailField('À quoi ?'), 'Arachide');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        FilledButton,
        'Continuer',
      );

      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Indiquez le type de chaque allergie avant de continuer.',
        ),
        findsNothing,
      );

      expect(find.byType(DiagnosedPathologiesPage), findsNothing);
    },
  );
}
