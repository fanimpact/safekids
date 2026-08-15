class ContactData {
  String? fullName;
  String? relationship;
  String? phoneNumber;
  bool isPrimaryContact;

  ContactData({
    this.fullName,
    this.relationship,
    this.phoneNumber,
    this.isPrimaryContact = false,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'relationship': relationship,
        'phoneNumber': phoneNumber,
        'isPrimaryContact': isPrimaryContact,
      };

  factory ContactData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ContactData(
      fullName: json['fullName'] as String?,
      relationship: json['relationship'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isPrimaryContact:
          json['isPrimaryContact'] as bool? ?? false,
    );
  }
}