class WalkingEffortData {
  bool prolongedWalkingRequiresVigilance;
  bool intensePhysicalEffortRequiresVigilance;

  WalkingEffortData({
    this.prolongedWalkingRequiresVigilance = false,
    this.intensePhysicalEffortRequiresVigilance = false,
  });

  Map<String, dynamic> toJson() => {
        'prolongedWalkingRequiresVigilance':
            prolongedWalkingRequiresVigilance,
        'intensePhysicalEffortRequiresVigilance':
            intensePhysicalEffortRequiresVigilance,
      };

  factory WalkingEffortData.fromJson(
    Map<String, dynamic> json,
  ) {
    return WalkingEffortData(
      prolongedWalkingRequiresVigilance:
          json['prolongedWalkingRequiresVigilance']
                  as bool? ??
              false,
      intensePhysicalEffortRequiresVigilance:
          json['intensePhysicalEffortRequiresVigilance']
                  as bool? ??
              false,
    );
  }
}