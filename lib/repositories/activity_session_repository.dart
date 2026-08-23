import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_provider.dart';
import '../usage/compteur_usage.dart';
import '../models/activity_session/activity_session_codec.dart';
import '../models/activity_session/activity_session_data.dart';
import '../models/activity_session/complete_activity_session_data.dart';

/// Sauvegarde/liste les activités préparées par le parent connecté
/// (table `activites_preparees`, `parent_id = auth.uid()`) — les
/// recommandations elles-mêmes ne sont jamais stockées, seule la
/// description de la sortie l'est ; elles sont recalculées à chaque
/// ouverture à partir du profil le plus à jour de chaque enfant.
class ActivitySessionRepository {
  ActivitySessionRepository._();

  static final ActivitySessionRepository instance =
      ActivitySessionRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<CompleteActivitySessionData> saveActivity(
    ActivitySessionData activity, {
    List<String> childIds = const [],
  }) async {
    final userId = SupabaseAuthProvider.instance.currentUserId;

    if (userId == null) {
      throw StateError(
        'Aucun utilisateur connecté.',
      );
    }

    compteurUsage.marquer(FonctionnaliteUsage.activitePreparee);

    final row = await _client
        .from('activites_preparees')
        .insert({
          'cree_par': userId,
          'parent_id': userId,
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

  Future<List<CompleteActivitySessionData>>
      listActivities() async {
    final userId = SupabaseAuthProvider.instance.currentUserId;

    if (userId == null) {
      return [];
    }

    final rows = await _client
        .from('activites_preparees')
        .select()
        .eq('parent_id', userId)
        .order('cree_le', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ActivitySessionCodec.completeFromRow)
        .toList();
  }
}
