class TransitionsData {
  /// Question filtre de la section : si "Non" (ou pas encore répondu),
  /// les questions détaillées ne sont pas affichées.
  bool? requiresAdaptations;

  bool transitionsMayCauseStress;

  bool changesMustBeAnnounced;

  TransitionsData({
    this.requiresAdaptations,
    this.transitionsMayCauseStress = false,
    this.changesMustBeAnnounced = false,
  });

  Map<String, dynamic> toJson() => {
        'requiresAdaptations': requiresAdaptations,
        'transitionsMayCauseStress':
            transitionsMayCauseStress,
        'changesMustBeAnnounced':
            changesMustBeAnnounced,
      };

  factory TransitionsData.fromJson(
    Map<String, dynamic> json,
  ) {
    return TransitionsData(
      requiresAdaptations:
          json['requiresAdaptations'] as bool?,
      transitionsMayCauseStress:
          json['transitionsMayCauseStress'] as bool? ??
              false,
      changesMustBeAnnounced:
          json['changesMustBeAnnounced'] as bool? ??
              false,
    );
  }
}
