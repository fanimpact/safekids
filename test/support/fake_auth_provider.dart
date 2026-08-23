import 'dart:async';

import 'package:kidsrelay/auth/auth_provider.dart';

/// Double de [AuthProvider] pour les tests.
///
/// Enregistre les opérations reçues et laisse le test piloter l'état de
/// session et les évènements. Aucun réseau, aucun SDK : c'est
/// précisément ce que l'abstraction du 23/08/2026 rend possible.
///
/// Le journal [operations] est la façon de vérifier *ce que l'app a
/// demandé*, dans l'ordre — utile là où le résultat visible ne dit pas
/// tout (ex. la déconnexion avant création d'un compte séparé).
class FakeAuthProvider implements AuthProvider {
  FakeAuthProvider({
    String? currentUserId,
    String? currentUserEmail,
    bool isAnonymous = false,
  })  : _identifiant = currentUserId,
        _email = currentUserEmail,
        _anonyme = isAnonymous;

  /// Session anonyme déjà ouverte, cas du lancement habituel.
  factory FakeAuthProvider.sessionAnonyme() => FakeAuthProvider(
        currentUserId: 'utilisateur-anonyme',
        isAnonymous: true,
      );

  /// Compte réel connecté.
  factory FakeAuthProvider.compteReel({
    String email = 'parent@exemple.fr',
  }) =>
      FakeAuthProvider(
        currentUserId: 'utilisateur-reel',
        currentUserEmail: email,
        isAnonymous: false,
      );

  /// Aucune session : premier lancement.
  factory FakeAuthProvider.sansSession() => FakeAuthProvider();

  String? _identifiant;
  String? _email;
  bool _anonyme;

  final _controller = StreamController<AuthSessionEvent>.broadcast();

  /// Opérations reçues, dans l'ordre.
  final List<String> operations = [];

  /// Erreur à lever à la prochaine opération, pour simuler un refus du
  /// fournisseur.
  AuthFailure? prochaineErreur;

  int initializeCount = 0;

  void _enregistrer(String operation) {
    operations.add(operation);

    final erreur = prochaineErreur;

    if (erreur != null) {
      prochaineErreur = null;
      throw erreur;
    }
  }

  /// Émet un évènement, comme le ferait le fournisseur réel.
  void emettre(AuthSessionEvent event) {
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();

  @override
  Future<void> initialize() async {
    initializeCount++;
    _enregistrer('initialize');
  }

  @override
  String? get currentUserId => _identifiant;

  @override
  String? get currentUserEmail => _email;

  @override
  bool get isAnonymous => _anonyme;

  @override
  bool get hasSession => _identifiant != null;

  @override
  Future<void> signInAnonymously() async {
    _enregistrer('signInAnonymously');

    // Même garde que l'implémentation réelle : sans effet si une
    // session existe déjà.
    if (hasSession) {
      return;
    }

    _identifiant = 'utilisateur-anonyme';
    _email = null;
    _anonyme = true;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _enregistrer('signInWithPassword($email)');

    _identifiant = 'utilisateur-reel';
    _email = email;
    _anonyme = false;
  }

  @override
  Future<void> signOut() async {
    _enregistrer('signOut');

    _identifiant = null;
    _email = null;
    _anonyme = false;
  }

  @override
  Future<void> attachAccountToCurrentSession({
    required String email,
    required String password,
    required String emailRedirectUrl,
  }) async {
    _enregistrer('attachAccountToCurrentSession($email)');

    _email = email;
    _anonyme = false;
  }

  @override
  Future<void> updatePassword(String password) async {
    _enregistrer('updatePassword');
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String redirectUrl,
  }) async {
    _enregistrer('requestPasswordReset($email)');
  }

  @override
  Stream<AuthSessionEvent> get onSessionEvent => _controller.stream;
}
