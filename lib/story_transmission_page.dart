import 'package:flutter/material.dart';
import 'story_end_page.dart';

class StoryTransmissionPage extends StatelessWidget {
  const StoryTransmissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche de télétransmission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.description,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'Une fiche prête à remettre aux secours',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Toutes les informations essentielles sont regroupées sur une seule fiche : antécédents, traitement, médicament d’urgence et informations utiles pour les secours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const Spacer(),

            FilledButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StoryEndPage(),
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