class EmergencyTreatmentData {
  String? medicationName;
  String? administrationCondition;
  String? dosage;
  String? administrationMethod;

  final List<String> relatedPathologyIds;
  final List<String> relatedAllergyIds;

  /// À quelle étape (index, 0-based) du protocole d'urgence de chaque
  /// pathologie/allergie ce traitement est administré — choisi
  /// explicitement par le parent sur la page des traitements, jamais
  /// deviné depuis le texte des étapes. Une pathologie/allergie absente
  /// de la carte n'a pas encore d'étape choisie (voir Mode Urgence :
  /// `resolveAdministrationStepIndex`, qui gère alors un repli).
  final Map<String, int> administrationStepByPathologyId;
  final Map<String, int> administrationStepByAllergyId;

  EmergencyTreatmentData({
    this.medicationName,
    this.administrationCondition,
    this.dosage,
    this.administrationMethod,
    List<String>? relatedPathologyIds,
    List<String>? relatedAllergyIds,
    Map<String, int>? administrationStepByPathologyId,
    Map<String, int>? administrationStepByAllergyId,
  })  : relatedPathologyIds =
            relatedPathologyIds ?? [],
        relatedAllergyIds =
            relatedAllergyIds ?? [],
        administrationStepByPathologyId =
            administrationStepByPathologyId ?? {},
        administrationStepByAllergyId =
            administrationStepByAllergyId ?? {};

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'administrationCondition':
            administrationCondition,
        'dosage': dosage,
        'administrationMethod': administrationMethod,
        'relatedPathologyIds': relatedPathologyIds,
        'relatedAllergyIds': relatedAllergyIds,
        'administrationStepByPathologyId':
            administrationStepByPathologyId,
        'administrationStepByAllergyId':
            administrationStepByAllergyId,
      };

  factory EmergencyTreatmentData.fromJson(
    Map<String, dynamic> json,
  ) {
    Map<String, int> stepMapFromJson(dynamic raw) {
      if (raw is! Map) {
        return {};
      }

      final result = <String, int>{};

      for (final entry in raw.entries) {
        final value = entry.value;

        if (value is int) {
          result[entry.key as String] = value;
        } else if (value is num) {
          result[entry.key as String] = value.toInt();
        }
      }

      return result;
    }

    return EmergencyTreatmentData(
      medicationName: json['medicationName'] as String?,
      administrationCondition:
          json['administrationCondition'] as String?,
      dosage: json['dosage'] as String?,
      administrationMethod:
          json['administrationMethod'] as String?,
      relatedPathologyIds:
          (json['relatedPathologyIds']
                  as List<dynamic>?)
              ?.map((id) => id as String)
              .toList(),
      relatedAllergyIds:
          (json['relatedAllergyIds']
                  as List<dynamic>?)
              ?.map((id) => id as String)
              .toList(),
      administrationStepByPathologyId: stepMapFromJson(
        json['administrationStepByPathologyId'],
      ),
      administrationStepByAllergyId: stepMapFromJson(
        json['administrationStepByAllergyId'],
      ),
    );
  }
}
