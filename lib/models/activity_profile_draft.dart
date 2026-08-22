import 'activity_profile_data.dart';
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

class ActivityProfileDraft {
  String? userId;
  String? childId;

  AquaticActivityData aquaticActivity;
  TransportData transport;
  WalkingEffortData walkingEffort;
  OvernightStayData overnightStay;
  ClothingData clothing;
  ToiletsData toilets;
  CommunicationData communication;
  TransitionsData transitions;
  SafetyData safety;
  OtherInformationData otherInformation;
  MealsData meals;

  ActivityProfileDraft({
    this.userId,
    this.childId,
    AquaticActivityData? aquaticActivity,
    TransportData? transport,
    WalkingEffortData? walkingEffort,
    OvernightStayData? overnightStay,
    ClothingData? clothing,
    ToiletsData? toilets,
    CommunicationData? communication,
    TransitionsData? transitions,
    SafetyData? safety,
    OtherInformationData? otherInformation,
    MealsData? meals,
  })  : aquaticActivity =
            aquaticActivity ?? AquaticActivityData(),
        transport = transport ?? TransportData(),
        walkingEffort =
            walkingEffort ?? WalkingEffortData(),
        overnightStay =
            overnightStay ?? OvernightStayData(),
        clothing = clothing ?? ClothingData(),
        toilets = toilets ?? ToiletsData(),
        communication =
            communication ?? CommunicationData(),
        transitions = transitions ?? TransitionsData(),
        safety = safety ?? SafetyData(),
        otherInformation =
            otherInformation ?? OtherInformationData(),
        meals = meals ?? MealsData();

  /// Pré-remplit un brouillon à partir d'un profil Activités déjà
  /// enregistré (modification), avec des copies indépendantes de
  /// chaque section — pour ne pas modifier le profil déjà enregistré
  /// tant que l'utilisateur n'a pas terminé et validé.
  factory ActivityProfileDraft.fromActivityProfileData(
    ActivityProfileData data, {
    String? userId,
    String? childId,
  }) {
    return ActivityProfileDraft(
      userId: userId,
      childId: childId,
      aquaticActivity: AquaticActivityData.fromJson(
        data.aquaticActivity.toJson(),
      ),
      transport: TransportData.fromJson(
        data.transport.toJson(),
      ),
      walkingEffort: WalkingEffortData.fromJson(
        data.walkingEffort.toJson(),
      ),
      overnightStay: OvernightStayData.fromJson(
        data.overnightStay.toJson(),
      ),
      clothing: ClothingData.fromJson(
        data.clothing.toJson(),
      ),
      toilets: ToiletsData.fromJson(
        data.toilets.toJson(),
      ),
      communication: CommunicationData.fromJson(
        data.communication.toJson(),
      ),
      transitions: TransitionsData.fromJson(
        data.transitions.toJson(),
      ),
      safety: SafetyData.fromJson(
        data.safety.toJson(),
      ),
      otherInformation: OtherInformationData.fromJson(
        data.otherInformation.toJson(),
      ),
      meals: MealsData.fromJson(
        data.meals.toJson(),
      ),
    );
  }

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
      otherInformation: otherInformation,
      meals: meals,
    );
  }
}
