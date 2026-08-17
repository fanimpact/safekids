import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class ClothingRules {
  const ClothingRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final clothing = child.activityProfile?.clothing;

    if (childId == null || clothing == null) {
      return recommendations;
    }

    if (activity.hasClothingChange == true &&
        clothing.requiresAssistance == true) {
      recommendations.add(
        Recommendation(
          id: 'clothing_change_assistance',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text: 'Assistance pour changement de tenue.',
        ),
      );
    }

    return recommendations;
  }
}
