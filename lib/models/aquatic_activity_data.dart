class AquaticActivityData {
  bool requiresAdaptations;

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