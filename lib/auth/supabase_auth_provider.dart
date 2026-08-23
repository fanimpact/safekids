import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'auth_provider.dart';

/// Implémentation Supabase de [AuthProvider].
///
/// **C'est le seul fichier de l'application autorisé à connaître
/// Supabase Auth.** Tout appel au SDK lié à l'authentification passe
/// ici — y compris `Supabase.initialize`. Le jour où l'hébergeur
/// change, ce fichier est réécrit et rien d'autre.
///
/// Ne pas réintroduire `Supabase.instance.client.auth` ailleurs dans
/// `lib/` : c'est précisément ce que ce chantier a supprimé
/// (23/08/2026, 30 appels dispersés dans 12 fichiers).
class SupabaseAuthProvider implements AuthProvider {
  SupabaseAuthProvider._();

  static final SupabaseAuthProvider instance = SupabaseAuthProvider._();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  bool get isAnonymous =>
      _client.auth.currentUser?.isAnonymous ?? false;

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Future<void> signInAnonymously() async {
    if (hasSession) {
      return;
    }

    await _execute(() => _client.auth.signInAnonymously());
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _execute(
      () => _client.auth.signInWithPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<void> signOut() {
    return _execute(() => _client.auth.signOut());
  }

  @override
  Future<void> attachAccountToCurrentSession({
    required String email,
    required String password,
    required String emailRedirectUrl,
  }) {
    // `updateUser` et non `signUp` : c'est ce qui conserve
    // `auth.uid()`, donc les enfants déjà enregistrés sous la session
    // anonyme.
    return _execute(
      () => _client.auth.updateUser(
        UserAttributes(email: email, password: password),
        emailRedirectTo: emailRedirectUrl,
      ),
    );
  }

  @override
  Future<void> updatePassword(String password) {
    return _execute(
      () => _client.auth.updateUser(
        UserAttributes(password: password),
      ),
    );
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String redirectUrl,
  }) {
    return _execute(
      () => _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      ),
    );
  }

  @override
  Stream<AuthSessionEvent> get onSessionEvent {
    return _client.auth.onAuthStateChange
        .map(_toSessionEvent)
        .where((event) => event != null)
        .cast<AuthSessionEvent>();
  }

  /// Ne laisse remonter que les évènements que l'application traite.
  /// Tous les autres (rafraîchissement de jeton, mise à jour du
  /// profil…) sont filtrés : les transcrire n'apporterait rien et
  /// exposerait le vocabulaire du SDK.
  static AuthSessionEvent? _toSessionEvent(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.passwordRecovery:
        return AuthSessionEvent.passwordRecovery;
      case AuthChangeEvent.signedIn:
        return AuthSessionEvent.signedIn;
      case AuthChangeEvent.signedOut:
        return AuthSessionEvent.signedOut;
      default:
        return null;
    }
  }

  /// Exécute une opération du SDK en traduisant ses échecs en
  /// [AuthFailure]. Sans ça, un type Supabase remonterait jusqu'aux
  /// écrans.
  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthApiException catch (error) {
      throw AuthFailure(
        _toErrorCode(error.code),
        rawMessage: error.message,
      );
    } catch (error) {
      // Réseau coupé, DNS, serveur injoignable : tout ce qui n'est pas
      // un rejet compris par le fournisseur.
      throw AuthFailure(
        AuthErrorCode.network,
        rawMessage: error.toString(),
      );
    }
  }

  static AuthErrorCode _toErrorCode(String? code) {
    switch (code) {
      case 'email_address_invalid':
        return AuthErrorCode.emailAddressInvalid;
      case 'email_exists':
      case 'user_already_exists':
        return AuthErrorCode.emailAlreadyExists;
      case 'over_email_send_rate_limit':
        return AuthErrorCode.tooManyAttempts;
      case 'weak_password':
        return AuthErrorCode.weakPassword;
      case 'same_password':
        return AuthErrorCode.samePassword;
      case 'invalid_credentials':
        return AuthErrorCode.invalidCredentials;
      case 'signup_disabled':
        return AuthErrorCode.signupDisabled;
      default:
        return AuthErrorCode.unknown;
    }
  }
}
