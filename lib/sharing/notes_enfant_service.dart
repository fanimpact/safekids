import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note_enfant_data.dart';

/// Côté parent : lire les notes qu'un établissement a écrites sur son
/// enfant.
///
/// Passe par la fonction `notes_enfant_pour_parent` et non par une
/// requête directe. La raison tient en une phrase : le parent a le
/// droit de lire la note, jamais l'activité ni la ligne du membre qui
/// l'a écrite — une requête directe rendrait une note sans contexte,
/// et ouvrir ces tables au parent lui rendrait au passage l'adresse
/// email du personnel. Voir
/// `supabase/schema_notes_visibles_parent.sql`.
///
/// Lecture seule, et sans écriture possible : le parent n'ajoute pas de
/// note, il en prend connaissance.
class NotesEnfantService {
  NotesEnfantService._();

  static final NotesEnfantService instance = NotesEnfantService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<NoteEnfantData>> notesForChild(String childId) async {
    final rows = await _client.rpc(
      'notes_enfant_pour_parent',
      params: {'p_enfant_id': childId},
    );

    if (rows is! List) {
      return [];
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(NoteEnfantData.fromRow)
        .toList();
  }
}
