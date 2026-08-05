import 'aquatic_activity_data.dart';
import 'clothing_data.dart';
import 'communication_data.dart';
import 'overnight_stay_data.dart';
import 'safety_data.dart';
import 'toilets_data.dart';
import 'transitions_data.dart';
import 'transport_data.dart';
import 'walking_effort_data.dart';

class ActivityProfileData {
  final AquaticActivityData aquaticActivity;

  final TransportData transport;

  final WalkingEffortData walkingEffort;

  final OvernightStayData overnightStay;

  final ClothingData clothing;

  final ToiletsData toilets;

  final CommunicationData communication;

  final TransitionsData transitions;

  final SafetyData safety;

  ActivityProfileData({
    required this.aquaticActivity,
    required this.transport,
    required this.walkingEffort,
    required this.overnightStay,
    required this.clothing,
    required this.toilets,
    required this.communication,
    required this.transitions,
    required this.safety,
  });
}