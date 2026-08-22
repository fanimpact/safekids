import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/demo/demo_children.dart';
import 'package:kidsrelay/models/activity_session/activity_answer.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/activity_session/complete_activity_session_data.dart';
import 'package:kidsrelay/recommendation_engine/recommendation_engine.dart';

void main() {
  DemoChildren.load();

  test(
    'Moteur complet - activité complexe avec Théo et Noé',
    () {
      final activitySession = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Sortie test complète',
          date: DateTime(2026, 8, 8),
          location: 'Lieu test',

          hasWaterNearby: true,
          childrenWillEnterWater: true,
          swimmingSupervisedByLifeguard: true,

          hasProlongedWalking: true,
          hasSignificantPhysicalEffort: true,

          hasTransport: true,
          transportTypes: {
            ActivityTransportType.car,
          },

          hasOvernightStay: true,
          collectiveAccommodation: true,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.yes,
          phoneNetworkMayBeUnavailable:
              ActivityThreeStateAnswer.unknown,

          hasHeightActivity: false,
          hasAnimalContact: false,

          hasLoudEnvironment: false,
          hasLargeCrowd: false,
          hasConfinedSpace: false,

          hasClothingChange: false,
        ),
        childIds: const [
          'demo-theo',
          'demo-noe',
        ],
        questionnaireCompleted: true,
        recommendationsGenerated: false,
      );

      final result = RecommendationEngine()
          .generateRecommendations(
        activitySession,
      );

      expect(
        result.childResults.length,
        2,
      );

      final theo = result.childResults.firstWhere(
        (childResult) =>
            childResult.childId == 'demo-theo',
      );

      final noe = result.childResults.firstWhere(
        (childResult) =>
            childResult.childId == 'demo-noe',
      );

      final theoIds = theo.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      final noeIds = noe.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      final globalIds = result.globalRecommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      // -------------------------
      // THÉO
      // -------------------------

      expect(
        theoIds,
        contains('photosensitivity'),
      );

      expect(
        theoIds,
        contains('photosensitivity_glasses'),
      );

      expect(
        theoIds,
        contains('heat_vigilance'),
      );

      expect(
        theoIds,
        contains(
          'stress_strong_emotions_vigilance',
        ),
      );

      expect(
        theoIds,
        contains('water_dedicated_adult'),
      );

      expect(
        theoIds,
        isNot(
          contains('water_adapted_supervision'),
        ),
      );

      expect(
        theoIds,
        contains('water_notify_lifeguard'),
      );

      expect(
        theoIds,
        contains(
          'intense_physical_effort_vigilance',
        ),
      );

      expect(
        theoIds,
        contains(
          'transport_motion_sickness_car',
        ),
      );

      expect(
        theoIds,
        isNot(
          contains(
            'transport_motion_sickness_medication_car',
          ),
        ),
      );

      expect(
        theoIds,
        contains('overnight_night_device'),
      );

      expect(
        theoIds,
        contains('overnight_backup_power'),
      );

      expect(
        theoIds,
        contains(
          'overnight_power_failure_critical',
        ),
      );

      expect(
        theoIds,
        contains('emergency_treatment_0'),
      );

      // -------------------------
      // NOÉ
      // -------------------------

      expect(
        noeIds,
        contains('overnight_night_device'),
      );

      expect(
        noeIds,
        isNot(
          contains('overnight_backup_power'),
        ),
      );

      // Corrigé (19/08/2026) : cette vigilance critique se déclenche
      // désormais dès que l'appareil dépend de l'électricité
      // (requiresElectricity == true pour Noé), même avec
      // powerFailureIsCritical à false — seule la suggestion concrète
      // de solution de secours reste conditionnée aux deux.
      expect(
        noeIds,
        contains(
          'overnight_power_failure_critical',
        ),
      );

      expect(
        noeIds,
        contains('emergency_treatment_0'),
      );

      expect(
        noeIds,
        contains('emergency_treatment_1'),
      );

      expect(
        noeIds,
        isNot(
          contains(
            'transport_motion_sickness_car',
          ),
        ),
      );

      expect(
        noeIds,
        isNot(
          contains(
            'intense_physical_effort_vigilance',
          ),
        ),
      );

      // -------------------------
      // RECOMMANDATION GLOBALE
      // -------------------------

      expect(
        globalIds,
        contains(
          'phone_network_may_be_unavailable',
        ),
      );

      expect(
        result.globalRecommendations.first.childId,
        isNull,
      );

      // -------------------------
      // DÉDUPLICATION
      // -------------------------

      for (final childResult in result.childResults) {
        final ids = childResult.recommendations
            .map((recommendation) => recommendation.id)
            .toList();

        expect(
          ids.length,
          ids.toSet().length,
        );
      }

      final globalIdList =
          result.globalRecommendations
              .map(
                (recommendation) =>
                    recommendation.id,
              )
              .toList();

      expect(
        globalIdList.length,
        globalIdList.toSet().length,
      );
    },
  );

  test(
    'Moteur complet - enfant inexistant est ignoré sans faire planter le moteur',
    () {
      final activitySession = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test enfant inexistant',
        ),
        childIds: const [
          'enfant-qui-n-existe-pas',
        ],
      );

      final result = RecommendationEngine()
          .generateRecommendations(
        activitySession,
      );

      expect(
        result.childResults,
        isEmpty,
      );
    },
  );

  test(
    'Moteur complet - recommandations globales existent même sans enfant',
    () {
      final activitySession = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test global sans enfant',
          phoneNetworkMayBeUnavailable:
              ActivityThreeStateAnswer.yes,
        ),
        childIds: const [],
      );

      final result = RecommendationEngine()
          .generateRecommendations(
        activitySession,
      );

      expect(
        result.childResults,
        isEmpty,
      );

      final globalIds = result.globalRecommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        globalIds,
        contains(
          'phone_network_may_be_unavailable',
        ),
      );
    },
  );
}