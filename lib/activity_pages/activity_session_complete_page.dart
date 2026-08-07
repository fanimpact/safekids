import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';

class ActivitySessionCompletePage extends StatelessWidget {
  final ActivitySessionData sessionData;

  const ActivitySessionCompletePage({
    super.key,
    required this.sessionData,
  });

  void _finish(BuildContext context) {
    Navigator.of(context).popUntil(
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