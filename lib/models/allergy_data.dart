class AllergyData {
  static int _nextId = 0;

  final String allergyId;

  String? allergen;

  String? observedReaction;

  /// Étapes à suivre en cas d'urgence liée à cette allergie,
  /// dans l'ordre, saisies par le parent. Affichées numérotées
  /// automatiquement dans le Mode Urgence.
  final List<String> emergencyInstructionSteps;

  AllergyData({
    String? allergyId,
    this.allergen,
    this.observedReaction,
    List<String>? emergencyInstructionSteps,
  })  : allergyId =
            allergyId ?? _createAllergyId(),
        emergencyInstructionSteps =
            emergencyInstructionSteps ?? [];

  static String _createAllergyId() {
    _nextId++;
    return 'allergy_$_nextId';
  }

  Map<String, dynamic> toJson() => {
        'allergyId': allergyId,
        'allergen': allergen,
        'observedReaction': observedReaction,
        'emergencyInstructionSteps':
            emergencyInstructionSteps,
      };

  factory AllergyData.fromJson(
    Map<String, dynamic> json,
  ) {
    return AllergyData(
      allergyId: json['allergyId'] as String?,
      allergen: json['allergen'] as String?,
      observedReaction:
          json['observedReaction'] as String?,
      emergencyInstructionSteps:
          (json['emergencyInstructionSteps']
                  as List<dynamic>?)
              ?.map((step) => step as String)
              .toList(),
    );
  }
}
