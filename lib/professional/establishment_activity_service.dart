import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_session/activity_session_codec.dart';
import '../models/activity_session/activity_session_data.dart';
import '../models/activity_session/complete_activity_session_data.dart';
import '../models/activity_session/note_activite_data.dart';

/// Regroupe les opérations Supabase pour la préparation d'activité
/// côté établissement : sauvegarde/liste des activités partagées à
/// toute l'école, masquage individuel des recommandations non
/// critiques, et notes rattachées à une activité (voir plan espace
/// professionnel, section 11).
class EstablishmentActivityService {
  EstablishmentActivityService._();

  static final EstablishmentActivityService instance =
      EstablishmentActivityService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Clé utilisée pour le masquage individuel — encode l'enfant
  /// concerné (ou "global" pour une recommandation d'activité, non
  /// liée à un enfant précis) et l'identifiant de la recommandation.
  static String maskKey({
    String? enfantId,
    required String recommandationId,
  }) {
    return '${enfantId ?? 'global'}:$recommandationId';
  }

  Future<CompleteActivitySessionData> saveActivity(
    ActivitySessionData activity, {
    required List<String> childIds,
    required String etablissementId,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError(
        'Aucun utilisateur connecté.',
      );
    }

    final row = await _client
        .from('activites_preparees')
        .insert({
          'cree_par': userId,
          'etablissement_id': etablissementId,
          'nom_activite': activity.activityName,
          'date_activite':
              activity.date?.toUtc().toIso8601String(),
          'lieu': activity.location,
          'description':
              ActivitySessionCodec.descriptionToJson(
            activity,
          ),
          'enfants_ids': childIds,
          'modifie_par': userId,
        })
        .select()
        .single();

    return ActivitySessionCodec.completeFromRow(row);
  }

  /// Change les enfants concernés par une activité déjà générée —
  /// utile quand un enfant rejoint ou quitte la sortie après coup
  /// (Fanny, 19/08/2026). Ne touche pas à la description de
  /// l'activité elle-même.
  Future<CompleteActivitySessionData> updateChildren({
    required String activiteId,
    required List<String> childIds,
  }) async {
    final userId = _client.auth.currentUser?.id;

    final row = await _client
        .from('activites_preparees')
        .update({
          'enfants_ids': childIds,
          'modifie_par': userId,
          'modifie_le':
              DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', activiteId)
        .select()
        .single();

    return ActivitySessionCodec.completeFromRow(row);
  }

  /// Change les caractéristiques d'une activité déjà générée (eau,
  /// transport, nuitée...) — pour corriger une réponse sans repasser
  /// par tout le parcours de préparation. Ne touche pas aux enfants
  /// concernés.
  Future<CompleteActivitySessionData> updateDescription({
    required String activiteId,
    required ActivitySessionData activity,
  }) async {
    final userId = _client.auth.currentUser?.id;

    final row = await _client
        .from('activites_preparees')
        .update({
          'nom_activite': activity.activityName,
          'date_activite':
              activity.date?.toUtc().toIso8601String(),
          'lieu': activity.location,
          'description':
              ActivitySessionCodec.descriptionToJson(
            activity,
          ),
          'modifie_par': userId,
          'modifie_le':
              DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', activiteId)
        .select()
        .single();

    return ActivitySessionCodec.completeFromRow(row);
  }

  Future<List<CompleteActivitySessionData>> listActivities(
    String etablissementId,
  ) async {
    final rows = await _client
        .from('activites_preparees')
        .select()
        .eq('etablissement_id', etablissementId)
        .order('cree_le', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ActivitySessionCodec.completeFromRow)
        .toList();
  }

  Future<Set<String>> loadMaskedKeys(
    String activiteId,
  ) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return {};
    }

    final rows = await _client
        .from('activites_recommandations_masquees')
        .select('cle_recommandation')
        .eq('activite_id', activiteId)
        .eq('user_id', userId);

    return (rows as List<dynamic>)
        .map(
          (row) =>
              row['cle_recommandation'] as String,
        )
        .toSet();
  }

  Future<void> toggleMask({
    required String activiteId,
    required String cle,
    required bool masquer,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return;
    }

    if (masquer) {
      await _client
          .from('activites_recommandations_masquees')
          .upsert(
            {
              'user_id': userId,
              'activite_id': activiteId,
              'cle_recommandation': cle,
            },
            onConflict: 'user_id,activite_id,cle_recommandation',
          );
    } else {
      await _client
          .from('activites_recommandations_masquees')
          .delete()
          .eq('user_id', userId)
          .eq('activite_id', activiteId)
          .eq('cle_recommandation', cle);
    }
  }

  /// Enregistre la note puis, si elle est rattachée à un enfant,
  /// déclenche la notification par email au parent — jamais pour une
  /// note générale au groupe (`enfantId` null), qui n'est envoyée à
  /// personne.
  Future<void> saveNote({
    required String activiteId,
    required String texte,
    String? enfantId,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError(
        'Aucun utilisateur connecté.',
      );
    }

    await _client.from('notes_activite').insert({
      'activite_id': activiteId,
      'auteur_id': userId,
      'enfant_id': enfantId,
      'note': texte,
    });

    if (enfantId == null) {
      return;
    }

    try {
      await _client.functions.invoke(
        'notifier-note-ajoutee',
        body: {
          'enfantId': enfantId,
          'activiteId': activiteId,
        },
      );
    } catch (_) {
      // La note est déjà enregistrée : un échec d'envoi de la
      // notification ne doit pas faire échouer la sauvegarde côté
      // utilisateur, qui n'a aucune action à refaire pour ça.
    }
  }

  Future<List<NoteActiviteData>> notesForActivite(
    String activiteId,
  ) async {
    final rows = await _client
        .from('notes_activite')
        .select()
        .eq('activite_id', activiteId)
        .order('cree_le', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(NoteActiviteData.fromRow)
        .toList();
  }
}
