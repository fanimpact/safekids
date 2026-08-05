class SafetyData {
  bool requiresAdaptations;

  bool mayLeaveGroupSuddenly;

  bool cannotSwim;

  bool waterDanger;

  bool requiresSafetyEquipment;
  String? safetyEquipmentDetails;

  SafetyData({
    this.requiresAdaptations = false,
    this.mayLeaveGroupSuddenly = false,
    this.cannotSwim = false,
    this.waterDanger = false,
    this.requiresSafetyEquipment = false,
    this.safetyEquipmentDetails,
  });
}