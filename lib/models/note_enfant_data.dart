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

  /// La fonction déclarée par l'auteur lui-même — « Enseignant·e »,
  /// « Restauration », ou ce qu'il a écrit sous « Autre ». Nulle tant
  /// qu'il ne l'a pas renseignée.
  ///
  /// Ce n'est pas son rôle administratif : `directeur`, `adjoint` et
  /// `membre` ne décrivent que qui gère l'équipe dans l'application, et
  /// ne disent rien de qui a écrit.
  final String? fonctionAuteur;

  const NoteEnfantData({
    required this.id,
    required this.note,
    required this.creeLe,
    this.nomActivite,
    this.dateActivite,
    this.nomEtablissement,
    this.fonctionAuteur,
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
      fonctionAuteur: row['fonction_auteur'] as String?,
    );
  }
}

/// Qui a écrit, sans dire qui.
///
/// Le parent voit la FONCTION de l'auteur, jamais son adresse email —
/// la seule identité qu'un professionnel possède en base, et qu'il n'a
/// jamais eu à voir ailleurs dans l'application. Il sait à qui
/// s'adresser sans qu'aucune adresse personnelle ne sorte ; il reprend
/// contact par l'établissement.
///
/// **Recopié tel quel, sans accord ajouté.** La personne a écrit ce
/// qu'elle est ; l'application n'ajoute ni « une », ni « (e) », ni
/// féminin de circonstance. C'est le seul moyen que la ligne soit vraie
/// pour tout le monde.
///
/// Le repli ne dure pas : une note nouvelle est impossible tant que la
/// fonction manque. Seules les notes écrites avant le 25/08/2026
/// peuvent l'afficher.
String libelleAuteurNote(String? fonctionAuteur) {
  final fonction = fonctionAuteur?.trim();

  if (fonction == null || fonction.isEmpty) {
    return 'Fonction non précisée';
  }

  return 'Écrit par : $fonction';
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
