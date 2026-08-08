import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/demo/demo_children.dart';
import 'package:safekids/models/activity_session/activity_session_data.dart';
import 'package:safekids/models/activity_session/complete_activity_session_data.dart';
import 'package:safekids/recommendation_engine/recommendation_engine.dart';

void main() {
  test(
    'Le moteur génère les recommandations de Théo et Noé',
    () {
      DemoChildren.load();

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

      final engine = RecommendationEngine();

      final result =
          engine.generateRecommendations(activity);

      expect(
        result.childResults.length,
        2,
      );

      final theoResult = result.childResults.firstWhere(
        (childResult) =>
            childResult.childId == 'demo-theo',
      );

      final noeResult = result.childResults.firstWhere(
        (childResult) =>
            childResult.childId == 'demo-noe',
      );

      final theoTexts = theoResult.recommendations
          .map((recommendation) => recommendation.text)
          .join('\n');

      final noeTexts = noeResult.recommendations
          .map((recommendation) => recommendation.text)
          .join('\n');

      // Théo : médicament d'urgence.
      expect(
        theoTexts,
        contains('Buccolam'),
      );

      // Théo : mal des transports en voiture.
      expect(
        theoTexts,
        contains(
          'Médicament test mal des transports',
        ),
      );

      // Noé : ses deux médicaments d'urgence.
      expect(
        noeTexts,
        contains('Desloratadine'),
      );

      expect(
        noeTexts,
        contains('Solupred'),
      );

      // Vérification de la déduplication.
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
}