class IdentityData {
  String? lastName;
  String? firstName;
  DateTime? dateOfBirth;
  double? heightCm;
  double? weightKg;

  /// Date à laquelle la taille et le poids ont été mesurés (les deux
  /// ensemble), pour que l'accompagnant sache si ces valeurs sont
  /// récentes avant de s'y fier (ex. dosage basé sur le poids).
  DateTime? measurementsUpdatedAt;

  bool? hasDiagnosedPathologies;

  IdentityData({
    this.lastName,
    this.firstName,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.measurementsUpdatedAt,
    this.hasDiagnosedPathologies,
  });
}
