import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/demo/demo_children.dart';
import 'package:safekids/models/activity_session/activity_answer.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
import 'package:safekids/models/activity_session/complete_activity_session_data.dart';
import 'package:safekids/recommendation_engine/recommendation_engine.dart';

void main() {
  DemoChildren.load();

  test(
    'Le moteur génère les recommandations de Théo et Noé',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test complet du moteur',
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
          hasOvernightStay: false,
          collectiveAccommodation: false,
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
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      expect(
        result.childResults.length,
        2,
      );

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final noeResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-noe',
      );

      final theoTexts = theoResult.recommendations
          .map((recommendation) => recommendation.text)
          .join('\n');

      final noeTexts = noeResult.recommendations
          .map((recommendation) => recommendation.text)
          .join('\n');

      expect(
        theoTexts,
        contains('Buccolam'),
      );

      expect(
        theoTexts,
        isNot(
          contains(
            'Médicament test mal des transports',
          ),
        ),
      );

      expect(
        noeTexts,
        contains('Desloratadine'),
      );

      expect(
        noeTexts,
        contains('Solupred'),
      );

      for (final childResult in result.childResults) {
        final ids = childResult.recommendations
            .map((recommendation) => recommendation.id)
            .toList();

        expect(
          ids.toSet().length,
          ids.length,
        );
      }
    },
  );

  test(
    'Eau - baignade de Théo avec maître-nageur',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test baignade',
          hasWaterNearby: true,
          childrenWillEnterWater: true,
          swimmingSupervisedByLifeguard: true,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      final texts = theoResult.recommendations
          .map((recommendation) => recommendation.text)
          .toSet();

      expect(
        ids,
        contains('water_dedicated_adult'),
      );

      expect(
        ids,
        isNot(
          contains('water_adapted_supervision'),
        ),
      );

      expect(
        ids,
        contains('water_notify_lifeguard'),
      );

      expect(
        ids,
        contains('water_special_swimming_equipment'),
      );

      expect(
        texts,
        contains(
          'Bouchons d’oreilles et bonnet de bain',
        ),
      );
    },
  );

  test(
    'Eau - sans maître-nageur on ne demande pas de le prévenir',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test baignade sans maître-nageur',
          hasWaterNearby: true,
          childrenWillEnterWater: true,
          swimmingSupervisedByLifeguard: false,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('water_dedicated_adult'),
      );

      expect(
        ids,
        isNot(
          contains('water_adapted_supervision'),
        ),
      );

      expect(
        ids,
        isNot(
          contains('water_notify_lifeguard'),
        ),
      );
    },
  );

  test(
    'Eau - aucune recommandation eau sans contexte eau',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test sans eau',
          hasWaterNearby: false,
          childrenWillEnterWater: false,
          swimmingSupervisedByLifeguard: false,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final waterRecommendations =
          theoResult.recommendations.where(
        (recommendation) =>
            recommendation.id.startsWith('water_'),
      );

      expect(
        waterRecommendations,
        isEmpty,
      );
    },
  );

  test(
    'Effort - Théo nécessite une vigilance pour effort intense',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test effort intense',
          hasProlongedWalking: false,
          hasSignificantPhysicalEffort: true,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains(
          'intense_physical_effort_vigilance',
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'prolonged_walking_vigilance',
          ),
        ),
      );
    },
  );

  test(
    'Marche - marche prolongée seule ne déclenche pas la vigilance effort de Théo',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test marche prolongée',
          hasProlongedWalking: true,
          hasSignificantPhysicalEffort: false,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        isNot(
          contains(
            'prolonged_walking_vigilance',
          ),
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'intense_physical_effort_vigilance',
          ),
        ),
      );
    },
  );

  test(
    'Marche et effort - Noé ne reçoit aucune de ces vigilances',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test marche et effort Noé',
          hasProlongedWalking: true,
          hasSignificantPhysicalEffort: true,
        ),
        childIds: const [
          'demo-noe',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final noeResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-noe',
      );

      final ids = noeResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        isNot(
          contains(
            'prolonged_walking_vigilance',
          ),
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'intense_physical_effort_vigilance',
          ),
        ),
      );
    },
  );

  test(
    'Transport - voiture déclenche le mal des transports de Théo sans médicament renseigné',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test voiture',
          hasTransport: true,
          transportTypes: {
            ActivityTransportType.car,
          },
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains(
          'transport_motion_sickness_car',
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'transport_motion_sickness_medication_car',
          ),
        ),
      );
    },
  );

  test(
    'Transport - train ne déclenche pas le mal des transports de Théo',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test train',
          hasTransport: true,
          transportTypes: {
            ActivityTransportType.train,
          },
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        isNot(
          contains(
            'transport_motion_sickness_car',
          ),
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'transport_motion_sickness_medication_car',
          ),
        ),
      );
    },
  );

  test(
    'Transport - aucun transport ne déclenche aucune règle transport',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test sans transport',
          hasTransport: false,
          transportTypes: {
            ActivityTransportType.car,
          },
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final transportRecommendations =
          theoResult.recommendations.where(
        (recommendation) =>
            recommendation.id.startsWith('transport_'),
      );

      expect(
        transportRecommendations,
        isEmpty,
      );
    },
  );

  test(
    'Transport - Noé ne reçoit pas de recommandation mal des transports',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test voiture Noé',
          hasTransport: true,
          transportTypes: {
            ActivityTransportType.car,
          },
        ),
        childIds: const [
          'demo-noe',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final noeResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-noe',
      );

      final motionSicknessRecommendations =
          noeResult.recommendations.where(
        (recommendation) =>
            recommendation.id.startsWith(
          'transport_motion_sickness',
        ),
      );

      expect(
        motionSicknessRecommendations,
        isEmpty,
      );
    },
  );

  test(
    'Nuitée - Théo doit emporter sa machine',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test nuitée Théo',
          hasOvernightStay: true,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.no,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      final texts = theoResult.recommendations
          .map((recommendation) => recommendation.text)
          .toSet();

      expect(
        ids,
        contains('overnight_night_device'),
      );

      expect(
        texts,
        contains(
          'Machine pour l’apnée du sommeil',
        ),
      );

      expect(
        ids,
        isNot(
          contains('overnight_backup_power'),
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'overnight_power_failure_critical',
          ),
        ),
      );
    },
  );

  test(
    'Nuitée - coupure électrique possible déclenche secours et criticité pour Théo',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test électricité Théo',
          hasOvernightStay: true,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.yes,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('overnight_night_device'),
      );

      expect(
        ids,
        contains('overnight_backup_power'),
      );

      expect(
        ids,
        contains(
          'overnight_power_failure_critical',
        ),
      );
    },
  );

  test(
    'Nuitée - électricité inconnue est traitée comme un risque pour Théo',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName:
              'Test électricité inconnue Théo',
          hasOvernightStay: true,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.unknown,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final ids = theoResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      expect(
        ids,
        contains('overnight_backup_power'),
      );

      expect(
        ids,
        contains(
          'overnight_power_failure_critical',
        ),
      );
    },
  );

  test(
    'Nuitée - Noé emporte sa machine sans alimentation de secours imposée',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test nuitée Noé',
          hasOvernightStay: true,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.yes,
        ),
        childIds: const [
          'demo-noe',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final noeResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-noe',
      );

      final ids = noeResult.recommendations
          .map((recommendation) => recommendation.id)
          .toSet();

      final texts = noeResult.recommendations
          .map((recommendation) => recommendation.text)
          .toSet();

      expect(
        ids,
        contains('overnight_night_device'),
      );

      expect(
        texts,
        contains(
          'Machine pour l’apnée du sommeil',
        ),
      );

      expect(
        ids,
        isNot(
          contains('overnight_backup_power'),
        ),
      );

      expect(
        ids,
        isNot(
          contains(
            'overnight_power_failure_critical',
          ),
        ),
      );
    },
  );

  test(
    'Nuitée - aucune recommandation nuitée si activité sans nuit',
    () {
      final activity = CompleteActivitySessionData(
        activity: ActivitySessionData(
          activityName: 'Test sans nuitée',
          hasOvernightStay: false,
          electricityMayBeUnavailable:
              ActivityThreeStateAnswer.yes,
        ),
        childIds: const [
          'demo-theo',
        ],
      );

      final result =
          RecommendationEngine().generateRecommendations(activity);

      final theoResult = result.childResults.firstWhere(
        (childResult) => childResult.childId == 'demo-theo',
      );

      final overnightRecommendations =
          theoResult.recommendations.where(
        (recommendation) =>
            recommendation.id.startsWith(
          'overnight_',
        ),
      );

      expect(
        overnightRecommendations,
        isEmpty,
      );
    },
  );
}