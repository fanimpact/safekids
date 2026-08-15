class MedicalProfessionalData {
  String? name;
  String? specialty;
  String? workplace;
  String? phoneNumber;

  MedicalProfessionalData({
    this.name,
    this.specialty,
    this.workplace,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'specialty': specialty,
        'workplace': workplace,
        'phoneNumber': phoneNumber,
      };

  factory MedicalProfessionalData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalProfessionalData(
      name: json['name'] as String?,
      specialty: json['specialty'] as String?,
      workplace: json['workplace'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}