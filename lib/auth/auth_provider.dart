/// Frontière entre l'application et le fournisseur d'authentification.
///
/// Tout ce que KidsRelay sait faire d'un compte passe par cette
/// interface. Elle ne mentionne aucun SDK, aucun type de bibliothèque
/// tierce : le jour où l'hébergeur change, c'est l'implémentation qui
/// est réécrite, pas les écrans ni les services.
///
/// Avant sa création (23/08/2026), 30 appels au SDK Supabase étaient
/// dispersés dans 12 fichiers, dont 5 écrans qui l'appelaient
/// directement.
abstract class AuthProvider {
  /// Prépare le fournisseur. Appelé une seule fois au démarrage, avant
  /// toute autre opération.
  Future<void> initialize();

  /// Identifiant technique de la personne connectée, ou `null` si
  /// aucune session n'est ouverte.
  ///
  /// C'est cette valeur que la base rapproche de `auth.uid()` dans ses
  /// règles de cloisonnement : `enfants.parent_id`,
  /// `membres_etablissement.user_id`, etc.
  String? get currentUserId;

  /// Adresse email de la personne connectée, ou `null` si elle n'en a
  /// pas encore (session anonyme) ou si aucune session n'est ouverte.
  String? get currentUserEmail;

  /// Vrai quand la session en cours n'est rattachée à aucun compte
  /// réel — l'app en ouvre une dès le premier lancement, pour que
  /// l'enfant puisse être enregistré sans créer de compte.
  bool get isAnonymous;

  /// Vrai dès qu'une session existe, anonyme ou non.
  bool get hasSession;

  /// Ouvre une session anonyme. Sans effet si une session existe déjà.
  Future<void> signInAnonymously();

  /// Connexion par email et mot de passe.
  ///
  /// Ne dit rien de l'appareil utilisé : c'est à l'appelant de
  /// vérifier ensuite s'il est reconnu (voir
  /// `AccountService.isCurrentDeviceRecognized`).
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Attache un email et un mot de passe à la session en cours, sans
  /// changer l'identité technique.
  ///
  /// C'est ce qui permet de transformer une session anonyme en compte
  /// réel sans perdre les enfants déjà enregistrés : `currentUserId`
  /// reste le même avant et après.
  ///
  /// [emailRedirectUrl] est l'adresse ouverte depuis l'email de
  /// confirmation.
  Future<void> attachAccountToCurrentSession({
    required String email,
    required String password,
    required String emailRedirectUrl,
  });

  /// Change le mot de passe de la personne connectée.
  Future<void> updatePassword(String password);

  /// Envoie l'email de réinitialisation. Ne révèle jamais si l'adresse
  /// correspond à un compte existant.
  Future<void> requestPasswordReset({
    required String email,
    required String redirectUrl,
  });

  /// Évènements de session, pour les écrans qui doivent réagir sans
  /// avoir déclenché l'opération eux-mêmes.
  Stream<AuthSessionEvent> get onSessionEvent;
}

/// Ce qui peut arriver à une session en dehors d'une action explicite
/// de l'application.
///
/// Volontairement réduit à ce que KidsRelay traite réellement : ajouter
/// une valeur ici doit rester un choix, pas une transcription de tout
/// ce qu'un SDK sait émettre.
enum AuthSessionEvent {
  /// L'app a été ouverte par un lien "mot de passe oublié" et une
  /// session temporaire vient d'être établie. L'écran de saisie du
  /// nouveau mot de passe doit s'afficher.
  passwordRecovery,

  /// Une session vient de s'ouvrir.
  signedIn,

  /// La session a pris fin.
  signedOut,
}

/// Cause d'un échec d'authentification, traduite depuis le
/// fournisseur.
///
/// L'application ne voit jamais les codes d'erreur du SDK : c'est
/// l'implémentation qui les rapproche de cette liste, et
/// `friendlyAuthErrorMessage` qui en fait une phrase lisible.
enum AuthErrorCode {
  emailAddressInvalid,
  emailAlreadyExists,
  tooManyAttempts,
  weakPassword,
  samePassword,
  invalidCredentials,
  signupDisabled,

  /// Le serveur n'a pas pu être joint.
  network,

  /// Rejet compris par le fournisseur, mais qu'on ne sait pas nommer
  /// plus précisément.
  unknown,
}

/// Échec d'une opération d'authentification.
///
/// Remplace l'exception du SDK, qui remontait jusque dans les
/// utilitaires d'affichage et les écrans.
class AuthFailure implements Exception {
  final AuthErrorCode code;

  /// Message brut du fournisseur, conservé pour le diagnostic. Jamais
  /// affiché tel quel : il n'est ni traduit, ni écrit pour un parent.
  final String? rawMessage;

  const AuthFailure(this.code, {this.rawMessage});

  @override
  String toString() =>
      'AuthFailure(${code.name}${rawMessage == null ? '' : ' : $rawMessage'})';
}
