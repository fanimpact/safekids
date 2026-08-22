import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/recommendation_engine/rules/environment_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool height = false,
  HeightVigilance? heightVigilance,
  String? otherHeightVigilance,
  bool animals = false,
  AnimalVigilance? animalVigilance,
  String? otherAnimalVigilance,
  bool noise = false,
  bool crowd = false,
  bool confinedSpaces = false,
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
        height: height,
        heightVigilance: heightVigilance,
        otherHeightVigilance: otherHeightVigilance,
        animals: animals,
        animalVigilance: animalVigilance,
        otherAnimalVigilance: otherAnimalVigilance,
        noise: noise,
        crowd: crowd,
        confinedSpaces: confinedSpaces,
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
  const rules = EnvironmentRules();

  test(
    'Hauteur - enfant qui ne perçoit pas le danger',
    () {
      final child = _createTestChild(
        childId: 'test-height-danger',
        height: true,
        heightVigilance:
            HeightVigilance.doesNotPerceiveDanger,
      );

      final activity = ActivitySessionData(
        hasHeightActivity: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('height_does_not_perceive_danger'),
      );
    },
  );

  test(
    'Hauteur - aucune recommandation si activité sans hauteur',
    () {
      final child = _createTestChild(
        childId: 'test-height-no-activity',
        height: true,
        heightVigilance:
            HeightVigilance.vertigoOrImportantFear,
      );

      final activity = ActivitySessionData(
        hasHeightActivity: false,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final heightRecommendations =
          recommendations.where(
        (recommendation) =>
            recommendation.id.startsWith('height_'),
      );

      expect(
        heightRecommendations,
        isEmpty,
      );
    },
  );

  test(
    'Animaux - peur importante',
    () {
      final child = _createTestChild(
        childId: 'test-animal-fear',
        animals: true,
        animalVigilance:
            AnimalVigilance.importantFear,
      );

      final activity = ActivitySessionData(
        hasAnimalContact: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('animals_important_fear'),
      );
    },
  );

  test(
    'Animaux - approche sans percevoir le danger',
    () {
      final child = _createTestChild(
        childId: 'test-animal-danger',
        animals: true,
        animalVigilance:
            AnimalVigilance.approachesWithoutPerceivingDanger,
      );

      final activity = ActivitySessionData(
        hasAnimalContact: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains(
          'animals_approaches_without_perceiving_danger',
        ),
      );
    },
  );

  test(
    'Environnement - bruit foule et espace confiné',
    () {
      final child = _createTestChild(
        childId: 'test-environment',
        noise: true,
        crowd: true,
        confinedSpaces: true,
      );

      final activity = ActivitySessionData(
        hasLoudEnvironment: true,
        hasLargeCrowd: true,
        hasConfinedSpace: true,
      );

      final recommendations =
          rules.evaluate(child, activity);

      final ids = recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('noise_vigilance'),
      );

      expect(
        ids,
        contains('crowd_vigilance'),
      );

      expect(
        ids,
        contains('confined_space_vigilance'),
      );
    },
  );

  test(
    'Environnement - aucun faux déclenchement sans contexte correspondant',
    () {
      final child = _createTestChild(
        childId: 'test-no-context',
        noise: true,
        crowd: true,
        confinedSpaces: true,
        height: true,
        heightVigilance:
            HeightVigilance.doesNotPerceiveDanger,
        animals: true,
        animalVigilance:
            AnimalVigilance.importantFear,
      );

      final activity = ActivitySessionData(
        hasHeightActivity: false,
        hasAnimalContact: false,
        hasLoudEnvironment: false,
        hasLargeCrowd: false,
        hasConfinedSpace: false,
      );

      final recommendations =
          rules.evaluate(child, activity);

      expect(
        recommendations,
        isEmpty,
      );
    },
  );
}