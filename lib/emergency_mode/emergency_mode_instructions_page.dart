import 'package:flutter/material.dart';

/// Écran générique de consigne pour le Mode Urgence : affiche soit une
/// liste d'étapes numérotées automatiquement (préparées à l'avance par
/// le parent pour une pathologie/allergie précise), soit un message
/// unique (pas de consigne renseignée, ou cas "Autre urgence").
/// Cet écran ne contient aucune logique médicale — tout le texte lui
/// est fourni tel quel par l'écran précédent.
class EmergencyModeInstructionsPage extends StatelessWidget {
  final String title;
  final List<String> steps;
  final String emptyMessage;

  const EmergencyModeInstructionsPage({
    super.key,
    required this.title,
    required this.steps,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Urgence'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (steps.isEmpty)
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                      ),
                    )
                  else
                    for (var index = 0;
                        index < steps.length;
                        index++)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: Text(
                          '${index + 1}. ${steps[index]}',
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.4,
                          ),
                        ),
                      ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.red.shade700,
              child: const Text(
                'Appelez les secours (15 ou 112)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
