import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class TransitionsRules {
  const TransitionsRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final transitions = child.activityProfile?.transitions;

    if (childId == null || transitions == null) {
      return recommendations;
    }

    if (transitions.transitionsMayCauseStress) {
      recommendations.add(
        Recommendation(
          id: 'transitions_may_cause_stress',
          category: RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Les transitions peuvent provoquer du stress chez l’enfant.',
        ),
      );
    }

    if (transitions.changesMustBeAnnounced) {
      recommendations.add(
        Recommendation(
          id: 'transitions_announce_changes',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text: 'Annoncer les changements à l’avance.',
        ),
      );
    }

    return recommendations;
  }
}