import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../utils/child_name_utils.dart';
import 'activity_session_start_page.dart';
import 'saved_activities_info_page.dart';

class ActivitiesHomePage extends StatelessWidget {
  final CompleteChildProfileData? selectedChild;

  const ActivitiesHomePage({
    super.key,
    this.selectedChild,
  });

  String? get _childDisplayName {
    final child = selectedChild;

    if (child == null) {
      return null;
    }

    return childFullName(
      child.essentialInformation.identity,
    );
  }

  void _openNewActivity(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivitySessionStartPage(),
      ),
    );
  }

  void _openSavedActivities(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SavedActivitiesInfoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childDisplayName = _childDisplayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activités',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Text(
                'Que souhaitez-vous faire ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (childDisplayName != null) ...[
                const SizedBox(height: 12),

                Text(
                  'Pour $childDisplayName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _openNewActivity(context),
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Préparer une activité',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openSavedActivities(context),
                  icon: const Icon(
                    Icons.folder_open,
                  ),
                  label: const Text(
                    'Activités enregistrées',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}