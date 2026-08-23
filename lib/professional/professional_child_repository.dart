import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_provider.dart';
import '../models/complete_child_profile_data.dart';
import '../repositories/child_profile_codec.dart';

/// Trombinoscope d'un établissement, en lecture seule (le personnel ne
/// modifie jamais la fiche d'un enfant — seuls les parents le font).
/// Même principe de copie locale persistante que `ChildRepository`
/// côté parent, mais avec deux garde-fous propres à l'usage
/// professionnel : un enfant révoqué/expiré disparaît dès le prochain
/// contact réussi avec le serveur (la synchronisation remplace
/// entièrement la liste), et la copie locale n'est plus jamais
/// utilisée au-delà de 7 jours sans synchronisation réussie — sans
/// cette limite, une personne dont l'accès a été révoqué garderait
/// indéfiniment des données de santé d'enfants sur son téléphone.
class ProfessionalChildRepository extends ChangeNotifier {
  ProfessionalChildRepository._();

  static final ProfessionalChildRepository instance =
      ProfessionalChildRepository._();

  static const _cacheKey = 'kidsrelay_pro_cached_children';
  static const _cacheSyncedAtKey =
      'kidsrelay_pro_cache_synced_at';

  static const _maxOfflineAge = Duration(days: 7);

  final List<CompleteChildProfileData> _children = [];

  String? _etablissementId;
  bool _isOffline = false;
  DateTime? _lastSyncAt;

  SupabaseClient get _client => Supabase.instance.client;

  List<CompleteChildProfileData> get children =>
      List.unmodifiable(_children);

  bool get isOffline => _isOffline;

  DateTime? get lastSyncAt => _lastSyncAt;

  CompleteChildProfileData? findByChildId(String childId) {
    for (final child in _children) {
      if (child.childId == childId) {
        return child;
      }
    }

    return null;
  }

  Future<void> loadFromSupabase(
    String etablissementId,
  ) async {
    _etablissementId = etablissementId;

    final rows = await _client
        .from('enfants_etablissements')
        .select('enfant_id, enfants(*)')
        .eq('etablissement_id', etablissementId)
        .eq('statut', 'actif');

    final loaded = <CompleteChildProfileData>[];

    for (final row in rows) {
      final enfant = row['enfants'] as Map<String, dynamic>?;

      if (enfant == null) {
        // La ligne "enfants" correspondante n'est plus lisible (accès
        // retiré entre-temps, ou incohérence passagère) : on ne
        // l'affiche simplement pas, plutôt que de planter.
        continue;
      }

      final childId = enfant['id'] as String;

      final sante = await _client
          .from('profils_sante')
          .select()
          .eq('enfant_id', childId)
          .maybeSingle();

      final activites = await _client
          .from('profils_activites')
          .select()
          .eq('enfant_id', childId)
          .maybeSingle();

      loaded.add(
        CompleteChildProfileData(
          essentialInformation:
              ChildProfileCodec.childProfileFromRows(
            childId: childId,
            enfant: enfant,
            sante: sante,
          ),
          activityProfile:
              ChildProfileCodec.activityProfileFromRow(
            activites,
          ),
          activityProfileCompleted: activites != null,
        ),
      );
    }

    // Remplacement complet, jamais une fusion : un enfant révoqué ou
    // expiré depuis la dernière synchronisation disparaît ici
    // automatiquement, sans logique de purge séparée à maintenir.
    _children
      ..clear()
      ..addAll(loaded);

    await _saveToLocalCache(etablissementId);
  }

  /// Recharge la dernière copie locale connue, uniquement si elle a
  /// moins de 7 jours — sinon, refuse et force une reconnexion plutôt
  /// que d'afficher des données potentiellement périmées (accès
  /// révoqué entre-temps sans que l'appareil ait pu le savoir).
  Future<bool> loadFromLocalCacheIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();

    final syncedAtRaw = prefs.getString(_cacheSyncedAtKey);
    final syncedAt = syncedAtRaw == null
        ? null
        : DateTime.tryParse(syncedAtRaw);

