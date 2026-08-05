class CommunicationData {
  bool requiresAdaptations;

  bool useSimpleInstructions;

  bool mayAppearToUnderstand;

  bool verifyUnderstandingIndividually;

  bool usesCommunicationSupport;
  String? communicationSupportDetails;

  CommunicationData({
    this.requiresAdaptations = false,
    this.useSimpleInstructions = false,
    this.mayAppearToUnderstand = false,
    this.verifyUnderstandingIndividually = false,
    this.usesCommunicationSupport = false,
    this.communicationSupportDetails,
  });
}