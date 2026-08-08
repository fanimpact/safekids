class SafetyData {
  bool requiresAdaptations;

  bool mayLeaveGroupSuddenly;

  bool requiresSafetyEquipment;
  String? safetyEquipmentDetails;

  SafetyData({
    this.requiresAdaptations = false,
    this.mayLeaveGroupSuddenly = false,
    this.requiresSafetyEquipment = false,
    this.safetyEquipmentDetails,
  });
}