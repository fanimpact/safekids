class OvernightStayData {
  bool requiresAdaptations;

  bool usesNightDevice;

  /// Référence les `MedicalDeviceData.deviceId` du profil santé déjà
  /// déclarés — pas de nouvelle saisie du nom de l'appareil ici, pour
  /// éviter que le même appareil soit décrit à deux endroits.
  Set<String> nightDeviceIds;

  bool requiresElectricity;

  bool powerFailureIsCritical;

  bool requiresNightSupervision;
  String? nightSupervisionDetails;

  OvernightStayData({
    this.requiresAdaptations = false,
    this.usesNightDevice = false,
    Set<String>? nightDeviceIds,
    this.requiresElectricity = false,
    this.powerFailureIsCritical = false,
    this.requiresNightSupervision = false,
    this.nightSupervisionDetails,
  }) : nightDeviceIds = nightDeviceIds ?? <String>{};

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'usesNightDevice': usesNightDevice,
        'nightDeviceIds': nightDeviceIds.toList(),
        'requiresElectricity': requiresElectricity,
        'powerFailureIsCritical': powerFailureIsCritical,
        'requiresNightSupervision':
            requiresNightSupervision,
        'nightSupervisionDetails':
            nightSupervisionDetails,
      };

  factory OvernightStayData.fromJson(
    Map<String, dynamic> json,
  ) {
    return OvernightStayData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool? ??
              false,
      usesNightDevice:
          json['usesNightDevice'] as bool? ?? false,
      nightDeviceIds: (json['nightDeviceIds']
                  as List<dynamic>?)
              ?.map((id) => id as String)
              .toSet() ??
          {},
      requiresElectricity:
          json['requiresElectricity'] as bool? ??
              false,
      powerFailureIsCritical:
          json['powerFailureIsCritical'] as bool? ??
              false,
      requiresNightSupervision:
          json['requiresNightSupervision'] as bool? ??
              false,
      nightSupervisionDetails:
          json['nightSupervisionDetails'] as String?,
    );
  }
}
