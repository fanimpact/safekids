class OtherInformationData {
  // Corrigé (19/08/2026) : était un bool non nullable, défaut false,
  // ce qui présélectionnait "Non" — même défaut déjà corrigé ailleurs
  // dans l'app le 16/08 (voir clothing_page/toilets_page), jamais
  // appliqué à cette dernière page du questionnaire jusqu'ici.
  bool? hasOtherInformation;

  String? details;
  String? secondDetails;
  String? thirdDetails;
  String? fourthDetails;

  OtherInformationData({
    this.hasOtherInformation,
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
          json['hasOtherInformation'] as bool?,
      details: json['details'] as String?,
      secondDetails: json['secondDetails'] as String?,
      thirdDetails: json['thirdDetails'] as String?,
      fourthDetails: json['fourthDetails'] as String?,
    );
  }
}