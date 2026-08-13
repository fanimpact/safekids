import 'medical_professional_data.dart';

class PathologyData {
  static int _nextId = 0;

  final String pathologyId;

  String? name;

  /// Date ou période approximative
  String? approximateDiagnosisDate;

  bool hasReferringProfessional;

  MedicalProfessionalData? referringProfessional;

  /// Étapes à suivre en cas d'urgence liée à cette pathologie,
  /// dans l'ordre, saisies par le parent. Affichées numérotées
  /// automatiquement dans le Mode Urgence.
  final List<String> emergencyInstructionSteps;

  PathologyData({
    String? pathologyId,
    this.name,
    this.approximateDiagnosisDate,
    this.hasReferringProfessional = false,
    this.referringProfessional,
    List<String>? emergencyInstructionSteps,
  })  : pathologyId =
            pathologyId ?? _createPathologyId(),
        emergencyInstructionSteps =
            emergencyInstructionSteps ?? [];

  static String _createPathologyId() {
    _nextId++;
    return 'pathology_$_nextId';
  }
}