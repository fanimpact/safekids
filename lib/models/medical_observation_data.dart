class MedicalObservationData {
  String? description;

  /// Date ou période approximative
  String? approximateDate;

  /// Ce qui en est ressorti (ex. "Sans conséquence identifiée").
  String? conclusion;

  MedicalObservationData({
    this.description,
    this.approximateDate,
    this.conclusion,
  });

  /// Bloc ajouté puis laissé entièrement vide. Il est retiré sans rien
  /// dire au moment de continuer, plutôt que de bloquer le parent :
  /// une observation médicale est une information descriptive, jamais
  /// indispensable à la sécurité de l'enfant.
  ///
  /// Sert aussi à débloquer les profils enregistrés avant le
  /// 19/08/2026, quand la page insérait une entrée vide d'office et la
  /// sauvegardait en silence — rouvrir un de ces profils butait sinon
  /// sur une entrée que le parent n'avait jamais créée.
  bool get isEmpty {
    return (description ?? '').trim().isEmpty &&
        (approximateDate ?? '').trim().isEmpty &&
        (conclusion ?? '').trim().isEmpty;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'approximateDate': approximateDate,
        'conclusion': conclusion,
      };

  factory MedicalObservationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalObservationData(
      description: json['description'] as String?,
      approximateDate:
          json['approximateDate'] as String?,
      conclusion: json['conclusion'] as String?,
    );
  }
}
