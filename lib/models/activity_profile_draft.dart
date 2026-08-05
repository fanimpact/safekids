import 'activity_profile_data.dart';
import 'aquatic_activity_data.dart';
import 'clothing_data.dart';
import 'communication_data.dart';
import 'overnight_stay_data.dart';
import 'safety_data.dart';
import 'toilets_data.dart';
import 'transitions_data.dart';
import 'transport_data.dart';
import 'walking_effort_data.dart';

class ActivityProfileDraft {
  String? userId;
  String? childId;

  final AquaticActivityData aquaticActivity =
      AquaticActivityData();

  final TransportData transport =
      TransportData();

  final WalkingEffortData walkingEffort =
      WalkingEffortData();

  final OvernightStayData overnightStay =
      OvernightStayData();

  final ClothingData clothing =
      ClothingData();

  final ToiletsData toilets =
      ToiletsData();

  final CommunicationData communication =
      CommunicationData();

  final TransitionsData transitions =
      TransitionsData();

  final SafetyData safety =
      SafetyData();

  ActivityProfileData toProfile() {
    return ActivityProfileData(
      aquaticActivity: aquaticActivity,
      transport: transport,
      walkingEffort: walkingEffort,
      overnightStay: overnightStay,
      clothing: clothing,
      toilets: toilets,
      communication: communication,
      transitions: transitions,
      safety: safety,
    );
  }
}