    if (syncedAt == null ||
        DateTime.now().difference(syncedAt) >
            _maxOfflineAge) {
      return false;
    }

    final raw = prefs.getString(_cacheKey);

    if (raw == null) {
      return false;
    }

    try {
      final items = jsonDecode(raw) as List<dynamic>;

      final loaded = items
          .map(
            (item) => _childFromCacheJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      _children
        ..clear()
        ..addAll(loaded);

      _etablissementId =
          prefs.getString('${_cacheKey}_etablissement_id');
      _lastSyncAt = syncedAt;
      _isOffline = true;

      notifyListeners();

      return true;
    } catch (error) {
      debugPrint(
        'Impossible de lire la copie locale du '
        'trombinoscope professionnel : $error',
      );

      return false;
    }
  }

  /// Enregistre une consultation dans le journal de traçabilité —
  /// échec silencieux : ne doit jamais empêcher la consultation
  /// elle-même de s'afficher.
  Future<void> logConsultation({
    required String enfantId,
    required String typeFiche,
  }) async {
    final userId = SupabaseAuthProvider.instance.currentUserId;
    final etablissementId = _etablissementId;

    if (userId == null || etablissementId == null) {
      return;
    }

    try {
      await _client.from('journal_consultations_fiche').insert({
        'user_id': userId,
        'enfant_id': enfantId,
        'etablissement_id': etablissementId,
        'type_fiche': typeFiche,
      });
    } catch (error) {
      debugPrint(
        'Impossible d’enregistrer la consultation dans le '
        'journal : $error',
      );
    }
  }

  /// Vide entièrement la copie locale — à appeler à la déconnexion du
  /// compte professionnel, pour ne jamais laisser de données de santé
  /// d'enfants sur l'appareil au-delà de la session active.
  Future<void> clearLocalData() async {
    _children.clear();
    _etablissementId = null;
    _lastSyncAt = null;
    _isOffline = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheSyncedAtKey);
    await prefs.remove('${_cacheKey}_etablissement_id');

    notifyListeners();
  }

  Future<void> _saveToLocalCache(
    String etablissementId,
  ) async {
    _isOffline = false;
    _lastSyncAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();

    final items =
        _children.map(_childToCacheJson).toList();

    await prefs.setString(_cacheKey, jsonEncode(items));
    await prefs.setString(
      _cacheSyncedAtKey,
      _lastSyncAt!.toIso8601String(),
    );
    await prefs.setString(
      '${_cacheKey}_etablissement_id',
      etablissementId,
    );

    notifyListeners();
  }

  Map<String, dynamic> _childToCacheJson(
    CompleteChildProfileData child,
  ) {
    final essential = child.essentialInformation;
    final childId = essential.childId ?? '';
    final activityProfile = child.activityProfile;

    return {
      'enfant': ChildProfileCodec.enfantRow(essential, ''),
      'sante': ChildProfileCodec.santeRow(childId, essential),
      'activites': activityProfile == null
          ? null
          : ChildProfileCodec.activitesRow(
              childId,
              activityProfile,
            ),
      'activityProfileCompleted':
          child.activityProfileCompleted,
    };
  }

  CompleteChildProfileData _childFromCacheJson(
    Map<String, dynamic> json,
  ) {
    final enfant = Map<String, dynamic>.from(
      json['enfant'] as Map,
    );
    final childId = enfant['id'] as String;

    final sante = json['sante'] == null
        ? null
        : Map<String, dynamic>.from(json['sante'] as Map);

    final activites = json['activites'] == null
        ? null
        : Map<String, dynamic>.from(
            json['activites'] as Map,
          );

    return CompleteChildProfileData(
      essentialInformation:
          ChildProfileCodec.childProfileFromRows(
        childId: childId,
        enfant: enfant,
        sante: sante,
      ),
      activityProfile:
          ChildProfileCodec.activityProfileFromRow(
        activites,
      ),
      activityProfileCompleted:
          json['activityProfileCompleted'] as bool? ??
              (activites != null),
    );
  }
}
