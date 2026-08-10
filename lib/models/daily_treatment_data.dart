class DailyTreatmentData {
  String? medicationName;
  String? dosage;
  String? administrationTimes;

  final List<String> relatedPathologyIds;
  final List<String> relatedAllergyIds;

  DailyTreatmentData({
    this.medicationName,
    this.dosage,
    this.administrationTimes,
    List<String>? relatedPathologyIds,
    List<String>? relatedAllergyIds,
  })  : relatedPathologyIds =
            relatedPathologyIds ?? [],
        relatedAllergyIds =
            relatedAllergyIds ?? [];
}