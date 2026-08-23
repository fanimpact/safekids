import 'dart:async';

import 'package:flutter/material.dart';

import 'auth/app_auth.dart';
import 'auth/auth_provider.dart';
import 'auth/set_new_password_page.dart';
import 'auth/supabase_auth_provider.dart';
import 'repositories/child_repository.dart';
import 'theme/kidsrelay_theme.dart';
import 'welcome_page.dart';

/// Permet de naviguer depuis en dehors de l'arbre de widgets, pour le
/// cas où l'app est ouverte "à froid" via le lien "mot de passe
/// oublié" reçu par email (kidsrelay://auth-callback) : l'évènement
/// Supabase peut arriver avant qu'un contexte d'écran ne soit prêt.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseAuthProvider.instance.initialize();

  // L'app doit pouvoir s'ouvrir même sans réseau ou si Supabase est
  // indisponible (Mode Urgence en particulier ne doit jamais rester
  // bloqué faute de connexion) : on tente la synchronisation avec un
  // délai maximum ; en cas d'échec, on affiche la dernière copie
  // locale connue plutôt qu'une liste vide.
  try {
    await ensureSignedIn().timeout(
      const Duration(seconds: 10),
    );
    await ChildRepository.instance
        .loadFromSupabase()
        .timeout(const Duration(seconds: 10));
  } catch (error) {
    debugPrint(
      'Synchronisation Supabase indisponible au '
      'démarrage : $error',
    );

    await ChildRepository.instance
        .loadFromLocalCacheIfAvailable();
  }

  // Dès que le réseau revient (au démarrage ou plus tard pendant la
  // session), retente une synchronisation en arrière-plan.
  ChildRepository.instance.startAutoResync();

  runApp(
    const KidsRelayApp(),
  );
}

class KidsRelayApp extends StatefulWidget {
  /// Fournisseur d'authentification écouté par l'app. Laissé à `null`
  /// en production — l'implémentation Supabase est alors utilisée.
  ///
  /// Ce paramètre n'existe que pour permettre aux tests de fournir un
  /// double et de vérifier ce que l'app fait d'un évènement de session.
  /// Le câblage du lien « mot de passe oublié » ne reposait sinon que
  /// sur une vérification manuelle.
  final AuthProvider? authProvider;

  const KidsRelayApp({
    super.key,
    this.authProvider,
  });

  @override
  State<KidsRelayApp> createState() => _KidsRelayAppState();
}

class _KidsRelayAppState extends State<KidsRelayApp> {
  late final StreamSubscription<AuthSessionEvent> _authSubscription;

  @override
  void initState() {
    super.initState();

    // Ouvrir l'app via le lien "mot de passe oublié" (kidsrelay://
    // auth-callback) déclenche cet évènement une fois la session
    // temporaire établie par Supabase : on bascule alors directement
    // sur l'écran de saisie du nouveau mot de passe, y compris si
    // l'app vient d'être lancée à froid par ce lien.
    final auth =
        widget.authProvider ?? SupabaseAuthProvider.instance;

    _authSubscription = auth.onSessionEvent.listen(
      (event) {
        if (event == AuthSessionEvent.passwordRecovery) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const SetNewPasswordPage(),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'KidsRelay',
      theme: kidsRelayTheme(),
      home: const WelcomePage(),
    );
  }
}