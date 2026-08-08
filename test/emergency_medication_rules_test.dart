import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/emergency_treatment_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/recommendation_engine/models/recommendation_category.dart';
import 'package:safekids/recommendation_engine/rules/emergency_medication_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
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
        hasDiagnosedPathologies: false,
      ),
      pathologies: [],
      medicalEvents: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
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
        'Buccolam',
      );
    },
  );

  test(
    'Médicament urgence général - dosage condition et mode sont conservés',
    () {
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
          'Condition d’administration : En cas de crise',
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
          .map((recommendation) => recommendation.id)
          .toSet();

      final texts = recommendations
          .map((recommendation) => recommendation.text)
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
        contains('Médicament A'),
      );

      expect(
        texts,
        contains('Médicament B'),
      );
    },
  );

  test(
    'Allergie - traitement urgence est repris avec dosage et allergène',
    () {
      final child = _createTestChild(
        childId: 'test-allergy-emergency',
        allergies: [
          AllergyData(
            allergen: 'Arachide',
            hasEmergencyTreatment: true,
            emergencyTreatmentName:
                'Auto-injecteur test',
            emergencyTreatmentDosage:
                '0,3 mg',
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
        'allergy_emergency_treatment_0',
      );

      expect(
        recommendations.first.category,
        RecommendationCategory.emergencyMedication,
      );

      expect(
        recommendations.first.text,
        contains('Auto-injecteur test'),
      );

      expect(
        recommendations.first.text,
        contains('Dosage : 0,3 mg'),
      );

      expect(
        recommendations.first.text,
        contains('Allergie : Arachide'),
      );
    },
  );

  test(
    'Allergie - aucun traitement urgence ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-allergy-no-emergency',
        allergies: [
          AllergyData(
            allergen: 'Pollen',
            hasEmergencyTreatment: false,
            emergencyTreatmentName:
                'Médicament non utilisé',
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
    'Traitement général et traitement allergie peuvent apparaître ensemble',
    () {
      final child = _createTestChild(
        childId: 'test-both-emergency-sources',
        emergencyTreatments: [
          EmergencyTreatmentData(
            medicationName:
                'Traitement urgence général',
          ),
        ],
        allergies: [
          AllergyData(
            allergen: 'Guêpe',
            hasEmergencyTreatment: true,
            emergencyTreatmentName:
                'Traitement urgence allergie',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('emergency_treatment_0'),
      );

      expect(
        ids,
        contains('allergy_emergency_treatment_0'),
      );

      expect(
        recommendations.length,
        2,
      );
    },
  );
}