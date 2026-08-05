class TransportData {
  bool requiresAdaptations;

  bool motionSickness;

  bool requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool requiresSpecialAttention;
  String? specialAttentionDetails;

  TransportData({
    this.requiresAdaptations = false,
    this.motionSickness = false,
    this.requiresSpecialEquipment = false,
    this.specialEquipmentDetails,
    this.requiresSpecialAttention = false,
    this.specialAttentionDetails,
  });
}