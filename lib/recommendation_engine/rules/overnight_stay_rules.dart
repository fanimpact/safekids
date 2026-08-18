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

    // Corrigé (19/08/2026) : cette vigilance fait partie des
    // recommandations critiques (jamais masquables) — elle doit donc
    // se déclencher dès que l'appareil dépend de l'électricité, sans
    // aucune condition qui pourrait la contourner. Avant cette
    // correction, elle ne se déclenchait que si le parent avait EN
    // PLUS coché la coupure comme "critique" : un appareil dépendant
    // de l'électricité mais avec une coupure jugée "non critique" (ou
    // jamais répondue) ne générait rien du tout.
    if (overnightStay.requiresElectricity == true) {
      recommendations.add(
        Recommendation(
          id: 'overnight_power_failure_critical',
          category:
              RecommendationCategory
                  .informationVigilance,
          childId: childId,
          text:
              'L’appareil utilisé la nuit nécessite une alimentation électrique.',
          isCritical: true,
        ),
      );

      // La suggestion concrète d'une solution de secours, elle,
      // reste liée à la probabilité réelle d'une coupure pour CETTE
      // sortie précise (inutile de la suggérer si l'activité garantit
      // une alimentation stable) et au fait que le parent a signalé
      // cette coupure comme critique pour son enfant.
      if (overnightStay.powerFailureIsCritical == true &&
          electricityIsUncertainOrUnavailable) {
        recommendations.add(
          Recommendation(
            id: 'overnight_backup_power',
            category:
                RecommendationCategory.adaptation,
            childId: childId,
            text:
                'Prévoir une solution d’alimentation électrique de secours.',
            isCritical: true,
          ),
        );
      }
    }

    return recommendations;
  }
}