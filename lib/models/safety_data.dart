class SafetyData {
  bool? mayLeaveGroupSuddenly;

  bool? requiresSafetyEquipment;
  String? safetyEquipmentDetails;

  SafetyData({
    this.mayLeaveGroupSuddenly,
    this.requiresSafetyEquipment,
    this.safetyEquipmentDetails,
  });

  Map<String, dynamic> toJson() => {
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
      mayLeaveGroupSuddenly:
          json['mayLeaveGroupSuddenly'] as bool?,
      requiresSafetyEquipment:
          json['requiresSafetyEquipment'] as bool?,
      safetyEquipmentDetails:
          json['safetyEquipmentDetails'] as String?,
    );
  }
}
