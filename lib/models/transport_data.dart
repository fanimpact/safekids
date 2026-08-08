enum TransportMode {
  car,
  bus,
  train,
  tram,
  metro,
  plane,
  boatOrFerry,
  other,
}

class TransportData {
  bool requiresAdaptations;

  bool motionSickness;

  Set<TransportMode> motionSicknessTransports;

  bool takesMotionSicknessMedication;

  Map<TransportMode, String> motionSicknessMedicationNames;

  bool requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool requiresSpecialAttention;
  String? specialAttentionDetails;

  TransportData({
    this.requiresAdaptations = false,
    this.motionSickness = false,
    Set<TransportMode>? motionSicknessTransports,
    this.takesMotionSicknessMedication = false,
    Map<TransportMode, String>? motionSicknessMedicationNames,
    this.requiresSpecialEquipment = false,
    this.specialEquipmentDetails,
    this.requiresSpecialAttention = false,
    this.specialAttentionDetails,
  })  : motionSicknessTransports =
            motionSicknessTransports ?? <TransportMode>{},
        motionSicknessMedicationNames =
            motionSicknessMedicationNames ?? <TransportMode, String>{};
}