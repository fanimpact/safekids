import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_provider.dart';
import '../models/activity_profile_data.dart';
import '../models/child_profile_data.dart';
import '../models/complete_child_profile_data.dart';
import '../sharing/enfant_confiance_service.dart';
import 'child_profile_codec.dart';

/// Source de vérité : Supabase (tables `enfants`, `profils_sante`,
/// `profils_activites`). `_children` est un cache en mémoire, rempli une
/// fois au démarrage par [loadFromSupabase] : les lectures (`children`,
/// `findByChildId`) restent synchrones pour ne rien changer aux ~30
/// endroits de l'app qui les utilisent directement dans un `build()`.
///
/// Une copie persistante (survit à la fermeture de l'app) est écrite à
/// chaque synchronisation réussie, et sert de secours au démarrage si
/// Supabase est injoignable (pas de réseau, service indisponible) —
/// indispensable pour que le Mode Urgence et la fiche secours
/// fonctionnent hors-ligne. `ChangeNotifier` permet à l'écran d'accueil
/// de savoir quand une resynchronisation en arrière-plan a réussi.
class ChildRepository extends ChangeNotifier {
  ChildRepository._();

  static final ChildRepository instance = ChildRepository._();

  static const _cacheKey = 'kidsrelay_cached_children';
  static const _cacheSyncedAtKey =
      'kidsrelay_cache_synced_at';

  // Sur une connexion lente ou instable, une requête Supabase peut
  // rester en attente indéfiniment sans jamais réussir ni échouer —
  // l'app resterait alors bloquée (ex. indicateur de chargement qui
  // tourne sans fin) sans jamais informer l'utilisateur. Cette limite
  // force chaque écriture à échouer clairement au bout d'un moment
  // raisonnable plutôt que de rester bloquée.
  static const _writeTimeout = Duration(seconds: 15);

  final List<CompleteChildProfileData> _children = [];

  bool _isOffline = false;
  DateTime? _lastSyncAt;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  SupabaseClient get _client => Supabase.instance.client;

  List<CompleteChildProfileData> get children =>
      List.unmodifiable(_children);

  /// true si les données affichées viennent de la copie locale plutôt
  /// que d'une synchronisation Supabase réussie.
  bool get isOffline => _isOffline;

  /// Date de la dernière synchronisation Supabase réussie (celle qui a
  /// produit les données actuellement affichées, en ligne ou hors
  /// ligne).
  DateTime? get lastSyncAt => _lastSyncAt;

  CompleteChildProfileData? findByChildId(
    String childId,
  ) {
    for (final child in _children) {
      if (child.childId == childId) {
        return child;
      }
    }

    return null;
  }

