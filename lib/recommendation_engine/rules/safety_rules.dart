import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class SafetyRules {
  const SafetyRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final safety = child.activityProfile?.safety;

    if (childId == null || safety == null) {
      return recommendations;
    }

    if (safety.mayLeaveGroupSuddenly) {
      recommendations.add(
        Recommendation(
          id: 'safety_may_leave_group_suddenly',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'L’enfant peut quitter le groupe soudainement.',
        ),
      );
    }

    if (safety.requiresSafetyEquipment == true) {
      final equipmentDetails =
          safety.safetyEquipmentDetails?.trim();

      if (equipmentDetails != null &&
          equipmentDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'safety_equipment',
            category:
                RecommendationCategory.equipment,
            childId: childId,
            text: equipmentDetails,
          ),
        );
      }
    }

    return recommendations;
  }
}