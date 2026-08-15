class MedicalObservationData {
  String? description;

  /// Date ou période approximative
  String? approximateDate;

  /// Ce qui en est ressorti (ex. "Sans conséquence identifiée").
  String? conclusion;

  MedicalObservationData({
    this.description,
    this.approximateDate,
    this.conclusion,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'approximateDate': approximateDate,
        'conclusion': conclusion,
      };

  factory MedicalObservationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalObservationData(
      description: json['description'] as String?,
      approximateDate:
          json['approximateDate'] as String?,
      conclusion: json['conclusion'] as String?,
    );
  }
}
