import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class WalkingEffortRules {
  const WalkingEffortRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final walkingEffort =
        child.activityProfile?.walkingEffort;

    if (childId == null || walkingEffort == null) {
      return recommendations;
    }

    if (activity.hasProlongedWalking == true &&
        walkingEffort
            .prolongedWalkingRequiresVigilance) {
      recommendations.add(
        Recommendation(
          id: 'prolonged_walking_vigilance',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'Marche prolongée : vigilance particulière.',
        ),
      );
    }

    if (activity.hasSignificantPhysicalEffort ==
            true &&
        walkingEffort
            .intensePhysicalEffortRequiresVigilance) {
      recommendations.add(
        Recommendation(
          id:
              'intense_physical_effort_vigilance',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'Effort physique intense : vigilance particulière.',
        ),
      );
    }

    return recommendations;
  }
}