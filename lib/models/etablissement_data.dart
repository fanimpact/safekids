class EtablissementData {
  final String id;
  final String nom;
  final String? typeEtablissement;

  const EtablissementData({
    required this.id,
    required this.nom,
    this.typeEtablissement,
  });

  factory EtablissementData.fromRow(Map<String, dynamic> row) {
    return EtablissementData(
      id: row['id'] as String,
      nom: row['nom'] as String,
      typeEtablissement: row['type_etablissement'] as String?,
    );
  }
}
