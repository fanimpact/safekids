import 'package:flutter/material.dart';

import 'saved_activities_page.dart';

class SavedActivitiesInfoPage extends StatelessWidget {
  const SavedActivitiesInfoPage({
    super.key,
  });

  void _continue(
    BuildContext context,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SavedActivitiesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activités enregistrées',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.info_outline,
                size: 72,
              ),

              const SizedBox(height: 28),

              const Text(
                'Avant de continuer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Une activité enregistrée permet de gagner du temps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Vérifiez toujours les caractéristiques de l’activité avant de générer les recommandations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Une activité portant le même nom peut avoir des caractéristiques différentes selon le lieu, la durée, l’environnement ou l’organisation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Les recommandations sont calculées à partir des caractéristiques de l’activité, pas de son nom.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: () =>
                    _continue(context),
                style:
                    FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  'J’ai compris',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}