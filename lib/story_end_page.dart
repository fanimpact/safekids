import 'package:flutter/material.dart';

class StoryEndPage extends StatelessWidget {
  const StoryEndPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue dans SafeKids'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.favorite,
              size: 90,
              color: Colors.red,
            ),

            const SizedBox(height: 30),

            const Text(
              'Vous êtes prêt à créer le profil de votre enfant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Quelques minutes suffisent pour commencer à sécuriser le quotidien de votre enfant.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const Spacer(),

            FilledButton(
              onPressed: () {
  Navigator.popUntil(context, (route) => route.isFirst);
},
              child: const Text('Créer gratuitement la fiche de mon enfant'),
            ),
          ],
        ),
      ),
    );
  }
}