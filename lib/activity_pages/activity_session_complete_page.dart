import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import '../repositories/activity_session_repository.dart';
import 'activities_home_page.dart';

class ActivitySessionCompletePage extends StatelessWidget {
  final ActivitySessionData sessionData;

  const ActivitySessionCompletePage({
    super.key,
    required this.sessionData,
  });

  void _finish(BuildContext context) {
    ActivitySessionRepository.instance.addActivity(
      sessionData,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivitiesHomePage(),
      ),
      (route) => route.isFirst,
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

              if (sessionData.activityName != null &&
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
                'Cette activité sera enregistrée lorsque vous appuierez sur Terminer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: () => _finish(context),
                child: const Text(
                  'Terminer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}