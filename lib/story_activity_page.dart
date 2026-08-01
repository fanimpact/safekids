import 'package:flutter/material.dart';
import 'story_emergency_page.dart';

class StoryActivityPage extends StatelessWidget {
  const StoryActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activité'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            const Text(
              'Préparer une sortie',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Vous choisissez une activité.\n'
              'SafeKids affiche automatiquement les informations importantes à ne pas oublier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            Card(
              child: ListTile(
                leading: Icon(Icons.pool),
                title: Text('Piscine'),
                subtitle: Text(
                  'Prévoir le traitement d’urgence • Informer le maître-nageur • Vérifier les consignes',
                ),
              ),
            ),

            const Spacer(),

            FilledButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StoryEmergencyPage(),
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