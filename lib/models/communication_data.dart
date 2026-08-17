class CommunicationData {
  /// Question filtre de la section : si "Non" (ou pas encore répondu),
  /// les questions détaillées ne sont pas affichées — seuls les
  /// parents concernés par un souci de communication ont besoin d'y
  /// répondre.
  bool? requiresAdaptations;

  bool useSimpleInstructions;

  bool mayAppearToUnderstand;

  bool verifyUnderstandingIndividually;

  bool? usesCommunicationSupport;
  String? communicationSupportDetails;

  CommunicationData({
    this.requiresAdaptations,
    this.useSimpleInstructions = false,
    this.mayAppearToUnderstand = false,
    this.verifyUnderstandingIndividually = false,
    this.usesCommunicationSupport,
    this.communicationSupportDetails,
  });

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'useSimpleInstructions': useSimpleInstructions,
        'mayAppearToUnderstand': mayAppearToUnderstand,
        'verifyUnderstandingIndividually':
            verifyUnderstandingIndividually,
        'usesCommunicationSupport':
            usesCommunicationSupport,
        'communicationSupportDetails':
            communicationSupportDetails,
      };

  factory CommunicationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommunicationData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool?,
      useSimpleInstructions:
          json['useSimpleInstructions'] as bool? ??
              false,
      mayAppearToUnderstand:
          json['mayAppearToUnderstand'] as bool? ??
              false,
      verifyUnderstandingIndividually:
          json['verifyUnderstandingIndividually']
                  as bool? ??
              false,
      usesCommunicationSupport:
          json['usesCommunicationSupport'] as bool?,
      communicationSupportDetails:
          json['communicationSupportDetails']
              as String?,
    );
  }
}
