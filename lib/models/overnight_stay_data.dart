class OvernightStayData {
  bool requiresAdaptations;

  bool usesNightDevice;
  String? nightDeviceDetails;

  bool requiresElectricity;

  bool powerFailureIsCritical;

  bool requiresNightSupervision;
  String? nightSupervisionDetails;

  OvernightStayData({
    this.requiresAdaptations = false,
    this.usesNightDevice = false,
    this.nightDeviceDetails,
    this.requiresElectricity = false,
    this.powerFailureIsCritical = false,
    this.requiresNightSupervision = false,
    this.nightSupervisionDetails,
  });
}