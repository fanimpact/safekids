import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/app_auth.dart';
import 'auth/set_new_password_page.dart';
import 'config/supabase_config.dart';
import 'repositories/child_repository.dart';
import 'welcome_page.dart';

/// Permet de naviguer depuis en dehors de l'arbre de widgets, pour le
/// cas où l'app est ouverte "à froid" via le lien "mot de passe
/// oublié" reçu par email (kidsrelay://auth-callback) : l'évènement
/// Supabase peut arriver avant qu'un contexte d'écran ne soit prêt.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

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
  const KidsRelayApp({
    super.key,
  });

  @override
  State<KidsRelayApp> createState() => _KidsRelayAppState();
}

class _KidsRelayAppState extends State<KidsRelayApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    // Ouvrir l'app via le lien "mot de passe oublié" (kidsrelay://
    // auth-callback) déclenche cet évènement une fois la session
    // temporaire établie par Supabase : on bascule alors directement
    // sur l'écran de saisie du nouveau mot de passe, y compris si
    // l'app vient d'être lancée à froid par ce lien.
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}