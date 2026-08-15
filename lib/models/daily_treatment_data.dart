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

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'dosage': dosage,
        'administrationTimes': administrationTimes,
        'relatedPathologyIds': relatedPathologyIds,
        'relatedAllergyIds': relatedAllergyIds,
      };

  factory DailyTreatmentData.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyTreatmentData(
      medicationName: json['medicationName'] as String?,
      dosage: json['dosage'] as String?,
      administrationTimes:
          json['administrationTimes'] as String?,
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