  Future<void> loadFromSupabase() async {
    final parentId = SupabaseAuthProvider.instance.currentUserId;

    if (parentId == null) {
      // Ne jamais réussir silencieusement ici : si on ne sait pas qui
      // est le parent connecté (ex. session expirée et impossible à
      // rafraîchir faute de réseau), l'appelant doit passer par le
      // chemin d'échec pour se rabattre sur la copie locale au lieu
      // d'afficher une liste vide comme si tout allait bien.
      throw StateError(
        'Synchronisation impossible : aucun utilisateur '
        'Supabase connecté.',
      );
    }

    // Active toute invitation "personne de confiance" en attente pour
    // ce compte avant de charger la liste des enfants, pour qu'un
    // enfant tout juste partagé apparaisse immédiatement. Non
    // bloquant : au pire, l'invitation s'activera à la prochaine
    // synchronisation.
    try {
      await EnfantConfianceService.instance
          .activatePendingInvitations();
    } catch (_) {}

    // PIEGE. Aucun filtre ici, volontairement : c'est le RLS qui
    // decide. Or il renvoie les enfants de ce compte **et** ceux sur
    // lesquels il est personne de confiance. `children` n'est donc
    // pas "mes enfants" mais "les enfants que je peux voir".
    //
    // C'est ce qu'il faut pour l'affichage : une personne de
    // confiance doit voir la fiche sur laquelle elle a ete invitee.
    // Mais tout ecran ou toute fonction qui veut dire "mes enfants"
    // doit refiltrer sur `parent_id == currentUserId` — sinon il
    // melange deux familles. L'export RGPD du 23/08/2026 le fait
    // (voir `collecterExport` dans lib/export/source_export.dart, et
    // test/export_cloisonnement_test.dart).
    final enfantsRows = await _client
        .from('enfants')
        .select();

    final loaded = <CompleteChildProfileData>[];

    for (final enfant in enfantsRows) {
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

    _children
      ..clear()
      ..addAll(loaded);

    await _saveToLocalCache();
  }

  /// Recharge la dernière copie locale connue (écrite lors de la
  /// dernière synchronisation Supabase réussie). Utilisé au démarrage
  /// quand Supabase est injoignable, pour que l'app s'ouvre quand même
  /// avec les dernières données connues au lieu d'une liste vide —
  /// notamment pour que le Mode Urgence et la fiche secours restent
  /// utilisables sans réseau.
  Future<bool> loadFromLocalCacheIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();

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

      final syncedAtRaw =
          prefs.getString(_cacheSyncedAtKey);

      _lastSyncAt = syncedAtRaw == null
          ? null
          : DateTime.tryParse(syncedAtRaw);
      _isOffline = true;

      notifyListeners();

      return true;
    } catch (error) {
      debugPrint(
        'Impossible de lire la copie locale des '
        'enfants : $error',
      );

      return false;
    }
  }

  /// Écoute les changements de connexion réseau et retente une
  /// synchronisation Supabase dès qu'une connexion redevient
  /// disponible — sans bloquer l'utilisateur (échec silencieux, on
  /// réessaiera au prochain changement de réseau).
  void startAutoResync() {
    _connectivitySubscription ??= Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!hasConnection) {
        return;
      }

      try {
        await loadFromSupabase().timeout(
          const Duration(seconds: 10),
        );
      } catch (error) {
        debugPrint(
          'Resynchronisation Supabase toujours '
          'indisponible après reconnexion : $error',
        );
      }
    });
  }

  Future<void> addChild(
    ChildProfileData child,
  ) async {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    if (findByChildId(childId) != null) {
      return;
    }

    final parentId = _requireParentId();

    // upsert plutôt qu'insert : si un essai précédent a échoué après
    // avoir déjà créé la ligne "enfants" (coupure réseau, etc.), on
    // doit pouvoir réessayer avec les mêmes réponses sans provoquer
    // une erreur de doublon.
    await _client
        .from('enfants')
        .upsert(ChildProfileCodec.enfantRow(child, parentId))
        .timeout(_writeTimeout);
    await _client
        .from('profils_sante')
        .upsert(
          ChildProfileCodec.santeRow(childId, child),
          onConflict: 'enfant_id',
        )
        .timeout(_writeTimeout);

    _children.add(
      CompleteChildProfileData(
        essentialInformation: child,
      ),
    );

    await _saveToLocalCache();
  }

  Future<void> replaceChild(
    ChildProfileData child,
  ) async {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    final existing = findByChildId(childId);

    if (existing == null) {
      await addChild(child);
      return;
    }

    final parentId = _requireParentId();

    await _client
        .from('enfants')
        .update(ChildProfileCodec.enfantRow(child, parentId))
        .eq('id', childId)
        .timeout(_writeTimeout);
    await _client
        .from('profils_sante')
        .upsert(
          ChildProfileCodec.santeRow(childId, child),
          onConflict: 'enfant_id',
        )
        .timeout(_writeTimeout);

    existing.essentialInformation = child;

    await _saveToLocalCache();
  }

  /// Supprime définitivement le profil d'un enfant (informations
  /// essentielles, profil santé, profil activités — les tables liées
  /// sont configurées en suppression en cascade côté base de
  /// données) et met à jour la copie locale en conséquence.
  Future<void> deleteChild(String childId) async {
    await _client
        .from('enfants')
        .delete()
        .eq('id', childId)
        .timeout(_writeTimeout);

    _children.removeWhere(
      (child) => child.childId == childId,
    );

    await _saveToLocalCache();
  }

  Future<void> saveActivityProfile({
    required String childId,
    required ActivityProfileData activityProfile,
  }) async {
    final child = findByChildId(childId);

    if (child == null) {
      return;
    }

    await _client
        .from('profils_activites')
        .upsert(
          ChildProfileCodec.activitesRow(
            childId,
            activityProfile,
          ),
          onConflict: 'enfant_id',
        )
        .timeout(_writeTimeout);

    child.activityProfile = activityProfile;
    child.activityProfileCompleted = true;

    await _saveToLocalCache();
  }

  /// Vide le cache en mémoire — utilisé par les tests pour vérifier
  /// qu'une relecture (Supabase ou copie locale) reconstruit vraiment
  /// les données, plutôt que de constater qu'elles sont "encore" là.
  @visibleForTesting
  void clearForTesting() {
    _children.clear();
  }

  /// Ajoute uniquement au cache local, sans appel réseau — utilisé par
  /// les tests unitaires et les profils de démo pour ne pas dépendre
  /// d'une connexion Supabase.
  void seedForTesting(ChildProfileData child) {
    final childId = child.childId;

    if (childId == null || findByChildId(childId) != null) {
      return;
    }

    _children.add(
      CompleteChildProfileData(
        essentialInformation: child,
      ),
    );
  }

  /// Équivalent de [saveActivityProfile], mais uniquement dans le cache
  /// local — même usage que [seedForTesting].
  void seedActivityProfileForTesting({
    required String childId,
    required ActivityProfileData activityProfile,
  }) {
    final child = findByChildId(childId);

    if (child == null) {
      return;
    }

    child.activityProfile = activityProfile;
    child.activityProfileCompleted = true;
  }

  String _requireParentId() {
    final parentId = SupabaseAuthProvider.instance.currentUserId;

    if (parentId == null) {
      throw StateError(
        "Impossible d'enregistrer : aucun utilisateur "
        'Supabase connecté.',
      );
    }

    return parentId;
  }

  // ---------------------------------------------------------------------
  // Copie locale persistante (mode hors-ligne)
  // ---------------------------------------------------------------------

  Future<void> _saveToLocalCache() async {
    _isOffline = false;
    _lastSyncAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();

    final items = _children
        .map(_childToCacheJson)
        .toList();

    await prefs.setString(_cacheKey, jsonEncode(items));
    await prefs.setString(
      _cacheSyncedAtKey,
      _lastSyncAt!.toIso8601String(),
    );

    notifyListeners();
  }

  /// Assemble un enfant complet en un seul bloc JSON, en réutilisant
  /// telles quelles les fonctions qui savent déjà le décomposer pour
  /// Supabase (`ChildProfileCodec`) — même forme, juste rassemblée en
  /// un objet local au lieu de trois lignes de tables séparées.
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
        : Map<String, dynamic>.from(
            json['sante'] as Map,
          );

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

  /// Déclenche une écriture de la copie locale sans passer par
  /// Supabase — utilisé par les tests pour vérifier l'aller-retour
  /// (sauvegarde puis relecture) sans dépendre du réseau.
  @visibleForTesting
  Future<void> saveToLocalCacheForTesting() {
    return _saveToLocalCache();
  }
}
