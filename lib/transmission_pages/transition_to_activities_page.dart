import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../particulier_home_page.dart';

class TransitionToActivitiesPage extends StatelessWidget {
  final TransmissionController transmissionController;

  const TransitionToActivitiesPage({
    super.key,
    required this.transmissionController,
  });

  void _finishForNow(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ParticulierHomePage(),
      ),
      (route) => false,
    );
  }

  void _continueToActivities(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Le profil Activités sera créé à l’étape suivante.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil de l'enfant"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.check_circle_outline,
                size: 72,
              ),

              const SizedBox(height: 24),

              const Text(
                "Les informations essentielles ont été enregistrées.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Les informations que vous venez de renseigner permettront "
                "de préparer une fiche qui pourra être transmise aux "
                "services de secours en cas d'urgence.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Vous pourrez compléter plus tard le profil de votre enfant "
                "afin de préparer les activités de votre enfant. Les "
                "informations déjà renseignées seront automatiquement "
                "réutilisées : vous n'aurez pas besoin de les saisir une "
                "seconde fois.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              FilledButton(
                onPressed: () => _continueToActivities(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  "Compléter le profil Activités",
                  style: TextStyle(fontSize: 17),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () => _finishForNow(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  "Terminer pour le moment",
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}