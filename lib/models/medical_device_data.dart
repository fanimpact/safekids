class MedicalDeviceData {
  static int _nextId = 0;

  final String deviceId;

  String? deviceName;
  String? mainUse;

  /// true : porté ou implanté en permanence sur l'enfant (ex. pacemaker).
  /// false : à emporter/préparer pour chaque sortie (ex. machine à apnée).
  /// null : non renseigné.
  bool? isWornOrImplantedPermanently;

  MedicalDeviceData({
    String? deviceId,
    this.deviceName,
    this.mainUse,
    this.isWornOrImplantedPermanently,
  }) : deviceId = deviceId ?? _createDeviceId();

  static String _createDeviceId() {
    _nextId++;
    return 'device_$_nextId';
  }
}
