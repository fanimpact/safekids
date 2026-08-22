import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/recommendation_engine/rules/universal_trigger_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool flashingLights = false,
  bool requiresGlassesOutdoors = false,
  bool heat = false,
  bool stressOrStrongEmotions = false,
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
      medicalObservations: [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: true,
        flashingLights: flashingLights,
        requiresGlassesOutdoors:
            requiresGlassesOutdoors,
        heat: heat,
        stressOrStrongEmotions:
            stressOrStrongEmotions,
      ),
      dailyTreatments: [],
      discontinuedTreatments: [],
      emergencyTreatments: [],
      allergies: [],
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
  const rules = UniversalTriggerRules();

  test(
    'Déclencheurs universels - photosensibilité',
    () {
      final child = _createTestChild(
        childId: 'test-photosensitivity',
        flashingLights: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('photosensitivity'),
      );

      expect(
        ids,
        isNot(
          contains('photosensitivity_glasses'),
        ),
      );
    },
  );

  test(
    'Déclencheurs universels - lunettes avec photosensibilité',
    () {
      final child = _createTestChild(
        childId: 'test-photosensitivity-glasses',
        flashingLights: true,
        requiresGlassesOutdoors: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('photosensitivity'),
      );

      expect(
        ids,
        contains('photosensitivity_glasses'),
      );
    },
  );

  test(
    'Déclencheurs universels - lunettes seules ne génèrent rien',
    () {
      final child = _createTestChild(
        childId: 'test-glasses-only',
        flashingLights: false,
        requiresGlassesOutdoors: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        isNot(
          contains('photosensitivity'),
        ),
      );

      expect(
        ids,
        isNot(
          contains('photosensitivity_glasses'),
        ),
      );
    },
  );

  test(
    'Déclencheurs universels - chaleur',
    () {
      final child = _createTestChild(
        childId: 'test-heat',
        heat: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('heat_vigilance'),
      );
    },
  );

  test(
    'Déclencheurs universels - stress et émotions fortes',
    () {
      final child = _createTestChild(
        childId: 'test-stress',
        stressOrStrongEmotions: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains(
          'stress_strong_emotions_vigilance',
        ),
      );
    },
  );

  test(
    'Déclencheurs universels - plusieurs facteurs peuvent apparaître ensemble',
    () {
      final child = _createTestChild(
        childId: 'test-all-triggers',
        flashingLights: true,
        requiresGlassesOutdoors: true,
        heat: true,
        stressOrStrongEmotions: true,
      );

      final recommendations = rules.evaluate(child);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('photosensitivity'),
      );

      expect(
        ids,
        contains('photosensitivity_glasses'),
      );

      expect(
        ids,
        contains('heat_vigilance'),
      );

      expect(
        ids,
        contains(
          'stress_strong_emotions_vigilance',
        ),
      );
    },
  );

  test(
    'Déclencheurs universels - aucun facteur ne génère rien',
    () {
      final child = _createTestChild(
        childId: 'test-no-trigger',
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}