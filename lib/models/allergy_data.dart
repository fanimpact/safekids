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

  /// Étapes à suivre en cas d'urgence liée à cette allergie,
  /// dans l'ordre, saisies par le parent. Affichées numérotées
  /// automatiquement dans le Mode Urgence.
  final List<String> emergencyInstructionSteps;

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
    List<String>? emergencyInstructionSteps,
  })  : allergyId =
            allergyId ?? _createAllergyId(),
        emergencyInstructionSteps =
            emergencyInstructionSteps ?? [];

  static String _createAllergyId() {
    _nextId++;
    return 'allergy_$_nextId';
  }
}