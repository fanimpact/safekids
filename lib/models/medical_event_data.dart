class MedicalEventData {
  String? approximateDate;
  String? description;

  bool emergencyServicesCalled;
  bool hospitalized;

  String? hospitalizationDuration;
  String? importantExaminations;

  MedicalEventData({
    this.approximateDate,
    this.description,
    this.emergencyServicesCalled = false,
    this.hospitalized = false,
    this.hospitalizationDuration,
    this.importantExaminations,
  });
}