import '../../models/activity_session/activity_session_data.dart';
import '../../models/complete_child_profile_data.dart';
import '../../models/transport_data.dart';
import '../models/recommendation.dart';
import '../models/recommendation_category.dart';

class TransportRules {
  const TransportRules();

  List<Recommendation> evaluate(
    CompleteChildProfileData child,
    ActivitySessionData activity,
  ) {
    final recommendations = <Recommendation>[];

    final childId = child.childId;
    final transport = child.activityProfile?.transport;

    if (childId == null || transport == null) {
      return recommendations;
    }

    if (activity.hasTransport != true) {
      return recommendations;
    }

    final matchingMotionSicknessModes =
        transport.motionSicknessTransports.where(
      (profileMode) =>
          activity.transportTypes.contains(
        _toActivityTransportType(profileMode),
      ),
    );

    for (final mode in matchingMotionSicknessModes) {
      recommendations.add(
        Recommendation(
          id: 'transport_motion_sickness_${mode.name}',
          category: RecommendationCategory.informationVigilance,
          childId: childId,
          text:
              'L’enfant a le mal des transports en ${_transportLabel(mode)}.',
        ),
      );

      if (transport.takesMotionSicknessMedication) {
        final medicationName =
            transport.motionSicknessMedicationNames[mode]?.trim();

        if (medicationName != null && medicationName.isNotEmpty) {
          recommendations.add(
            Recommendation(
              id: 'transport_motion_sickness_medication_${mode.name}',
              category: RecommendationCategory.rememberToTake,
              childId: childId,
              text: medicationName,
            ),
          );
        }
      }
    }

    if (transport.requiresSpecialEquipment) {
      final equipmentDetails =
          transport.specialEquipmentDetails?.trim();

      if (equipmentDetails != null && equipmentDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'transport_special_equipment',
            category: RecommendationCategory.equipment,
            childId: childId,
            text: equipmentDetails,
          ),
        );
      }
    }

    if (transport.requiresSpecialAttention) {
      final attentionDetails =
          transport.specialAttentionDetails?.trim();

      if (attentionDetails != null && attentionDetails.isNotEmpty) {
        recommendations.add(
          Recommendation(
            id: 'transport_special_attention',
            category: RecommendationCategory.adaptation,
            childId: childId,
            text: attentionDetails,
          ),
        );
      }
    }

    return recommendations;
  }

  ActivityTransportType _toActivityTransportType(
    TransportMode mode,
  ) {
    switch (mode) {
      case TransportMode.car:
        return ActivityTransportType.car;
      case TransportMode.bus:
        return ActivityTransportType.bus;
      case TransportMode.train:
        return ActivityTransportType.train;
      case TransportMode.tram:
        return ActivityTransportType.tram;
      case TransportMode.metro:
        return ActivityTransportType.metro;
      case TransportMode.plane:
        return ActivityTransportType.plane;
      case TransportMode.boatOrFerry:
        return ActivityTransportType.boatOrFerry;
      case TransportMode.other:
        return ActivityTransportType.other;
    }
  }

  String _transportLabel(
    TransportMode mode,
  ) {
    switch (mode) {
      case TransportMode.car:
        return 'voiture';
      case TransportMode.bus:
        return 'bus';
      case TransportMode.train:
        return 'train';
      case TransportMode.tram:
        return 'tramway';
      case TransportMode.metro:
        return 'métro';
      case TransportMode.plane:
        return 'avion';
      case TransportMode.boatOrFerry:
        return 'bateau / ferry';
      case TransportMode.other:
        return 'autre moyen de transport';
    }
  }
}