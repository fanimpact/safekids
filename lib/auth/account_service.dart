import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'auth_provider.dart';
import 'device_identity.dart';
import 'supabase_auth_provider.dart';

/// Regroupe toutes les opérations liées au compte réel — email + mot de
/// passe — communes aux parents et au personnel scolaire (espace
/// professionnel) : la conversion de la session anonyme existante en
/// compte (sans jamais changer `auth.uid()`, donc sans jamais perdre
/// les enfants déjà enregistrés côté parent), la connexion, la
/// réinitialisation de mot de passe, et la vérification par email d'un
/// appareil non reconnu (remplace la double authentification classique
/// par application tierce, jugée trop lourde à l'inscription).
///
/// Un même compte peut être à la fois parent (des enfants lui
/// appartiennent via `enfants.parent_id`) et membre du personnel d'un
/// ou plusieurs établissements (`membres_etablissement.user_id`) : ce
/// service ne fait aucune hypothèse sur le "rôle" de la personne, les
/// deux espaces de l'app s'appuient simplement sur la même identité
/// technique.
class AccountService {
  AccountService._();

  static final AccountService instance = AccountService._();

  /// Tout ce qui touche au compte lui-même passe par cette frontière —
  /// plus aucun appel direct au SDK d'authentification ici
  /// (23/08/2026).
  AuthProvider get _auth =>
      _authProviderForTesting ?? SupabaseAuthProvider.instance;

  AuthProvider? _authProviderForTesting;

  /// Remplace le fournisseur, uniquement pour les tests.
  ///
  /// Passer `null` rétablit l'implémentation Supabase — à faire en
  /// `tearDown`, sinon le remplacement fuiterait d'un test à l'autre
  /// (ce service est un singleton).
  @visibleForTesting
  void useAuthProviderForTesting(AuthProvider? authProvider) {
    _authProviderForTesting = authProvider;
  }

  /// Conservé uniquement pour les tables et les Edge Functions :
  /// `appareils_reconnus`, `comptes_parents`, `codes_verification`.
  /// L'accès aux données n'est pas encore abstrait.
  SupabaseClient get _client => Supabase.instance.client;

  /// Convertit la session anonyme actuelle en compte réel. L'identité
  /// technique (`auth.uid()`) ne change pas : `enfants.parent_id` et
  /// toutes les données déjà enregistrées restent valides sans aucune
  /// migration.
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await _auth.attachAccountToCurrentSession(
      email: email,
      password: password,
      emailRedirectUrl: SupabaseConfig.authRedirectUrl,
    );

    // Sans ça, la connexion par mot de passe peut échouer tant que la
    // personne n'a pas cliqué le lien de confirmation reçu par email :
    // Supabase ne crée la ligne d'identité "email" qu'à ce moment-là,
    // indépendamment du mot de passe lui-même. On la garantit
    // immédiatement, pour pouvoir se reconnecter sans attendre.
    try {
      await _client.rpc('rpc_assurer_identite_email');
    } catch (_) {
      // Non bloquant pour la création du compte elle-même ; si la
      // fonction n'existe pas encore côté serveur, la conversion reste
      // valable, seule cette garantie supplémentaire est absente.
    }

    final userId = _auth.currentUserId;

    if (userId == null) {
      return;
    }

    await _client.from('comptes_parents').upsert({
      'id': userId,
      'email': email,
      'compte_relie_le': DateTime.now().toUtc().toIso8601String(),
    });

