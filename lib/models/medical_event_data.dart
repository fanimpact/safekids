class MedicalEventData {
  String? description;
  String? approximateDate;

  bool? emergencyServicesCalled;

  /// Le traitement d'urgence a-t-il été donné lors de cet événement ?
  bool? emergencyTreatmentGiven;

  bool? hospitalized;
  String? hospitalName;
  String? hospitalizationDuration;

  bool? importantExaminationsPerformed;
  String? importantExaminations;

  MedicalEventData({
    this.description,
    this.approximateDate,
    this.emergencyServicesCalled,
    this.emergencyTreatmentGiven,
    this.hospitalized,
    this.hospitalName,
    this.hospitalizationDuration,
    this.importantExaminationsPerformed,
    this.importantExaminations,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'approximateDate': approximateDate,
        'emergencyServicesCalled':
            emergencyServicesCalled,
        'emergencyTreatmentGiven':
            emergencyTreatmentGiven,
        'hospitalized': hospitalized,
        'hospitalName': hospitalName,
        'hospitalizationDuration':
            hospitalizationDuration,
        'importantExaminationsPerformed':
            importantExaminationsPerformed,
        'importantExaminations':
            importantExaminations,
      };

  factory MedicalEventData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalEventData(
      description: json['description'] as String?,
      approximateDate:
          json['approximateDate'] as String?,
      emergencyServicesCalled:
          json['emergencyServicesCalled'] as bool?,
      emergencyTreatmentGiven:
          json['emergencyTreatmentGiven'] as bool?,
      hospitalized: json['hospitalized'] as bool?,
      hospitalName: json['hospitalName'] as String?,
      hospitalizationDuration:
          json['hospitalizationDuration'] as String?,
      importantExaminationsPerformed:
          json['importantExaminationsPerformed']
              as bool?,
      importantExaminations:
          json['importantExaminations'] as String?,
    );
  }
}