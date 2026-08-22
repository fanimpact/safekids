import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/transmission_pages/contacts_page.dart';
import 'package:kidsrelay/transmission_pages/treatments_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Corrigé (19/08/2026) : "Dans quelle situation doit-il être
/// administré ?" (le champ dont dépend le rappel affiché en Mode
/// Urgence) pouvait être laissé vide sans bloquer "Continuer" — ce
/// test vérifie que ce n'est plus le cas.
void main() {
  Future<void> answerYesNo(
    WidgetTester tester, {
    required String label,
    required bool yes,
  }) async {
    final field = find.ancestor(
      of: find.text(label),
      matching: find.byType(SkYesNoField),
    );

    await tester.ensureVisible(field);
    await tester.tap(
      find.descendant(
        of: field,
        matching: find.text(yes ? 'Oui' : 'Non'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Un traitement d’urgence nommé mais sans situation '
    'd’administration bloque Continuer',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: TreatmentsPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerYesNo(
        tester,
        label:
            'En dehors des traitements ponctuels '
            '(antibiotiques, Doliprane...), votre enfant '
            'suit-il un ou plusieurs traitements quotidiens '
            'prescrits ?',
        yes: false,
      );
      await answerYesNo(
        tester,
        label:
            'Votre enfant a-t-il arrêté un traitement '
            'récemment ?',
        yes: false,
      );
      await answerYesNo(
        tester,
        label:
            'Votre enfant dispose-t-il d’un ou plusieurs '
            'traitements d’urgence prescrits ?',
        yes: true,
      );
      await answerYesNo(
        tester,
        label:
            'Votre enfant utilise-t-il un ou plusieurs '
            'dispositifs médicaux ?',
        yes: false,
      );

      // Répondre "Oui" crée déjà un premier traitement vide
      // (`ensureFirstEmergencyTreatment`) — pas besoin de taper sur
      // "Ajouter un traitement d'urgence" pour celui-ci.
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label == 'Nom du traitement',
        ),
        'BUCCOLAM',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Indiquez dans quelle situation',
        ),
        findsOneWidget,
        reason:
            'Sans cette information, le rappel affiché en Mode '
            'Urgence n’aurait rien à montrer.',
      );
      expect(find.byType(TreatmentsPage), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label ==
                  'Dans quelle situation doit-il être '
                      'administré ?',
        ),
        'crise plus de 5 min',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.byType(ContactsPage),
        findsOneWidget,
        reason:
            'Une fois la situation renseignée, "Continuer" doit '
            'enfin fonctionner.',
      );
    },
  );
}
