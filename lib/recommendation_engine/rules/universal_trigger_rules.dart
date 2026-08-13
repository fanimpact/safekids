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

    if (triggerFactors.flashingLights == true) {
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

    if (triggerFactors.flashingLights == true &&
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

    if (triggerFactors.heat == true) {
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

    if (triggerFactors.stressOrStrongEmotions == true) {
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

    if (triggerFactors.fatigueOrLackOfSleep == true) {
      recommendations.add(
        Recommendation(
          id: 'fatigue_vigilance',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Fatigue ou manque de sommeil : vigilance particulière.',
        ),
      );
    }

    final otherTriggerFactor =
        triggerFactors.other?.trim();

    if (otherTriggerFactor != null &&
        otherTriggerFactor.isNotEmpty) {
      recommendations.add(
        Recommendation(
          id: 'other_trigger_factor',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text: otherTriggerFactor,
        ),
      );
    }

    return recommendations;
  }
}