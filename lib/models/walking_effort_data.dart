class WalkingEffortData {
  bool requiresAdaptations;

  bool requiresActivityAdjustment;
  String? activityAdjustmentDetails;

  WalkingEffortData({
    this.requiresAdaptations = false,
    this.requiresActivityAdjustment = false,
    this.activityAdjustmentDetails,
  });
}