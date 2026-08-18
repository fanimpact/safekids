import 'package:flutter/material.dart';

import '../emergency_mode/emergency_mode_button_list_page.dart';
import '../models/complete_child_profile_data.dart';
import 'professional_child_repository.dart';

/// Équivalent professionnel de `EmergencyModeChildPickerPage` : point
/// d'entrée du Mode Urgence depuis l'accueil de l'espace
/// professionnel, avant de savoir de quel enfant il s'agit — alimenté
/// par le trombinoscope de l'établissement au lieu des propres enfants
/// du parent.
class ProfessionalEmergencyModeChildPickerPage
    extends StatelessWidget {
  const ProfessionalEmergencyModeChildPickerPage({
    super.key,
  });

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
    return ListenableBuilder(
      listenable: ProfessionalChildRepository.instance,
      builder: (context, _) {
        final children =
            ProfessionalChildRepository.instance.children;

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
                              'Aucun enfant rattaché.',
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
                                leading:
                                    const CircleAvatar(
                                  child: Icon(
                                    Icons.child_care,
                                  ),
                                ),
                                title: Text(
                                  _displayName(child),
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .w600,
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
      },
    );
  }
}
