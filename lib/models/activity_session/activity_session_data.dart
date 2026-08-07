import 'activity_answer.dart';

enum ActivityTransportType {
  car,
  bus,
  train,
  tram,
  metro,
  plane,
  boatOrFerry,
  other,
}

class ActivitySessionData {
  String? activityName;
  DateTime? date;
  String? location;

  final List<String> selectedChildIds;

  bool? hasWaterNearby;
  bool? childrenWillEnterWater;
  bool? swimmingSupervisedByLifeguard;

  bool? hasProlongedWalking;
  bool? hasSignificantPhysicalEffort;

  bool? hasTransport;
  final Set<ActivityTransportType> transportTypes;

  bool? hasOvernightStay;
  bool? collectiveAccommodation;
  ActivityThreeStateAnswer? electricityMayBeUnavailable;
  ActivityThreeStateAnswer? phoneNetworkMayBeUnavailable;

  bool? hasFallRisk;
  bool? hasAnimalContact;

  bool? hasLoudEnvironment;
  bool? hasLargeCrowd;
  bool? hasConfinedSpace;

  bool? hasClothingChange;

  ActivitySessionData({
    this.activityName,
    this.date,
    this.location,
    List<String>? selectedChildIds,
    this.hasWaterNearby,
    this.childrenWillEnterWater,
    this.swimmingSupervisedByLifeguard,
    this.hasProlongedWalking,
    this.hasSignificantPhysicalEffort,
    this.hasTransport,
    Set<ActivityTransportType>? transportTypes,
    this.hasOvernightStay,
    this.collectiveAccommodation,
    this.electricityMayBeUnavailable,
    this.phoneNetworkMayBeUnavailable,
    this.hasFallRisk,
    this.hasAnimalContact,
    this.hasLoudEnvironment,
    this.hasLargeCrowd,
    this.hasConfinedSpace,
    this.hasClothingChange,
  })  : selectedChildIds = selectedChildIds ?? [],
        transportTypes = transportTypes ?? {};
}