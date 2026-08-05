import 'package:flutter/material.dart';

import '../activity_profile_pages/activity_profile_entry_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../particulier_home_page.dart';

class EssentialInformationCompletedPage
    extends StatelessWidget {
  final ActivityProfileController
      activityProfileController;

  const EssentialInformationCompletedPage({
    super.key,
    required this.activityProfileController,
  });

  void _continueActivityProfile(
    BuildContext context,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityProfileEntryPage(
          activityProfileController:
              activityProfileController,
        ),
      ),
    );
  }

  void _finishForNow(
    BuildContext context,
  ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ParticulierHomePage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil de votre enfant',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              const Icon(
                Icons.check_circle_outline,
                size: 72,
              ),

              const SizedBox(height: 24),

              const Text(
                'Les informations essentielles de votre enfant sont enregistrées.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Vous venez de terminer la première partie de son profil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Ces informations permettront notamment de générer une fiche destinée aux services de secours et seront disponibles dans le Mode Urgence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Vous pouvez poursuivre maintenant en complétant le profil Activités ou revenir plus tard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Le profil Activités permettra d’adapter automatiquement les recommandations en fonction des activités réalisées par votre enfant.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 40),

              FilledButton(
                onPressed: () =>
                    _continueActivityProfile(
                  context,
                ),
                child: const Text(
                  'Continuer le profil Activités',
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () =>
                    _finishForNow(
                  context,
                ),
                child: const Text(
                  'Terminer pour le moment',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}