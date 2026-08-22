class MedicalEventData {
  String? description;
  String? approximateDate;

  bool? emergencyServicesCalled;

  /// Le traitement d'urgence a-t-il été donné lors de cet événement ?
  bool? emergencyTreatmentGiven;

  bool? hospitalized;
  String? hospitalName;
  String? hospitalizationDuration;

  bool? importantExaminationsPerformed;
  String? importantExaminations;

  MedicalEventData({
    this.description,
    this.approximateDate,
    this.emergencyServicesCalled,
    this.emergencyTreatmentGiven,
    this.hospitalized,
    this.hospitalName,
    this.hospitalizationDuration,
    this.importantExaminationsPerformed,
    this.importantExaminations,
  });

  /// Bloc ajouté puis laissé entièrement vide : aucun texte saisi, et
  /// aucune des quatre questions Oui/Non répondue. Retiré sans rien
  /// dire au moment de continuer, plutôt que de bloquer le parent sur
  /// un bloc qu'il n'a jamais commencé à remplir.
  ///
  /// Dès qu'un seul champ est renseigné, l'événement n'est plus vide
  /// et redevient soumis à sa validation : un antécédent médical à
  /// moitié saisi serait inexploitable par un accompagnant.
  ///
  /// Sert aussi à débloquer les profils enregistrés avant le
  /// 19/08/2026, quand la page insérait une entrée vide d'office et la
  /// sauvegardait en silence.
  bool get isEmpty {
    return (description ?? '').trim().isEmpty &&
        (approximateDate ?? '').trim().isEmpty &&
        (hospitalName ?? '').trim().isEmpty &&
        (hospitalizationDuration ?? '').trim().isEmpty &&
        (importantExaminations ?? '').trim().isEmpty &&
        emergencyServicesCalled == null &&
        emergencyTreatmentGiven == null &&
        hospitalized == null &&
        importantExaminationsPerformed == null;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'approximateDate': approximateDate,
        'emergencyServicesCalled':
            emergencyServicesCalled,
        'emergencyTreatmentGiven':
            emergencyTreatmentGiven,
        'hospitalized': hospitalized,
        'hospitalName': hospitalName,
        'hospitalizationDuration':
            hospitalizationDuration,
        'importantExaminationsPerformed':
            importantExaminationsPerformed,
        'importantExaminations':
            importantExaminations,
      };

  factory MedicalEventData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalEventData(
      description: json['description'] as String?,
      approximateDate:
          json['approximateDate'] as String?,
      emergencyServicesCalled:
          json['emergencyServicesCalled'] as bool?,
      emergencyTreatmentGiven:
          json['emergencyTreatmentGiven'] as bool?,
      hospitalized: json['hospitalized'] as bool?,
      hospitalName: json['hospitalName'] as String?,
      hospitalizationDuration:
          json['hospitalizationDuration'] as String?,
      importantExaminationsPerformed:
          json['importantExaminationsPerformed']
              as bool?,
      importantExaminations:
          json['importantExaminations'] as String?,
    );
  }
}