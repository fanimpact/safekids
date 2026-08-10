class AllergyData {
  static int _nextId = 0;

  final String allergyId;

  String? allergen;

  String? observedReaction;

  bool? hasDailyTreatment;
  String? dailyTreatmentName;
  String? dailyTreatmentDosage;

  bool? hasEmergencyTreatment;
  String? emergencyTreatmentName;
  String? emergencyTreatmentDosage;

  AllergyData({
    String? allergyId,
    this.allergen,
    this.observedReaction,
    this.hasDailyTreatment,
    this.dailyTreatmentName,
    this.dailyTreatmentDosage,
    this.hasEmergencyTreatment,
    this.emergencyTreatmentName,
    this.emergencyTreatmentDosage,
  }) : allergyId =
            allergyId ?? _createAllergyId();

  static String _createAllergyId() {
    _nextId++;
    return 'allergy_$_nextId';
  }
}