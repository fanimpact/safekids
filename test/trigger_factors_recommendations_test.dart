import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
import 'package:safekids/models/activity_session/complete_activity_session_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/recommendation_engine/recommendation_engine.dart';
import 'package:safekids/repositories/child_repository.dart';

void main() {
  test(
    'Facteurs déclenchants (fatigue, effort physique, eau libre, libre) remontent sans doublon',
    () {
      const childId = 'test-trigger-factors-full';

      final child = ChildProfileData(
        childId: childId,
        userId: 'test-family',
        identity: IdentityData(
          firstName: 'Camille',
          lastName: 'Test',
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
          flashingLights: false,
          heat: false,
          fatigueOrLackOfSleep: true,
          noise: false,
          crowd: false,
          confinedSpaces: false,
          physicalEffort: true,
          stressOrStrongEmotions: false,
          waterContact: true,
          waterVigilance: WaterVigilance.other,
          otherWaterVigilance:
              'Éviter les éclaboussures au visage',
          animals: false,
          height: false,
          other:
              'Sensible aux changements de dernière minute',
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
      );

      ChildRepository.instance.addChild(child);

      final activitySession = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test facteurs déclenchants',
          hasWaterNearby: true,
          childrenWillEnterWater: true,
          hasSignificantPhysicalEffort: true,
        ),
        childIds: const [childId],
      );

      final result = RecommendationEngine()
          .generateRecommendations(activitySession);

      final childResult = result.childResults.firstWhere(
        (recommendationResult) =>
            recommendationResult.childId == childId,
      );

      final ids = childResult.recommendations
          .map((recommendation) => recommendation.id)
          .toList();

      // Pas de doublon d'identifiant dans la fiche générée.
      expect(ids.length, ids.toSet().length);

      // Les 4 facteurs déclenchants remontent bien.
      expect(ids, contains('fatigue_vigilance'));
      expect(
        ids,
        contains('trigger_physical_effort_vigilance'),
      );
      expect(
        ids,
        contains('trigger_water_other_vigilance'),
      );
      expect(ids, contains('other_trigger_factor'));

      // Le texte libre est repris tel quel, pas reformulé.
      final waterRecommendation =
          childResult.recommendations.firstWhere(
        (recommendation) =>
            recommendation.id ==
            'trigger_water_other_vigilance',
      );

      expect(
        waterRecommendation.text,
        'Éviter les éclaboussures au visage',
      );

      final otherRecommendation =
          childResult.recommendations.firstWhere(
        (recommendation) =>
            recommendation.id == 'other_trigger_factor',
      );

      expect(
        otherRecommendation.text,
        'Sensible aux changements de dernière minute',
      );

      // Rien qui n'a pas de sens : les facteurs non
      // renseignés (chaleur, lumières...) ne déclenchent
      // rien, et la vigilance "effort physique intense"
      // du profil marche (mécanisme distinct, non
      // renseigné ici) ne se déclenche pas non plus.
      expect(ids, isNot(contains('heat_vigilance')));
      expect(ids, isNot(contains('photosensitivity')));
      expect(
        ids,
        isNot(
          contains('intense_physical_effort_vigilance'),
        ),
      );
      expect(
        ids,
        isNot(contains('trigger_water_cannot_swim')),
      );
      expect(
        ids,
        isNot(
          contains('trigger_water_may_jump_into_water'),
        ),
      );
    },
  );
}
