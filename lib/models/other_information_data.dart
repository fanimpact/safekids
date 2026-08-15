class OtherInformationData {
  bool hasOtherInformation;

  String? details;
  String? secondDetails;
  String? thirdDetails;
  String? fourthDetails;

  OtherInformationData({
    this.hasOtherInformation = false,
    this.details,
    this.secondDetails,
    this.thirdDetails,
    this.fourthDetails,
  });

  Map<String, dynamic> toJson() => {
        'hasOtherInformation': hasOtherInformation,
        'details': details,
        'secondDetails': secondDetails,
        'thirdDetails': thirdDetails,
        'fourthDetails': fourthDetails,
      };

  factory OtherInformationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return OtherInformationData(
      hasOtherInformation:
          json['hasOtherInformation'] as bool? ??
              false,
      details: json['details'] as String?,
      secondDetails: json['secondDetails'] as String?,
      thirdDetails: json['thirdDetails'] as String?,
      fourthDetails: json['fourthDetails'] as String?,
    );
  }
}