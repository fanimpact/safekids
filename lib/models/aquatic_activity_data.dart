class AquaticActivityData {
  bool requiresAdaptations;

  // À proximité d'un point d'eau
  bool mayJumpIntoWater;
  bool canSwim;
  bool requiresFlotationVestNearWater;
  bool requiresDedicatedAdultNearWater;

  // Baignade
  bool requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool requiresAdaptedSupervision;
  bool notifyLifeguard;
  bool requiresDedicatedAdult;
  String? otherSupervisionDetails;

  bool requiresOtherAdaptation;
  String? otherAdaptationDetails;

  AquaticActivityData({
    this.requiresAdaptations = false,
    this.mayJumpIntoWater = false,
    this.canSwim = false,
    this.requiresFlotationVestNearWater = false,
    this.requiresDedicatedAdultNearWater = false,
    this.requiresSpecialEquipment = false,
    this.specialEquipmentDetails,
    this.requiresAdaptedSupervision = false,
    this.notifyLifeguard = false,
    this.requiresDedicatedAdult = false,
    this.otherSupervisionDetails,
    this.requiresOtherAdaptation = false,
    this.otherAdaptationDetails,
  });
}