import 'package:flutter/material.dart';
import 'dart:async';

import 'concept_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ConceptPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pas de fond impose : l'ecran herite du lin defini par le theme.
    return Scaffold(
      body: const Center(
        child: Text(
          "Bienvenue dans\nKidsRelay",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}