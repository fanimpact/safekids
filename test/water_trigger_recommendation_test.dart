import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/activity_profile_data.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
import 'package:safekids/models/activity_session/complete_activity_session_data.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/aquatic_activity_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/clothing_data.dart';
import 'package:safekids/models/communication_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/other_information_data.dart';
import 'package:safekids/models/overnight_stay_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/safety_data.dart';
import 'package:safekids/models/toilets_data.dart';
import 'package:safekids/models/transitions_data.dart';
import 'package:safekids/models/transport_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';
import 'package:safekids/models/walking_effort_data.dart';
import 'package:safekids/recommendation_engine/recommendation_engine.dart';
import 'package:safekids/repositories/child_repository.dart';

/// Bug trouvé lors de l'audit du moteur de recommandations (2026-08-15) :
/// "l'enfant ne sait pas nager" (facteur déclenchant du profil santé)
/// était généré deux fois avec des textes différents (une fois par
/// WaterRules, une fois par EnvironmentRules) quand le profil activité
/// cochait "adaptations nécessaires" pour l'eau — et complètement
/// absent si cette case n'était pas cochée, alors que c'est une
/// information de santé indépendante de cette case.
void main() {
  ChildProfileData buildChild({
    required String childId,
    required bool requiresAdaptations,
  }) {
    return ChildProfileData(
      childId: childId,
      userId: 'test-user',
      identity: IdentityData(firstName: 'Test'),
      pathologies: const <PathologyData>[],
      medicalEvents: const [],
      medicalObservations: const [],
      triggerFactors: TriggerFactorData(
        hasTriggerFactors: true,
        waterContact: true,
        waterVigilance: WaterVigilance.cannotSwim,
      ),
      dailyTreatments: const [],
      discontinuedTreatments: const [],
      emergencyTreatments: const [],
      allergies: const <AllergyData>[],
      medicalDevices: const [],
      contacts: const [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    );
  }

  ActivityProfileData buildActivityProfile({
    required bool requiresAdaptations,
  }) {
    return ActivityProfileData(
      aquaticActivity: AquaticActivityData(
        requiresAdaptations: requiresAdaptations,
      ),
      transport: TransportData(),
      walkingEffort: WalkingEffortData(),
      overnightStay: OvernightStayData(),
      clothing: ClothingData(),
      toilets: ToiletsData(),
      communication: CommunicationData(),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    );
  }

  setUp(() {
    ChildRepository.instance.clearForTesting();
  });

  test(
    'Une seule recommandation "ne sait pas nager", pas de doublon, '
    'même quand le profil activité coche "adaptations nécessaires"',
    () {
      const childId = 'water-dup-test-1';

      ChildRepository.instance.seedForTesting(
        buildChild(
          childId: childId,
          requiresAdaptations: true,
        ),
      );
      ChildRepository.instance.seedActivityProfileForTesting(
        childId: childId,
        activityProfile: buildActivityProfile(
          requiresAdaptations: true,
        ),
      );

      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test',
          hasWaterNearby: true,
          childrenWillEnterWater: true,
        ),
        childIds: const [childId],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final childResult = result.childResults.first;

      final cannotSwimRecommendations =
          childResult.recommendations.where(
        (recommendation) => recommendation.text.contains(
          'ne sait pas nager',
        ),
      );

      expect(
        cannotSwimRecommendations,
        hasLength(1),
        reason:
            'Le fait que l\'enfant ne sache pas nager ne doit apparaître '
            'qu\'une seule fois, pas une fois par règle.',
      );
    },
  );

  test(
    '"Ne sait pas nager" apparaît même si "adaptations nécessaires" '
    'n\'est pas coché sur le profil activité',
    () {
      const childId = 'water-dup-test-2';

      ChildRepository.instance.seedForTesting(
        buildChild(
          childId: childId,
          requiresAdaptations: false,
        ),
      );
      ChildRepository.instance.seedActivityProfileForTesting(
        childId: childId,
        activityProfile: buildActivityProfile(
          requiresAdaptations: false,
        ),
      );

      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test',
          hasWaterNearby: true,
          childrenWillEnterWater: true,
        ),
        childIds: const [childId],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final childResult = result.childResults.first;

      expect(
        childResult.recommendations.any(
          (recommendation) => recommendation.text.contains(
            'ne sait pas nager',
          ),
        ),
        isTrue,
        reason:
            'Le fait que l\'enfant ne sache pas nager vient du profil '
            'santé : ça ne doit jamais dépendre d\'une case cochée (ou '
            'pas) dans un profil activité séparé.',
      );
    },
  );
}
