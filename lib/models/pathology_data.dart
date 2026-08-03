import 'medical_professional_data.dart';

class PathologyData {
  String? name;

  /// Date ou période approximative
  String? approximateDiagnosisDate;

  bool hasReferringProfessional;

  MedicalProfessionalData? referringProfessional;

  PathologyData({
    this.name,
    this.approximateDiagnosisDate,
    this.hasReferringProfessional = false,
    this.referringProfessional,
  });
}