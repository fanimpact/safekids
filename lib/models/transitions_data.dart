class TransitionsData {
  bool requiresAdaptations;

  bool transitionsMayCauseStress;

  bool changesMustBeAnnounced;

  TransitionsData({
    this.requiresAdaptations = false,
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
          json['requiresAdaptations'] as bool? ??
              false,
      transitionsMayCauseStress:
          json['transitionsMayCauseStress'] as bool? ??
              false,
      changesMustBeAnnounced:
          json['changesMustBeAnnounced'] as bool? ??
              false,
    );
  }
}