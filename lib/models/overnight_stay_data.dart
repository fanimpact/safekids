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
}
