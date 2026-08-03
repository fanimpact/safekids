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
}