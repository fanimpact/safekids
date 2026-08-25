import '../utils/date_format_utils.dart';

/// Une note écrite par un membre d'établissement sur un enfant, telle
/// que son PARENT la voit.
///
/// Distincte de `NoteActiviteData`, qui est la note vue côté
/// professionnel : celle-ci porte le contexte (activité, établissement,
/// qualité de l'auteur) et ne porte pas ce que le parent n'a pas à voir
/// — ni l'identifiant de l'auteur, ni son adresse email.
///
/// Tout vient de `notes_enfant_pour_parent`, une fonction
/// `security definer` : c'est elle, et non le RLS, qui décide de ce qui
/// sort. Voir `supabase/schema_notes_visibles_parent.sql`.
class NoteEnfantData {
  final String id;
  final String note;
  final DateTime creeLe;

  /// Nuls quand l'établissement ou l'activité ont été supprimés depuis.
  /// La note, elle, reste : elle a été écrite, le parent doit pouvoir
  /// la lire.
  final String? nomActivite;
  final DateTime? dateActivite;
  final String? nomEtablissement;

  /// `directeur`, `adjoint`, `membre` — ou nul si l'auteur n'est plus
  /// membre de l'établissement.
  final String? roleAuteur;

  const NoteEnfantData({
    required this.id,
    required this.note,
    required this.creeLe,
    this.nomActivite,
    this.dateActivite,
    this.nomEtablissement,
    this.roleAuteur,
  });

  factory NoteEnfantData.fromRow(Map<String, dynamic> row) {
    final dateActivite = row['date_activite'] as String?;

    return NoteEnfantData(
      id: row['id'] as String,
      note: row['note'] as String,
      creeLe: DateTime.parse(row['cree_le'] as String).toLocal(),
      nomActivite: row['nom_activite'] as String?,
      dateActivite: dateActivite == null
          ? null
          : DateTime.parse(dateActivite).toLocal(),
      nomEtablissement: row['nom_etablissement'] as String?,
      roleAuteur: row['role_auteur'] as String?,
    );
  }
}

/// Qui a écrit, sans dire qui.
///
/// Décision du 25/08/2026 : le parent voit la QUALITÉ de l'auteur, pas
/// son adresse email — la seule identité qu'un professionnel possède en
/// base, et que le parent n'a jamais eu à voir ailleurs dans
/// l'application. Il sait à qui s'adresser sans qu'aucune adresse
/// personnelle ne sorte ; il reprend contact par l'établissement.
///
/// Aucune de ces formulations n'accorde en genre : rien dans la base ne
/// dit celui de l'auteur, et deviner serait pire que ne rien dire.
String libelleAuteurNote(String? roleAuteur) {
  switch (roleAuteur) {
    case 'directeur':
      return 'Écrit par la direction de l’établissement';
    case 'adjoint':
      return 'Écrit par la direction adjointe';
    case 'membre':
      return 'Écrit par un membre de l’équipe';
    default:
      // L'auteur n'est plus membre : sa qualité au moment où il a écrit
      // n'est plus lisible. On ne l'invente pas.
      return 'Écrit par l’établissement';
  }
}

/// L'en-tête d'une note : où et quand cela s'est passé.
///
/// L'établissement passe avant l'activité — c'est ce que le parent
/// reconnaît en premier. La date affichée est celle de l'ACTIVITÉ quand
/// elle existe, pas celle de la note : le parent cherche le jour où son
/// enfant était là-bas, pas le moment où quelqu'un s'est assis pour
/// écrire.
String libelleContexteNote(NoteEnfantData note) {
  final etablissement = note.nomEtablissement ?? 'Établissement';
  final activite = note.nomActivite?.trim();
  final date = note.dateActivite ?? note.creeLe;

  final debut = '$etablissement — ${formatShortDate(date)}';

  if (activite == null || activite.isEmpty) {
    return debut;
  }

  return '$debut · $activite';
}
