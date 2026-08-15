import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'demo/demo_children.dart';
import 'demo/demo_test_children.dart';
import 'demo/demo_test_children_emma.dart';
import 'demo/demo_test_children_final.dart';
import 'demo/demo_test_children_lucas.dart';
import 'welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  DemoChildren.load();
  DemoTestChildren.load();
  DemoTestChildrenLucas.load();
  DemoTestChildrenEmma.load();
  DemoTestChildrenFinal.load();

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