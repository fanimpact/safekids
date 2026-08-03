class MedicalEventData {
  String? description;
  String? approximateDate;

  bool? emergencyServicesCalled;

  bool? hospitalized;
  String? hospitalizationDuration;

  bool? importantExaminationsPerformed;
  String? importantExaminations;

  bool? hasOngoingConsequences;
  String? ongoingConsequences;

  MedicalEventData({
    this.description,
    this.approximateDate,
    this.emergencyServicesCalled,
    this.hospitalized,
    this.hospitalizationDuration,
    this.importantExaminationsPerformed,
    this.importantExaminations,
    this.hasOngoingConsequences,
    this.ongoingConsequences,
  });
}