    // Le nouveau compte vient d'être créé sur cet appareil : pas besoin
    // de lui redemander un code de vérification juste après.
    await _registerCurrentDeviceDirectly();
  }

  /// Crée un compte totalement indépendant de la session actuelle —
  /// utilisé pour l'espace professionnel : contrairement à
  /// [createAccount] (pensé pour convertir la session anonyme d'un
  /// parent en son propre compte), celui-ci NE DOIT JAMAIS réutiliser
  /// une session déjà attachée à un compte réel. Sans cette précaution,
  /// créer un compte professionnel alors qu'un parent est connecté
  /// écraserait l'email et le mot de passe de CE parent (déjà arrivé :
  /// c'est ce qui avait fait perdre l'accès à Théo et Noé).
  Future<void> createSeparateAccount({
    required String email,
    required String password,
  }) async {
    // Un compte réel déjà connecté doit céder la place à une session
    // anonyme neuve, sinon le nouveau compte reprendrait son identité
    // technique — et donc ses enfants.
    //
    // La condition porte sur l'identité et non sur la session, pour
    // rester strictement équivalente au code d'origine
    // (`currentUser != null && currentUser.isAnonymous == false`).
    if (_auth.currentUserId != null && !_auth.isAnonymous) {
      await _auth.signOut();
      await _auth.signInAnonymously();
    }

    await createAccount(email: email, password: password);
  }

  /// Connexion par mot de passe. Ne dit rien sur l'appareil : appeler
  /// [isCurrentDeviceRecognized] juste après pour savoir si une
  /// vérification par code est nécessaire avant de continuer.
  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  /// À appeler juste après une connexion réussie : vérifie si cet
  /// appareil a déjà été validé pour le compte connecté.
  Future<bool> isCurrentDeviceRecognized() async {
    final userId = _auth.currentUserId;

    if (userId == null) {
      return false;
    }

    final jetonHash = await DeviceIdentity.tokenHash();

    final row = await _client
        .from('appareils_reconnus')
        .select('id')
        .eq('user_id', userId)
        .eq('jeton_hash', jetonHash)
        .maybeSingle();

    if (row == null) {
      return false;
    }

    // Trace d'usage à titre informatif, échec silencieux acceptable.
    unawaited(
      _client
          .from('appareils_reconnus')
          .update({
            'derniere_utilisation_le':
                DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', row['id'])
          .catchError((_) {}),
    );

    return true;
  }

  /// Déclenche l'envoi du code de vérification par email pour cet
  /// appareil non reconnu.
  Future<void> requestDeviceVerificationCode() async {
    final jetonHash = await DeviceIdentity.tokenHash();

    final response = await _client.functions.invoke(
      'envoyer-code-verification',
      body: {'jetonAppareilHash': jetonHash},
    );

    if (response.status != 200) {
      throw const AccountServiceException(
        'Impossible d’envoyer le code de vérification. '
        'Réessayez dans un instant.',
      );
    }
  }

  /// Vérifie le code saisi par la personne. En cas de succès, cet
  /// appareil est mémorisé comme reconnu pour les prochaines
  /// connexions.
  Future<void> verifyDeviceCode(String code) async {
    final jetonHash = await DeviceIdentity.tokenHash();

    final response = await _client.functions.invoke(
      'verifier-code',
      body: {
        'code': code,
        'jetonAppareilHash': jetonHash,
      },
    );

    if (response.status != 200) {
      throw const AccountServiceException(
        'Code invalide ou expiré.',
      );
    }
  }

  Future<void> requestPasswordReset(String email) {
    return _auth.requestPasswordReset(
      email: email,
      redirectUrl: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Enregistre directement l'appareil courant comme reconnu, sans
  /// passer par un code — utilisé uniquement juste après la création
  /// d'un compte sur cet appareil (le mot de passe vient d'y être
  /// défini, il n'y a pas de risque supplémentaire à le considérer
  /// comme reconnu).
  Future<void> _registerCurrentDeviceDirectly() async {
    final userId = _auth.currentUserId;

    if (userId == null) {
      return;
    }

    final jetonHash = await DeviceIdentity.tokenHash();

    await _client.from('appareils_reconnus').upsert(
      {
        'user_id': userId,
        'jeton_hash': jetonHash,
        'derniere_utilisation_le':
            DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,jeton_hash',
    );
  }
}

class AccountServiceException implements Exception {
  final String message;

  const AccountServiceException(this.message);

  @override
  String toString() => message;
}
