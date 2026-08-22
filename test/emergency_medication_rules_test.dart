import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/emergency_treatment_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/recommendation_engine/models/recommendation_category.dart';
import 'package:kidsrelay/recommendation_engine/rules/emergency_medication_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  List<PathologyData> pathologies = const [],
  List<EmergencyTreatmentData> emergencyTreatments = const [],
  List<AllergyData> allergies = const [],
}) {
  return CompleteChildProfileData(
    essentialInformation: ChildProfileData(
      childId: childId,
      userId: 'test-family',
      identity: IdentityData(
        firstName: 'Test',
        lastName: 'Enfant',
        dateOfBirth: null,
        heightCm: null,
        weightKg: null,
        hasDiagnosedPathologies: pathologies.isNotEmpty,
      ),
      pathologies: pathologies,
      medicalEvents: [],
      medicalObservations: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
      discontinuedTreatments: [],
      emergencyTreatments: emergencyTreatments,
      allergies: allergies,
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor: PrimaryCareDoctorData(
        name: null,
        workplace: null,
        phoneNumber: null,
      ),
    ),
  );
}

void main() {
  const rules = EmergencyMedicationRules();

  test(
    'Médicament urgence général - nom seul',
    () {
      final child = _createTestChild(
        childId: 'test-emergency-simple',
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Buccolam',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.id,
        'emergency_treatment_0',
      );

      expect(
        recommendations.first.category,
        RecommendationCategory.emergencyMedication,
      );

      expect(
        recommendations.first.text,
        'Pensez à emporter le traitement d’urgence : Buccolam',
      );
    },
  );

  test(
    'Médicament urgence général - dosage, condition et mode sont '
    'tous les trois affichés',
    () {
      // Corrigé (19/08/2026) : la condition d'administration (dans
      // quelle situation donner le traitement) était saisie et
      // affichée sur les deux fiches de référence, mais jamais
      // reprise dans ce rappel — la seule recommandation censée se
      // déclencher à chaque préparation d'activité.
      final child = _createTestChild(
        childId: 'test-emergency-details',
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Médicament test',
            dosage: '5 mg',
            administrationCondition:
                'En cas de crise',
            administrationMethod:
                'Voie buccale',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      final text = recommendations.first.text;

      expect(
        text,
        contains('Médicament test'),
      );

      expect(
        text,
        contains('Dosage : 5 mg'),
      );

      expect(
        text,
        contains(
          'À donner si : En cas de crise',
        ),
      );

      expect(
        text,
        contains(
          'Mode d’administration : Voie buccale',
        ),
      );
    },
  );

  test(
    'Médicaments urgence - plusieurs traitements sont tous conservés',
    () {
      final child = _createTestChild(
        childId: 'test-emergency-multiple',
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Médicament A',
          ),
          EmergencyTreatmentData(
            medicationName: 'Médicament B',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map(
            (recommendation) => recommendation.id,
          )
          .toSet();

      final texts = recommendations
          .map(
            (recommendation) => recommendation.text,
          )
          .toSet();

      expect(
        ids,
        contains('emergency_treatment_0'),
      );

      expect(
        ids,
        contains('emergency_treatment_1'),
      );

      expect(
        texts,
        contains(
          'Pensez à emporter le traitement d’urgence : Médicament A',
        ),
      );

      expect(
        texts,
        contains(
          'Pensez à emporter le traitement d’urgence : Médicament B',
        ),
      );
    },
  );

  test(
    'Médicament urgence vide est ignoré',
    () {
      final child = _createTestChild(
        childId: 'test-empty-emergency',
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: '   ',
            dosage: '5 mg',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );

  test(
    'Un traitement d’urgence lié à une allergie ne génère qu’une seule '
    'recommandation (plus de saisie séparée possible sur l’allergie '
    'elle-même)',
    () {
      const allergyId = 'test-allergy-single-path';

      final child = _createTestChild(
        childId: 'test-single-emergency-source',
        allergies: [
          AllergyData(
            allergyId: allergyId,
            categories: {AllergyCategory.insectSting},
            details: {
              AllergyCategory.insectSting: 'Guêpe',
            },
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Traitement urgence guêpe',
            relatedAllergyIds: const [
              allergyId,
            ],
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
        reason:
            'Un seul chemin de saisie existe désormais pour un '
            'traitement d’urgence lié à une allergie : la liste '
            'générale des traitements d’urgence.',
      );

      expect(
        recommendations.first.id,
        'emergency_treatment_0',
      );
    },
  );

  test(
    'Traitement urgence général peut être relié à une pathologie',
    () {
      const pathologyId =
          'test-pathology-epilepsy';

      final child = _createTestChild(
        childId: 'test-pathology-link',
        pathologies: [
          PathologyData(
            pathologyId: pathologyId,
            name: 'Épilepsie',
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Buccolam',
            relatedPathologyIds: const [
              pathologyId,
            ],
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.text,
        contains('Épilepsie'),
      );

      expect(
        recommendations.first.text,
        contains('Buccolam'),
      );
    },
  );

  test(
    'Traitement urgence général peut être relié à une allergie',
    () {
      const allergyId =
          'test-allergy-wasp';

      final child = _createTestChild(
        childId: 'test-allergy-link',
        allergies: [
          AllergyData(
            allergyId: allergyId,
            categories: {AllergyCategory.insectSting},
            details: {
              AllergyCategory.insectSting: 'Piqûres de guêpe',
            },
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Desloratadine',
            relatedAllergyIds: const [
              allergyId,
            ],
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        1,
      );

      expect(
        recommendations.first.text,
        contains('Piqûres de guêpe'),
      );

      expect(
        recommendations.first.text,
        contains('Desloratadine'),
      );
    },
  );

  test(
    'Plusieurs médicaments peuvent être reliés à la même allergie',
    () {
      const allergyId =
          'test-allergy-wasp-multiple';

      final child = _createTestChild(
        childId: 'test-allergy-multiple-medications',
        allergies: [
          AllergyData(
            allergyId: allergyId,
            categories: {AllergyCategory.insectSting},
            details: {
              AllergyCategory.insectSting: 'Piqûres de guêpe',
            },
          ),
        ],
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName: 'Desloratadine',
            relatedAllergyIds: const [
              allergyId,
            ],
          ),
          EmergencyTreatmentData(
            medicationName: 'Solupred',
            relatedAllergyIds: const [
              allergyId,
            ],
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations.length,
        2,
      );

      final texts = recommendations
          .map(
            (recommendation) => recommendation.text,
          )
          .toList();

      expect(
        texts.any(
          (text) =>
              text.contains(
                'Piqûres de guêpe',
              ) &&
              text.contains(
                'Desloratadine',
              ),
        ),
        isTrue,
      );

      expect(
        texts.any(
          (text) =>
              text.contains(
                'Piqûres de guêpe',
              ) &&
              text.contains(
                'Solupred',
              ),
        ),
        isTrue,
      );
    },
  );
}