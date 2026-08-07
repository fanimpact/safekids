import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_child_selection_page.dart';

class ActivitySessionCompletePage
    extends StatelessWidget {
  final ActivitySessionData sessionData;

  const ActivitySessionCompletePage({
    super.key,
    required this.sessionData,
  });

  void _continue(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityChildSelectionPage(
          sessionData: sessionData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activité complétée',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Icon(
                Icons.check_circle_outline,
                size: 72,
              ),

              const SizedBox(height: 24),

              const Text(
                'Le questionnaire de l’activité est terminé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              if (sessionData.activityName !=
                      null &&
                  sessionData.activityName!
                      .isNotEmpty)
                Text(
                  sessionData.activityName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),

              const SizedBox(height: 12),

              const Text(
                'Vous allez maintenant sélectionner les enfants concernés par cette activité.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: () =>
                    _continue(context),
                child: const Text(
                  'Choisir les enfants',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}