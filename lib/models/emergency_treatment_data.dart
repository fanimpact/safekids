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

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'administrationCondition':
            administrationCondition,
        'dosage': dosage,
        'administrationMethod': administrationMethod,
        'relatedPathologyIds': relatedPathologyIds,
        'relatedAllergyIds': relatedAllergyIds,
      };

  factory EmergencyTreatmentData.fromJson(
    Map<String, dynamic> json,
  ) {
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
    );
  }
}
