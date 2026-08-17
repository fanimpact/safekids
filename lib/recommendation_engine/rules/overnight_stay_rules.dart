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
    final overnightStay =
        child.activityProfile?.overnightStay;

    if (childId == null || overnightStay == null) {
      return recommendations;
    }

    if (activity.hasOvernightStay != true) {
      return recommendations;
    }

    // Appareil utilisé pendant la nuit : le nom vient du dispositif
    // médical déjà déclaré dans le profil santé (une seule source),
    // jamais ressaisi ici.
    if (overnightStay.usesNightDevice == true &&
        overnightStay.nightDeviceIds.isNotEmpty) {
      final deviceNames = child
          .essentialInformation
          .medicalDevices
          .where(
            (device) => overnightStay.nightDeviceIds
                .contains(device.deviceId),
          )
          .map((device) => device.deviceName?.trim())
          .where(
            (name) => name != null && name.isNotEmpty,
          )
          .cast<String>()
          .toList();

      if (deviceNames.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'overnight_night_device',
            category:
                RecommendationCategory.equipment,
            childId: childId,
            text: deviceNames.join(' et '),
          ),
        );
      }
    }

    // Surveillance nocturne :
    // on reprend uniquement la précision
    // réellement renseignée par le parent.
    if (overnightStay.requiresNightSupervision == true) {
      final supervisionDetails =
          overnightStay
              .nightSupervisionDetails
              ?.trim();

      if (supervisionDetails != null &&
          supervisionDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'overnight_night_supervision',
            category:
                RecommendationCategory.adaptation,
            childId: childId,
            text: supervisionDetails,
          ),
        );
      }
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
    if (overnightStay.requiresElectricity == true &&
        overnightStay.powerFailureIsCritical == true &&
        electricityIsUncertainOrUnavailable) {
      recommendations.add(
        Recommendation(
          id: 'overnight_backup_power',
          category:
              RecommendationCategory.adaptation,
          childId: childId,
          text:
              'Prévoir une solution d’alimentation électrique de secours.',
        ),
      );

      recommendations.add(
        Recommendation(
          id: 'overnight_power_failure_critical',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'L’appareil utilisé la nuit nécessite une alimentation électrique.',
        ),
      );
    }

    return recommendations;
  }
}