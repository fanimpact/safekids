class EmergencyTreatmentData {
  String? medicationName;
  String? administrationCondition;
  String? dosage;
  String? administrationMethod;

  final List<String> relatedPathologyIds;
  final List<String> relatedAllergyIds;

  EmergencyTreatmentData({
    this.medicationName,
    this.administrationCondition,
    this.dosage,
    this.administrationMethod,
    List<String>? relatedPathologyIds,
    List<String>? relatedAllergyIds,
  })  : relatedPathologyIds =
            relatedPathologyIds ?? [],
        relatedAllergyIds =
            relatedAllergyIds ?? [];
}