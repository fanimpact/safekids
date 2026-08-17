class ToiletsData {
  bool? requiresAssistance;

  ToiletsData({
    this.requiresAssistance,
  });

  Map<String, dynamic> toJson() => {
        'requiresAssistance': requiresAssistance,
      };

  factory ToiletsData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ToiletsData(
      requiresAssistance:
          json['requiresAssistance'] as bool?,
    );
  }
}
