import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/medical_event_data.dart';
import 'package:kidsrelay/models/medical_observation_data.dart';
import 'package:kidsrelay/transmission_pages/diagnosed_pathologies_page.dart';
import 'package:kidsrelay/transmission_pages/medical_events_page.dart';
import 'package:kidsrelay/transmission_pages/trigger_factors_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Arbitrage du 22/08/2026 : un champ n'est obligatoire que s'il est
/// indispensable à la sécurité de l'enfant.
///
/// D'où deux mouvements en sens inverse :
///
/// - les champs purement descriptifs (observation médicale, bloc
///   d'événement jamais commencé) ne bloquent plus ;
/// - les champs sans lesquels une information de sécurité DISPARAÎT
///   des fiches sans le dire (nom de pathologie, précision du type
///   d'allergie) deviennent obligatoires. Une allergie enregistrée
///   mais invisible est plus grave que n'importe quel blocage de
///   saisie.
void main() {
  Future<void> pumpMedicalEvents(
    WidgetTester tester,
    TransmissionController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MedicalEventsPage(
          transmissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPathologies(
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

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.text('Continuer');

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
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

  Future<void> tickCategory(
    WidgetTester tester,
    String label,
  ) async {
    final finder = find.byWidgetPredicate(
      (widget) =>
          widget is CheckboxListTile &&
          widget.title is Text &&
          (widget.title as Text).data == label,
    );

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    tester.widget<CheckboxListTile>(finder).onChanged!(true);
    await tester.pumpAndSettle();
  }

  Future<void> fillField(
    WidgetTester tester,
    String labelContains,
    String value,
  ) async {
    final finder = find.byWidgetPredicate(
      (widget) =>
          widget is SkTextField &&
          widget.label.contains(labelContains),
    );

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  group('Observation médicale : jamais obligatoire', () {
    testWidgets(
      'Une observation ajoutée puis laissée vide est abandonnée sans '
      'bloquer',
      (tester) async {
        final controller = TransmissionController();
        await pumpMedicalEvents(tester, controller);

        await tester.tap(find.text('Ajouter une observation'));
        await tester.pumpAndSettle();

        expect(find.text('Observation n°1'), findsOneWidget);

        await tapContinue(tester);

        expect(
          find.textContaining('Décrivez chaque observation'),
          findsNothing,
        );
        expect(controller.formData.medicalObservations, isEmpty);
        expect(find.byType(TriggerFactorsPage), findsOneWidget);
      },
    );

    testWidgets(
      'Une observation sans description mais avec une conclusion est '
      'conservée, et ne bloque pas',
      (tester) async {
        final controller = TransmissionController();
        await pumpMedicalEvents(tester, controller);

        await tester.tap(find.text('Ajouter une observation'));
        await tester.pumpAndSettle();

        await fillField(
          tester,
          'Conclusion',
          'Sans conséquence identifiée',
        );

        await tapContinue(tester);

        expect(find.byType(TriggerFactorsPage), findsOneWidget);
        expect(
          controller.formData.medicalObservations.single.conclusion,
          equals('Sans conséquence identifiée'),
          reason:
              'Rien n’est exigé, mais rien n’est perdu non plus : le '
              'bloc n’était pas vide.',
        );
      },
    );

    test(
      'Un profil enregistré avant le 19/08/2026 peut porter une entrée '
      'vide : elle est retirée au lieu de bloquer',
      () {
        final controller = TransmissionController();

        // Ce que la version d'avant le 19/08/2026 insérait d'office et
        // sauvegardait en silence : rouvrir un tel profil butait
        // ensuite sur une entrée que le parent n'avait jamais créée.
        controller.formData.medicalEvents.add(MedicalEventData());
        controller.formData.medicalObservations.add(
          MedicalObservationData(),
        );

        controller.dropEmptyMedicalEntries();

        expect(controller.formData.medicalEvents, isEmpty);
        expect(controller.formData.medicalObservations, isEmpty);
      },
    );

    test(
      'Une entrée réellement renseignée n’est jamais retirée',
      () {
        final controller = TransmissionController();

        controller.formData.medicalEvents.add(
          MedicalEventData(description: 'Crise convulsive'),
        );
        controller.formData.medicalObservations.add(
          MedicalObservationData(approximateDate: 'Mars 2025'),
        );

        controller.dropEmptyMedicalEntries();

        expect(controller.formData.medicalEvents, hasLength(1));
        expect(controller.formData.medicalObservations, hasLength(1));
      },
    );

    test(
      'Un événement dont seule une question Oui/Non est répondue n’est '
      'pas considéré comme vide',
      () {
        final controller = TransmissionController();

        controller.formData.medicalEvents.add(
          MedicalEventData(hospitalized: false),
        );

        controller.dropEmptyMedicalEntries();

        expect(
          controller.formData.medicalEvents,
          hasLength(1),
          reason:
              'Le parent a commencé à répondre : le bloc lui appartient '
              'et doit rester soumis à validation.',
        );
      },
    );
  });

  group('Nom de la pathologie : obligatoire', () {
    testWidgets(
      'Une pathologie sans nom bloque, parce qu’elle serait invisible '
      'sur toutes les fiches',
      (tester) async {
        final controller = TransmissionController();
        await pumpPathologies(tester, controller);

        await answerYesNo(
          tester,
          'pathologies diagnostiquées par un professionnel',
          true,
        );
        await answerYesNo(
          tester,
          'une ou plusieurs allergies',
          false,
        );
        await answerYesNo(
          tester,
          'suivie par un professionnel de santé référent',
          false,
        );

        await tapContinue(tester);

        expect(
          find.text('Nommez chaque pathologie avant de continuer.'),
          findsOneWidget,
        );
        expect(find.byType(DiagnosedPathologiesPage), findsOneWidget);
      },
    );

    testWidgets(
      'Nommée, elle laisse passer',
      (tester) async {
        final controller = TransmissionController();
        await pumpPathologies(tester, controller);

        await answerYesNo(
          tester,
          'pathologies diagnostiquées par un professionnel',
          true,
        );
        await answerYesNo(
          tester,
          'une ou plusieurs allergies',
          false,
        );
        await answerYesNo(
          tester,
          'suivie par un professionnel de santé référent',
          false,
        );

        await fillField(tester, 'Nom de la pathologie', 'Épilepsie');

        await tapContinue(tester);

        expect(
          find.text('Nommez chaque pathologie avant de continuer.'),
          findsNothing,
        );
        expect(find.byType(DiagnosedPathologiesPage), findsNothing);
      },
    );
  });

  group('Précision du type d’allergie : obligatoire', () {
    testWidgets(
      'Un type coché sans précision bloque, parce que l’allergie '
      'n’aurait aucun libellé à afficher',
      (tester) async {
        final controller = TransmissionController();
        await pumpPathologies(tester, controller);

        await answerYesNo(
          tester,
          'pathologies diagnostiquées par un professionnel',
          false,
        );
        await answerYesNo(
          tester,
          'une ou plusieurs allergies',
          true,
        );
        await tickCategory(tester, 'Alimentaire');

        await tapContinue(tester);

        expect(
          find.text(
            "Précisez chaque type d'allergie coché avant de continuer.",
          ),
          findsOneWidget,
        );
        expect(find.byType(DiagnosedPathologiesPage), findsOneWidget);

        // Sans cette règle, l'allergie serait enregistrée avec un
        // libellé nul et sautée partout.
        expect(
          controller.formData.allergies.single.label,
          isNull,
        );
      },
    );

    testWidgets(
      'Chaque type coché exige sa propre précision',
      (tester) async {
        final controller = TransmissionController();
        await pumpPathologies(tester, controller);

        await answerYesNo(
          tester,
          'pathologies diagnostiquées par un professionnel',
          false,
        );
        await answerYesNo(
          tester,
          'une ou plusieurs allergies',
          true,
        );

        await tickCategory(tester, 'Alimentaire');
        await fillField(tester, 'À quoi ?', 'Arachide');

        await tickCategory(tester, 'Médicamenteuse');

        await tapContinue(tester);

        expect(
          find.text(
            "Précisez chaque type d'allergie coché avant de continuer.",
          ),
          findsOneWidget,
          reason:
              'Le second type reste sans précision : il ne doit pas '
              'passer sous prétexte que le premier est rempli.',
        );

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        await fillField(
          tester,
          'À quel médicament ?',
          'Pénicilline',
        );

        await tapContinue(tester);

        expect(find.byType(DiagnosedPathologiesPage), findsNothing);
        expect(
          controller.formData.allergies.single.label,
          equals('Arachide / Pénicilline'),
        );
      },
    );

    testWidgets(
      'Répondre "Non" aux allergies n’exige évidemment rien',
      (tester) async {
        final controller = TransmissionController();
        await pumpPathologies(tester, controller);

        await answerYesNo(
          tester,
          'pathologies diagnostiquées par un professionnel',
          false,
        );
        await answerYesNo(
          tester,
          'une ou plusieurs allergies',
          false,
        );

        await tapContinue(tester);

        expect(find.byType(DiagnosedPathologiesPage), findsNothing);
        expect(controller.formData.allergies, isEmpty);
      },
    );
  });

  test(
    'Une allergie dont le type coché n’a pas de précision n’a pas de '
    'libellé — ce que la règle empêche désormais d’enregistrer',
    () {
      final allergy = AllergyData(
        categories: {AllergyCategory.food},
      );

      expect(allergy.label, isNull);
    },
  );
}
