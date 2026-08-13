class MedicalObservationData {
  String? description;

  /// Date ou période approximative
  String? approximateDate;

  /// Ce qui en est ressorti (ex. "Sans conséquence identifiée").
  String? conclusion;

  MedicalObservationData({
    this.description,
    this.approximateDate,
    this.conclusion,
  });
}
