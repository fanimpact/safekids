/// Une note rédigée par un membre du personnel sur une activité
/// préparée, avec un enfant concerné optionnel — jamais visible des
/// collègues, visible du parent de l'enfant seulement quand
/// [enfantId] est renseigné (voir `notes_activite`, RLS).
class NoteActiviteData {
  final String id;
  final String activiteId;
  final String? enfantId;
  final String note;
  final DateTime creeLe;

  const NoteActiviteData({
    required this.id,
    required this.activiteId,
    required this.note,
    required this.creeLe,
    this.enfantId,
  });

  factory NoteActiviteData.fromRow(
    Map<String, dynamic> row,
  ) {
    return NoteActiviteData(
      id: row['id'] as String,
      activiteId: row['activite_id'] as String,
      enfantId: row['enfant_id'] as String?,
      note: row['note'] as String,
      creeLe:
          DateTime.parse(row['cree_le'] as String)
              .toLocal(),
    );
  }
}
