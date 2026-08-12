import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class UniversalTriggerRules {
  const UniversalTriggerRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final triggerFactors =
        child.essentialInformation.triggerFactors;

    if (childId == null) {
      return recommendations;
    }

    if (triggerFactors.flashingLights) {
      recommendations.add(
        Recommendation(
          id: 'photosensitivity',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Photosensibilité : vigilance avec les lumières, reflets et alternances ombre/lumière.',
        ),
      );
    }

    if (triggerFactors.flashingLights &&
        triggerFactors.requiresGlassesOutdoors) {
      recommendations.add(
        Recommendation(
          id: 'photosensitivity_glasses',
          category: RecommendationCategory.equipment,
          childId: childId,
          text:
              'Lunettes adaptées à la photosensibilité.',
        ),
      );
    }

    if (triggerFactors.heat) {
      recommendations.add(
        Recommendation(
          id: 'heat_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Chaleur : vigilance particulière.',
        ),
      );
    }

    if (triggerFactors.stressOrStrongEmotions) {
      recommendations.add(
        Recommendation(
          id: 'stress_strong_emotions_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Stress ou émotions fortes : vigilance particulière.',
        ),
      );
    }

    return recommendations;
  }
}