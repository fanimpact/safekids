import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../repositories/child_repository.dart';
import 'emergency_mode_button_list_page.dart';

/// Sélecteur d'enfant utilisé uniquement quand on arrive depuis l'accueil
/// (on ne sait pas encore de quel enfant il s'agit) et qu'il y a plusieurs
/// enfants enregistrés. Sélection unique : on touche un enfant et on
/// accède directement à son Mode Urgence.
class EmergencyModeChildPickerPage extends StatelessWidget {
  const EmergencyModeChildPickerPage({super.key});

  String _displayName(
    CompleteChildProfileData child,
  ) {
    final identity =
        child.essentialInformation.identity;

    final parts = [
      identity.firstName,
      identity.lastName,
    ].where(
      (value) =>
          value != null && value.trim().isNotEmpty,
    ).map(
      (value) => value!.trim(),
    );

    final name = parts.join(' ');

    return name.isEmpty ? 'Enfant' : name;
  }

  void _openButtonList(
    BuildContext context,
    CompleteChildProfileData child,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmergencyModeButtonListPage(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children =
        ChildRepository.instance.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Urgence'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pour quel enfant ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: children.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun enfant enregistré.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: children.length,
                        separatorBuilder:
                            (context, index) =>
                                const Divider(),
                        itemBuilder:
                            (context, index) {
                          final child =
                              children[index];

                          return ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.child_care,
                              ),
                            ),
                            title: Text(
                              _displayName(child),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () =>
                                _openButtonList(
                              context,
                              child,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
