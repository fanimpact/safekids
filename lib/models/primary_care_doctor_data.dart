class PrimaryCareDoctorData {
  String? name;
  String? workplace;
  String? phoneNumber;

  PrimaryCareDoctorData({
    this.name,
    this.workplace,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'workplace': workplace,
        'phoneNumber': phoneNumber,
      };

  factory PrimaryCareDoctorData.fromJson(
    Map<String, dynamic> json,
  ) {
    return PrimaryCareDoctorData(
      name: json['name'] as String?,
      workplace: json['workplace'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}