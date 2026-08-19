import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/emergency_mode/emergency_mode_button_list_page.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/emergency_treatment_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';

/// Corrigé (19/08/2026) : le Mode Urgence affichait les 6 étapes
/// numérotées d'un protocole d'urgence (ex. épilepsie), mais jamais le
/// traitement d'urgence associé (nom, dose, condition, mode) — un
/// accompagnant qui devait "administrer BUCCOLAM" à l'étape 6 n'avait
/// aucun moyen de savoir la dose. Reproduit ici le cas réel de Théo
/// (profil réel vérifié en base avant d'écrire ce correctif).
void main() {
  CompleteChildProfileData buildChild({
    required List<PathologyData> pathologies,
    List<AllergyData> allergies = const [],
    required List<EmergencyTreatmentData> emergencyTreatments,
  }) {
    return CompleteChildProfileData(
      essentialInformation: ChildProfileData(
        childId: 'test-child',
        userId: 'test-user',
        identity: IdentityData(firstName: 'Théo'),
        pathologies: pathologies,
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        allergies: allergies,
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: emergencyTreatments,
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      ),
    );
  }

  testWidgets(
    'Le traitement d’urgence relié par mot-clé (profil déjà existant, '
    'cas réel de Théo) s’affiche sous la bonne étape, dose comprise',
    (tester) async {
      final child = buildChild(
        pathologies: [
          PathologyData(
            pathologyId: 'pathology_1',
            name: 'Epilepsie',
            emergencyInstructionSteps: const [
              'Eloigner objets risquant de blesser',
              'Allonger en PLS',
              'Verifier qu il n y a rien dans la bouche ou enlever',
              'Declencher chrono',
              'Appeler secours',
              'Au bout de 5 min administrer BUCCOLAM dans la joue',
            ],
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'BUCCOLAM',
            dosage: '1 seringue',
            administrationCondition: 'crise plus de 5 min',
            administrationMethod: 'dans la bouche(joue)',
            relatedPathologyIds: const ['pathology_1'],
            // Pas de administrationStepByPathologyId : reproduit un
            // profil rempli avant ce correctif, comme celui de Théo.
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyModeButtonListPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urgence liée à : Epilepsie'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          '6. Au bout de 5 min administrer BUCCOLAM dans la joue',
        ),
        findsOneWidget,
      );

      expect(
        find.textContaining('1 seringue'),
        findsOneWidget,
        reason:
            'La dose doit être visible sur cet écran — c’est '
            'exactement ce qui manquait avant ce correctif.',
      );

      expect(
        find.textContaining('BUCCOLAM — 1 seringue'),
        findsOneWidget,
        reason:
            'Le bloc traitement doit contenir nom, dose et '
            'condition ensemble.',
      );
    },
  );

  testWidgets(
    'Un traitement relié à la pathologie mais sans étape choisie '
    's’affiche quand même, dans le filet de sécurité',
    (tester) async {
      final child = buildChild(
        pathologies: [
          PathologyData(
            pathologyId: 'pathology_1',
            name: 'Asthme',
            emergencyInstructionSteps: const [
              'Faire asseoir l’enfant',
              'Le rassurer',
            ],
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Ventoline',
            dosage: '2 bouffées',
            administrationCondition: 'gêne respiratoire',
            relatedPathologyIds: const ['pathology_1'],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyModeButtonListPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urgence liée à : Asthme'));
      await tester.pumpAndSettle();

      expect(
        find.text('Traitement à disposition pour cette urgence'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ventoline — 2 bouffées'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '"Autre urgence" liste tous les traitements du profil, y compris '
    'ceux non reliés à une pathologie ou une allergie',
    (tester) async {
      final child = buildChild(
        pathologies: [
          PathologyData(
            pathologyId: 'pathology_1',
            name: 'Epilepsie',
            emergencyInstructionSteps: const ['Mettre en PLS'],
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'BUCCOLAM',
            dosage: '1 seringue',
            administrationCondition: 'crise plus de 5 min',
            relatedPathologyIds: const ['pathology_1'],
          ),
          EmergencyTreatmentData(
            medicationName: 'Adrénaline',
            dosage: '1 injection',
            administrationCondition: 'choc anaphylactique',
            // Ni relatedPathologyIds ni relatedAllergyIds : un
            // traitement "orphelin" doit rester visible sur "Autre
            // urgence", jamais invisible.
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyModeButtonListPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Autre urgence'));
      await tester.pumpAndSettle();

      expect(
        find.text('Traitements d’urgence renseignés dans le profil'),
        findsOneWidget,
      );
      expect(
        find.textContaining('BUCCOLAM — 1 seringue'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Adrénaline — 1 injection'),
        findsOneWidget,
        reason:
            'Un traitement saisi dans le profil ne doit jamais être '
            'invisible pendant une crise, même sans lien à une '
            'pathologie ou une allergie précise.',
      );

      expect(
        find.textContaining(
          'Mettez l’enfant en sécurité et appelez les secours',
        ),
        findsOneWidget,
        reason:
            'Le message générique existant doit rester affiché en '
            'plus de la liste des traitements, pas être remplacé.',
      );
    },
  );

  testWidgets(
    'Aucun traitement d’urgence renseigné : rien ne change par '
    'rapport à avant ce correctif',
    (tester) async {
      final child = buildChild(
        pathologies: [
          PathologyData(
            pathologyId: 'pathology_1',
            name: 'Epilepsie',
            emergencyInstructionSteps: const ['Mettre en PLS'],
          ),
        ],
        emergencyTreatments: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyModeButtonListPage(child: child),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urgence liée à : Epilepsie'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1. Mettre en PLS'), findsOneWidget);
      expect(
        find.text('Traitement à disposition pour cette urgence'),
        findsNothing,
      );
    },
  );
}
