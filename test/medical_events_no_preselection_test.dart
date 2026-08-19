import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/controllers/transmission_controller.dart';
import 'package:safekids/transmission_pages/medical_events_page.dart';
import 'package:safekids/transmission_pages/trigger_factors_page.dart';
import 'package:safekids/widgets/sk_text_field.dart';

/// Corrigé (19/08/2026, corrections de l'inventaire du 19/08/2026) :
/// MedicalEventsPage insérait automatiquement un événement et une
/// observation vides dès l'arrivée sur la page, et ne bloquait jamais
/// "Continuer" — un parent pouvait traverser la page sans rien
/// renseigner, tout en laissant une entrée vide enregistrée en
/// silence.
void main() {
  testWidgets(
    'Aucune entrée n’est présélectionnée, et Continuer est possible '
    'sans rien ajouter',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: MedicalEventsPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.formData.medicalEvents,
        isEmpty,
        reason:
            'Aucun événement ne doit être créé avant que le parent '
            'ne clique sur "Ajouter".',
      );
      expect(
        controller.formData.medicalObservations,
        isEmpty,
        reason:
            'Aucune observation ne doit être créée avant que le '
            'parent ne clique sur "Ajouter".',
      );
      expect(find.text('Événement n°1'), findsNothing);

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.byType(TriggerFactorsPage),
        findsOneWidget,
        reason:
            'Sans aucun événement ni observation ajoutés, "Continuer" '
            'doit fonctionner directement.',
      );
    },
  );

  testWidgets(
    'Un événement ajouté mais laissé vide bloque Continuer',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: MedicalEventsPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Ajouter un événement médical'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Événement n°1'), findsOneWidget);

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Décrivez chaque événement'),
        findsOneWidget,
        reason:
            'Un événement ajouté sans description doit bloquer, pas '
            'être enregistré vide en silence.',
      );
      expect(find.byType(MedicalEventsPage), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains(
                'événement médical important',
              ),
        ),
        'Crise convulsive',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Répondez par oui ou par non',
        ),
        findsOneWidget,
        reason:
            'La description est remplie, mais pas les questions '
            'oui/non de l’événement : doit encore bloquer.',
      );
    },
  );

  testWidgets(
    'Un événement ajouté peut être retiré complètement, jusqu’à zéro',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: MedicalEventsPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Ajouter un événement médical'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Événement n°1'), findsOneWidget);

      await tester.ensureVisible(find.text('Supprimer').first);
      await tester.tap(find.text('Supprimer').first);
      await tester.pumpAndSettle();

      expect(find.text('Événement n°1'), findsNothing);
      expect(controller.formData.medicalEvents, isEmpty);
    },
  );
}
