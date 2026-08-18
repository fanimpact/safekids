import '../../models/complete_child_profile_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

/// Rappelle chaque dispositif médical à emporter, indépendamment de
/// tout usage nocturne. Corrigé (19/08/2026) : la seule règle qui
/// lisait `medicalDevices` jusqu'ici était celle de la nuitée
/// (`OvernightStayRules`), qui ne s'applique que si l'activité inclut
/// une nuitée ET que le dispositif est explicitement lié à un usage
/// nocturne — un dispositif utilisé seulement le jour ne générait
/// jamais aucun rappel, quelle que soit l'activité. Un dispositif
/// porté ou implanté en permanence (`isWornOrImplantedPermanently ==
/// true`) est déjà sur l'enfant : il n'y a rien à "emporter", donc
/// pas de rappel pour lui.
class MedicalDeviceReminderRules {
  const MedicalDeviceReminderRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;

    if (childId == null) {
      return recommendations;
    }

    for (final device
        in child.essentialInformation.medicalDevices) {
      if (device.isWornOrImplantedPermanently == true) {
        continue;
      }

      final name = device.deviceName?.trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      final use = device.mainUse?.trim();

      recommendations.add(
        Recommendation(
          id: 'medical_device_reminder_${device.deviceId}',
          category: RecommendationCategory.rememberToTake,
          childId: childId,
          text: use != null && use.isNotEmpty
              ? '$name — $use'
              : name,
        ),
      );
    }

    return recommendations;
  }
}
