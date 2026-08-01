import 'package:flutter/material.dart';
import 'story_transmission_page.dart';

class StoryEmergencyPage extends StatelessWidget {
  const StoryEmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode urgence'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.emergency,
              size: 80,
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            const Text(
              'En cas d’urgence',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Un seul écran regroupe les informations essentielles : conduite à tenir, traitement d’urgence et accès rapide aux informations importantes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const Spacer(),

            FilledButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StoryTransmissionPage(),
    ),
  );
},
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}