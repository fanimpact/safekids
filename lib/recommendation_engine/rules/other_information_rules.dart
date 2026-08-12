import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class OtherInformationRules {
  const OtherInformationRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final otherInformation =
        child.activityProfile?.otherInformation;

    if (childId == null ||
        otherInformation == null) {
      return recommendations;
    }

    if (!otherInformation.hasOtherInformation) {
      return recommendations;
    }

    final details =
        otherInformation.details?.trim();

    if (details != null &&
        details.isNotEmpty) {
      recommendations.add(
        Recommendation(
          id: 'other_information_1',
          category:
              RecommendationCategory.additionalInformation,
          childId: childId,
          text: details,
        ),
      );
    }

    final secondDetails =
        otherInformation.secondDetails?.trim();

    if (secondDetails != null &&
        secondDetails.isNotEmpty) {
      recommendations.add(
        Recommendation(
          id: 'other_information_2',
          category:
              RecommendationCategory.additionalInformation,
          childId: childId,
          text: secondDetails,
        ),
      );
    }

    return recommendations;
  }
}