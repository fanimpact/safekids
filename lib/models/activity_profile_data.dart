import 'aquatic_activity_data.dart';
import 'clothing_data.dart';
import 'communication_data.dart';
import 'other_information_data.dart';
import 'overnight_stay_data.dart';
import 'meals_data.dart';
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

  final OtherInformationData otherInformation;

  /// Section Repas (22/08/2026). Paramètre optionnel avec valeur par
  /// défaut, contrairement aux autres sections : les profils de démo
  /// et les tests écrits avant cette section continuent de compiler
  /// sans être touchés, et se comportent comme un parent qui n'a pas
  /// encore répondu.
  final MealsData meals;

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
    required this.otherInformation,
    MealsData? meals,
  }) : meals = meals ?? MealsData();
}