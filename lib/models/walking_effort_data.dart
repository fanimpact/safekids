class WalkingEffortData {
  bool? prolongedWalkingRequiresVigilance;
  bool? intensePhysicalEffortRequiresVigilance;

  WalkingEffortData({
    this.prolongedWalkingRequiresVigilance,
    this.intensePhysicalEffortRequiresVigilance,
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
              as bool?,
      intensePhysicalEffortRequiresVigilance:
          json['intensePhysicalEffortRequiresVigilance']
              as bool?,
    );
  }
}
