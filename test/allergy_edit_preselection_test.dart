import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/child_profile_draft.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/transmission_pages/diagnosed_pathologies_page.dart';
import 'package:kidsrelay/transmission_pages/identity_page.dart';
import 'package:kidsrelay/transmission_pages/medical_events_page.dart';
import 'package:kidsrelay/transmission_pages/treatments_page.dart';
import 'package:kidsrelay/transmission_pages/trigger_factors_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';
import 'package:kidsrelay/widgets/sk_yes_no_field.dart';

/// Reproduit le scénario signalé par l'utilisatrice, en rejouant la vraie
/// navigation et les vrais taps à l'écran (pas seulement la logique en
/// isolation) : cocher "Allergie importante", valider, puis revenir sur
/// "Modifier le profil" et vérifier que la réponse est toujours
/// présélectionnée.
void main() {
  // Invoque directement le callback onChanged du champ (le même code que
  // celui déclenché par un vrai tap sur "Oui"/"Non"), pour ne pas dépendre
  // du hit-testing bas niveau du SegmentedButton dans les tests.
  Future<void> answerYesNoField(
    WidgetTester tester,
    String fieldLabelContains,
    bool value,
  ) async {
    final fieldFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SkYesNoField &&
          widget.label.contains(fieldLabelContains),
    );

    await tester.ensureVisible(fieldFinder);
    await tester.pumpAndSettle();

    final field = tester.widget<SkYesNoField>(fieldFinder);
    field.onChanged(value);
    await tester.pumpAndSettle();
  }

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

  Future<void> pumpFreshIdentityPage(
    WidgetTester tester,
    TransmissionController controller,
  ) async {
    // pumpWidget() sur un arbre de même forme (même MaterialApp/même
    // IdentityPage) réutilise le Navigator existant au lieu de repartir
    // à zéro (donc une éventuelle page déjà poussée précédemment reste
    // affichée). On force un vrai redémarrage en passant par un écran
    // vide entre les deux, comme un vrai relancement de l'app.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: IdentityPage(transmissionController: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> continueFromIdentityPage(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Bout en bout : cocher Allergie importante, valider, revenir sur '
    'Modifier -> toujours coché',
    (tester) async {
      // 1. Création : IdentityPage.
      final createController = TransmissionController();

      // La date de naissance n'a pas de champ texte (sélecteur de date
      // uniquement) : on la renseigne directement sur le contrôleur,
      // avant de construire l'écran, pour que l'état initial de la
      // page la reprenne comme si elle avait été choisie via le
      // sélecteur.
      createController.updateDateOfBirth(DateTime(2016, 6, 1));

      await pumpFreshIdentityPage(tester, createController);

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Prénom'),
        ),
        'Camille',
      );

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Nom de famille'),
        ),
        'Test',
      );

      await continueFromIdentityPage(tester);

      expect(find.byType(DiagnosedPathologiesPage), findsOneWidget);

      // 2. Pathologies : Non. Allergies : Oui + un allergène.
      await answerYesNoField(
        tester,
        'pathologies diagnostiquées par un professionnel',
        false,
      );

      await answerYesNoField(
        tester,
        'une ou plusieurs allergies',
        true,
      );

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('allergique'),
        ),
        'Arachides',
      );
      await tester.pumpAndSettle();

      expect(
        yesNoValue(tester, 'une ou plusieurs allergies'),
        isTrue,
        reason:
            'Juste après avoir coché "Oui", le bouton doit rester sur Oui.',
      );

      // 3. Traverse le reste du vrai parcours (comme dans l'app) :
      // Événements médicaux -> Facteurs déclenchants -> Traitements,
      // avant de "Valider" -- pour vérifier qu'aucune de ces pages
      // n'efface l'allergie en cours de route.
      await tester.ensureVisible(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.byType(MedicalEventsPage), findsOneWidget);

      await tester.ensureVisible(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.byType(TriggerFactorsPage), findsOneWidget);

      // Toutes les questions individuelles sont désormais posées à tout
      // le monde (plus de question filtre) et obligatoires avant de
      // continuer.
      await answerYesNoField(
        tester,
        'lumières clignotantes',
        false,
      );
      await answerYesNoField(
        tester,
        'chaleur nécessite',
        false,
      );
      await answerYesNoField(
        tester,
        'fatigue ou le manque de sommeil',
        false,
      );
      await answerYesNoField(
        tester,
        'bruit nécessite',
        false,
      );
      await answerYesNoField(
        tester,
        'foule nécessite',
        false,
      );
      await answerYesNoField(
        tester,
        'espaces confinés',
        false,
      );
      await answerYesNoField(
        tester,
        'effort physique nécessite',
        false,
      );
      await answerYesNoField(
        tester,
        'stress ou les émotions fortes',
        false,
      );
      await answerYesNoField(
        tester,
        'contact avec l’eau',
        false,
      );
      await answerYesNoField(
        tester,
        'présence d’animaux',
        false,
      );
      await answerYesNoField(
        tester,
        'hauteur nécessite',
        false,
      );

      await tester.ensureVisible(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.byType(TreatmentsPage), findsOneWidget);

      expect(
        createController.formData.allergies,
        hasLength(1),
        reason:
            'L\'allergie doit toujours être présente une fois arrivé '
            'sur la page des traitements.',
      );

      final savedProfile = createController.validateAndGetProfile();

      expect(
        savedProfile.allergies,
        hasLength(1),
        reason: 'L\'allergie saisie doit être conservée après validation.',
      );

      // 4. "Modifier le profil" -> "Informations essentielles" : même
      // construction que child_profile_page.dart, sur un écran neuf
      // (comme une vraie nouvelle navigation dans l'app).
      final editController = TransmissionController(
        initialDraft: ChildProfileDraft.fromChildProfileData(
          savedProfile,
        ),
        isEditing: true,
      );

      await pumpFreshIdentityPage(tester, editController);
      await continueFromIdentityPage(tester);

      expect(find.byType(DiagnosedPathologiesPage), findsOneWidget);

      expect(
        yesNoValue(tester, 'une ou plusieurs allergies'),
        isTrue,
        reason:
            'En revenant sur Modifier, "Oui" doit rester présélectionné '
            'pour la question allergies.',
      );
    },
  );

  testWidgets(
    'Cas isolé : enfant avec pathologie ET allergie déjà enregistrées',
    (tester) async {
      final savedProfile = ChildProfileData(
        childId: 'test-child-2',
        identity: IdentityData(
          firstName: 'Test',
          lastName: 'Nom',
          dateOfBirth: DateTime(2016, 6, 1),
          hasDiagnosedPathologies: true,
        ),
        pathologies: [PathologyData(name: 'Épilepsie')],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: [AllergyData(allergen: 'Arachides')],
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      );

      final editController = TransmissionController(
        initialDraft: ChildProfileDraft.fromChildProfileData(
          savedProfile,
        ),
        isEditing: true,
      );

      await pumpFreshIdentityPage(tester, editController);
      await continueFromIdentityPage(tester);

      expect(
        yesNoValue(tester, 'une ou plusieurs allergies'),
        isTrue,
      );
    },
  );

  testWidgets(
    'Cas isolé : IdentityPage ne pose plus de question filtre, on continue '
    'directement même sans hasDiagnosedPathologies renseigné',
    (tester) async {
      final savedProfile = ChildProfileData(
        childId: 'test-child-3',
        identity: IdentityData(
          firstName: 'Test',
          lastName: 'Nom',
          dateOfBirth: DateTime(2016, 6, 1),
          hasDiagnosedPathologies: null,
        ),
        pathologies: const [],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: [AllergyData(allergen: 'Arachides')],
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      );

      final editController = TransmissionController(
        initialDraft: ChildProfileDraft.fromChildProfileData(
          savedProfile,
        ),
        isEditing: true,
      );

      await pumpFreshIdentityPage(tester, editController);

      // Plus de question filtre à répondre sur IdentityPage : on doit
      // pouvoir continuer directement.
      await continueFromIdentityPage(tester);

      expect(find.byType(DiagnosedPathologiesPage), findsOneWidget);

      expect(
        yesNoValue(tester, 'une ou plusieurs allergies'),
        isTrue,
      );
    },
  );

  testWidgets(
    'Cas signalé : allergie répondue "Non" (liste vide) reste sur "Non" '
    'en revenant sur Modifier, comme les autres champs',
    (tester) async {
      final savedProfile = ChildProfileData(
        childId: 'test-child-4',
        identity: IdentityData(
          firstName: 'Test',
          lastName: 'Nom',
          dateOfBirth: DateTime(2016, 6, 1),
          hasDiagnosedPathologies: true,
        ),
        hasPathologies: false,
        hasAllergies: false,
        pathologies: const [],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: const [],
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      );

      final editController = TransmissionController(
        initialDraft: ChildProfileDraft.fromChildProfileData(
          savedProfile,
        ),
        isEditing: true,
      );

      await pumpFreshIdentityPage(tester, editController);
      await continueFromIdentityPage(tester);

      expect(
        yesNoValue(tester, 'pathologies diagnostiquées par un professionnel'),
        isFalse,
        reason:
            'Répondu "Non" à la création : doit rester "Non" (pas vide) '
            'en revenant sur Modifier.',
      );

      expect(
        yesNoValue(tester, 'une ou plusieurs allergies'),
        isFalse,
        reason:
            'Répondu "Non" à la création : doit rester "Non" (pas vide) '
            'en revenant sur Modifier.',
      );
    },
  );
}
