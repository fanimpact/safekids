class AquaticActivityData {
  bool requiresAdaptations;

  // À proximité d'un point d'eau
  bool? requiresFlotationVestNearWater;
  bool? requiresDedicatedAdultNearWater;

  // Baignade
  bool? requiresSpecialEquipment;
  String? specialEquipmentDetails;

  bool? requiresAdaptedSupervision;
  bool notifyLifeguard;
  bool requiresDedicatedAdult;
  String? otherSupervisionDetails;

  bool? requiresOtherAdaptation;
  String? otherAdaptationDetails;

  AquaticActivityData({
    this.requiresAdaptations = false,
    this.requiresFlotationVestNearWater,
    this.requiresDedicatedAdultNearWater,
    this.requiresSpecialEquipment,
    this.specialEquipmentDetails,
    this.requiresAdaptedSupervision,
    this.notifyLifeguard = false,
    this.requiresDedicatedAdult = false,
    this.otherSupervisionDetails,
    this.requiresOtherAdaptation,
    this.otherAdaptationDetails,
  });

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'requiresFlotationVestNearWater':
            requiresFlotationVestNearWater,
        'requiresDedicatedAdultNearWater':
            requiresDedicatedAdultNearWater,
        'requiresSpecialEquipment':
            requiresSpecialEquipment,
        'specialEquipmentDetails':
            specialEquipmentDetails,
        'requiresAdaptedSupervision':
            requiresAdaptedSupervision,
        'notifyLifeguard': notifyLifeguard,
        'requiresDedicatedAdult': requiresDedicatedAdult,
        'otherSupervisionDetails':
            otherSupervisionDetails,
        'requiresOtherAdaptation':
            requiresOtherAdaptation,
        'otherAdaptationDetails':
            otherAdaptationDetails,
      };

  factory AquaticActivityData.fromJson(
    Map<String, dynamic> json,
  ) {
    return AquaticActivityData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool? ??
              false,
      requiresFlotationVestNearWater:
          json['requiresFlotationVestNearWater']
              as bool?,
      requiresDedicatedAdultNearWater:
          json['requiresDedicatedAdultNearWater']
              as bool?,
      requiresSpecialEquipment:
          json['requiresSpecialEquipment'] as bool?,
      specialEquipmentDetails:
          json['specialEquipmentDetails'] as String?,
      requiresAdaptedSupervision:
          json['requiresAdaptedSupervision'] as bool?,
      notifyLifeguard:
          json['notifyLifeguard'] as bool? ?? false,
      requiresDedicatedAdult:
          json['requiresDedicatedAdult'] as bool? ??
              false,
      otherSupervisionDetails:
          json['otherSupervisionDetails'] as String?,
      requiresOtherAdaptation:
          json['requiresOtherAdaptation'] as bool?,
      otherAdaptationDetails:
          json['otherAdaptationDetails'] as String?,
    );
  }
}
