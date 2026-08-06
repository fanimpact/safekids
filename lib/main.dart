import 'package:flutter/material.dart';

import 'demo/demo_children.dart';
import 'welcome_page.dart';

void main() {
  DemoChildren.load();

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