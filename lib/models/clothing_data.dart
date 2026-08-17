class ClothingData {
  bool? requiresAssistance;

  ClothingData({
    this.requiresAssistance,
  });

  Map<String, dynamic> toJson() => {
        'requiresAssistance': requiresAssistance,
      };

  factory ClothingData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClothingData(
      requiresAssistance:
          json['requiresAssistance'] as bool?,
    );
  }
}
