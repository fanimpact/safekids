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

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'mayLeaveGroupSuddenly': mayLeaveGroupSuddenly,
        'requiresSafetyEquipment':
            requiresSafetyEquipment,
        'safetyEquipmentDetails':
            safetyEquipmentDetails,
      };

  factory SafetyData.fromJson(
    Map<String, dynamic> json,
  ) {
    return SafetyData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool? ??
              false,
      mayLeaveGroupSuddenly:
          json['mayLeaveGroupSuddenly'] as bool? ??
              false,
      requiresSafetyEquipment:
          json['requiresSafetyEquipment'] as bool? ??
              false,
      safetyEquipmentDetails:
          json['safetyEquipmentDetails'] as String?,
    );
  }
}