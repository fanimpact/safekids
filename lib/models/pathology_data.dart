import 'medical_professional_data.dart';

class PathologyData {
  static int _nextId = 0;

  final String pathologyId;

  String? name;

  /// Date ou période approximative
  String? approximateDiagnosisDate;

  bool hasReferringProfessional;

  MedicalProfessionalData? referringProfessional;

  PathologyData({
    String? pathologyId,
    this.name,
    this.approximateDiagnosisDate,
    this.hasReferringProfessional = false,
    this.referringProfessional,
  }) : pathologyId =
            pathologyId ?? _createPathologyId();

  static String _createPathologyId() {
    _nextId++;
    return 'pathology_$_nextId';
  }
}