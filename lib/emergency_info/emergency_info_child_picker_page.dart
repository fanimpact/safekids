import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../repositories/child_repository.dart';
import 'emergency_info_sheet_page.dart';

/// Sélecteur d'enfant utilisé uniquement quand on arrive depuis l'accueil
/// (on ne sait pas encore de quel enfant il s'agit) et qu'il y a plusieurs
/// enfants enregistrés. Contrairement au sélecteur de la préparation
/// d'activité, celui-ci est à sélection unique : on touche un enfant et on
/// accède directement à sa fiche.
class EmergencyInfoChildPickerPage extends StatelessWidget {
  const EmergencyInfoChildPickerPage({super.key});

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

  void _openSheet(
    BuildContext context,
    CompleteChildProfileData child,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmergencyInfoSheetPage(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sans ça, cette page pourrait continuer d'afficher un enfant
    // supprimé/ajouté ailleurs entre-temps si elle reste en mémoire
    // sous une autre page au lieu d'être rouverte à neuf.
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) {
        final children =
            ChildRepository.instance.children;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Informations pour les secours',
            ),
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
                                    _openSheet(
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
