class AllergyData {
  String? allergen;

  String? observedReaction;

  bool? hasDailyTreatment;
  String? dailyTreatmentName;
  String? dailyTreatmentDosage;

  bool? hasEmergencyTreatment;
  String? emergencyTreatmentName;
  String? emergencyTreatmentDosage;

  AllergyData({
    this.allergen,
    this.observedReaction,
    this.hasDailyTreatment,
    this.dailyTreatmentName,
    this.dailyTreatmentDosage,
    this.hasEmergencyTreatment,
    this.emergencyTreatmentName,
    this.emergencyTreatmentDosage,
  });
}