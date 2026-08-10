import '../../models/activity_session/activity_answer.dart';
import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class OvernightStayRules {
  const OvernightStayRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final overnightStay = child.activityProfile?.overnightStay;

    if (childId == null || overnightStay == null) {
      return recommendations;
    }

    if (activity.hasOvernightStay != true) {
      return recommendations;
    }

    // Appareil utilisé pendant la nuit.
    if (overnightStay.usesNightDevice) {
      final deviceDetails =
          overnightStay.nightDeviceDetails?.trim();

      if (deviceDetails != null &&
          deviceDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'overnight_night_device',
            category: RecommendationCategory.equipment,
            childId: childId,
            text: deviceDetails,
          ),
        );
      }
    }

    // Surveillance nocturne éventuelle.
    if (overnightStay.requiresNightSupervision) {
      final supervisionDetails =
          overnightStay.nightSupervisionDetails?.trim();

      recommendations.add(
        Recommendation(
          id: 'overnight_night_supervision',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text: supervisionDetails != null &&
                  supervisionDetails.isNotEmpty
              ? supervisionDetails
              : 'Prévoir une surveillance nocturne.',
        ),
      );
    }

    final electricityMayBeUnavailable =
        activity.electricityMayBeUnavailable;

    final electricityIsUncertainOrUnavailable =
        electricityMayBeUnavailable ==
                ActivityThreeStateAnswer.yes ||
            electricityMayBeUnavailable ==
                ActivityThreeStateAnswer.unknown;

    // Une alimentation de secours n'est recommandée
    // que si la coupure est indiquée comme critique
    // pour cet enfant.
    if (overnightStay.requiresElectricity &&
        overnightStay.powerFailureIsCritical &&
        electricityIsUncertainOrUnavailable) {
      recommendations.add(
        Recommendation(
          id: 'overnight_backup_power',
          category: RecommendationCategory.adaptation,
          childId: childId,
          text:
              'Prévoir une solution d’alimentation électrique de secours.',
        ),
      );

      recommendations.add(
        Recommendation(
          id: 'overnight_power_failure_critical',
          category:
              RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'Une coupure de courant nécessite une vigilance particulière pour cet enfant.',
        ),
      );
    }

    return recommendations;
  }
}