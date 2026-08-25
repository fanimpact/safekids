import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_consultation_data.dart';

/// Côté parent : lire le journal des consultations de la fiche d'un
/// enfant (qui a consulté, quand) — traçabilité RGPD, corrections de
/// l'audit passe 1. Lecture seule : l'écriture reste réservée au
/// personnel qui consulte une fiche (voir
/// `ProfessionalChildRepository.logConsultation`).
class ConsultationJournalService {
  ConsultationJournalService._();

  static final ConsultationJournalService instance =
      ConsultationJournalService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<JournalConsultationData>> consultationsForChild(
    String childId,
  ) async {
    final rows = await _client
        .from('journal_consultations_fiche')
        // `etablissements(nom)` reste une jointure facultative : une
        // ouverture de lien n'a pas d'etablissement, et la ligne doit
        // quand meme remonter.
        .select('*, etablissements(nom)')
        .eq('enfant_id', childId)
        .order('consulte_le', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => JournalConsultationData.fromRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
