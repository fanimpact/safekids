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

  Map<String, dynamic> toJson() => {
        'pathologyId': pathologyId,
        'name': name,
        'approximateDiagnosisDate':
            approximateDiagnosisDate,
        'hasReferringProfessional':
            hasReferringProfessional,
        'referringProfessional':
            referringProfessional?.toJson(),
        'emergencyInstructionSteps':
            emergencyInstructionSteps,
      };

  factory PathologyData.fromJson(
    Map<String, dynamic> json,
  ) {
    final referringProfessional =
        json['referringProfessional'];

    return PathologyData(
      pathologyId: json['pathologyId'] as String?,
      name: json['name'] as String?,
      approximateDiagnosisDate:
          json['approximateDiagnosisDate']
              as String?,
      hasReferringProfessional:
          json['hasReferringProfessional']
              as bool? ??
              false,
      referringProfessional:
          referringProfessional == null
              ? null
              : MedicalProfessionalData.fromJson(
                  Map<String, dynamic>.from(
                    referringProfessional as Map,
                  ),
                ),
      emergencyInstructionSteps:
          (json['emergencyInstructionSteps']
                  as List<dynamic>?)
              ?.map((step) => step as String)
              .toList(),
    );
  }
}
