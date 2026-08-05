class TransitionsData {
  bool requiresAdaptations;

  bool transitionsMayCauseStress;

  bool changesMustBeAnnounced;

  TransitionsData({
    this.requiresAdaptations = false,
    this.transitionsMayCauseStress = false,
    this.changesMustBeAnnounced = false,
  });
}