import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class ToiletsRules {
  const ToiletsRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final toilets = child.activityProfile?.toilets;

    if (childId == null || toilets == null) {
      return recommendations;
    }

    if (toilets.requiresAssistance) {
      recommendations.add(
        Recommendation(
          id: 'toilets_assistance',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text: 'Prévoir une assistance pour les toilettes.',
        ),
      );
    }

    return recommendations;
  }
}