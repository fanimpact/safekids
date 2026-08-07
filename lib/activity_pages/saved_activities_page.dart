import 'package:flutter/material.dart';

import '../models/activity_session/complete_activity_session_data.dart';
import '../repositories/activity_session_repository.dart';

class SavedActivitiesPage extends StatefulWidget {
  const SavedActivitiesPage({
    super.key,
  });

  @override
  State<SavedActivitiesPage> createState() =>
      _SavedActivitiesPageState();
}

class _SavedActivitiesPageState
    extends State<SavedActivitiesPage> {
  @override
  void initState() {
    super.initState();

    ActivitySessionRepository.instance
        .ensureDemoActivityExists();
  }

  @override
  Widget build(BuildContext context) {
    final activities =
        ActivitySessionRepository
            .instance
            .activities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activités enregistrées',
        ),
      ),
      body: SafeArea(
        child: activities.isEmpty
            ? const Center(
                child: Text(
                  'Aucune activité enregistrée.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder:
                    (context, index) {
                  final CompleteActivitySessionData
                      activity =
                      activities[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.event,
                      ),
                      title: Text(
                        activity.activityName ??
                            'Sans nom',
                      ),
                      subtitle: Text(
                        activity.location ??
                            'Lieu non renseigné',
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Préparer une activité',
        ),
      ),
    );
  }
}