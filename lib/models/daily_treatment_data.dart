class DailyTreatmentData {
  String? medicationName;
  String? dosage;
  String? administrationTimes;

  final List<String> relatedPathologyIds;

  DailyTreatmentData({
    this.medicationName,
    this.dosage,
    this.administrationTimes,
    List<String>? relatedPathologyIds,
  }) : relatedPathologyIds =
            relatedPathologyIds ?? [];
}