class EmergencyTreatmentData {
  String? medicationName;
  String? administrationCondition;
  String? dosage;
  String? administrationMethod;

  final List<String> relatedPathologyIds;

  EmergencyTreatmentData({
    this.medicationName,
    this.administrationCondition,
    this.dosage,
    this.administrationMethod,
    List<String>? relatedPathologyIds,
  }) : relatedPathologyIds =
            relatedPathologyIds ?? [];
}