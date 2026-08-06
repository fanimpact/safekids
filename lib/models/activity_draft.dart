class ActivityDraft {
  String? activityName;
  DateTime? date;
  String? location;

  String? userId;
  String? childId;

  bool water;
  bool transport;
  bool prolongedWalking;
  bool significantPhysicalEffort;
  bool severalHours;
  bool overnightStay;
  bool meal;
  bool clothingChange;

  bool outdoors;
  bool flashingLights;
  bool importantNoise;
  bool importantCrowd;
  bool animals;
  bool height;

  bool prolongedWaiting;
  bool remainCalmOrStill;
  bool dangerousTools;

  bool otherCharacteristic;
  String? otherCharacteristicDetails;

  ActivityDraft({
    this.activityName,
    this.date,
    this.location,
    this.userId,
    this.childId,
    this.water = false,
    this.transport = false,
    this.prolongedWalking = false,
    this.significantPhysicalEffort = false,
    this.severalHours = false,
    this.overnightStay = false,
    this.meal = false,
    this.clothingChange = false,
    this.outdoors = false,
    this.flashingLights = false,
    this.importantNoise = false,
    this.importantCrowd = false,
    this.animals = false,
    this.height = false,
    this.prolongedWaiting = false,
    this.remainCalmOrStill = false,
    this.dangerousTools = false,
    this.otherCharacteristic = false,
    this.otherCharacteristicDetails,
  });
}