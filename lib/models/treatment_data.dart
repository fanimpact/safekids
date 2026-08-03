enum TreatmentType {
  regular,
  emergency,
}

class TreatmentData {
  TreatmentType type;
  String? medicationName;
  String? dosage;
  String? usualIntakeTime;

  TreatmentData({
    required this.type,
    this.medicationName,
    this.dosage,
    this.usualIntakeTime,
  });
}