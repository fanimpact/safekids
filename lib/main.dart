import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/app_auth.dart';
import 'config/supabase_config.dart';
import 'repositories/child_repository.dart';
import 'welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // L'app doit pouvoir s'ouvrir même sans réseau ou si Supabase est
  // indisponible (Mode Urgence en particulier ne doit jamais rester
  // bloqué faute de connexion) : on tente la synchronisation avec un
  // délai maximum, mais on lance l'app dans tous les cas.
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
  }

  runApp(
    const SafeKidsApp(),
  );
}

class SafeKidsApp extends StatelessWidget {
  const SafeKidsApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeKids',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SafeKids',
        ),
      ),
      body: const Center(
        child: Text(
          'Bienvenue dans SafeKids',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}