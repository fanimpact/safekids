class DiscontinuedTreatmentData {
  String? medicationName;

  /// Mois/année suffit.
  String? approximateStopDate;

  DiscontinuedTreatmentData({
    this.medicationName,
    this.approximateStopDate,
  });

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'approximateStopDate': approximateStopDate,
      };

  factory DiscontinuedTreatmentData.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiscontinuedTreatmentData(
      medicationName: json['medicationName'] as String?,
      approximateStopDate:
          json['approximateStopDate'] as String?,
    );
  }
}
