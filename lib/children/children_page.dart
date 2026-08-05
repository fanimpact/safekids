import 'package:flutter/material.dart';

import '../child_profile_pages/create_child_profile_intro_page.dart';
import '../models/child_profile_data.dart';
import '../repositories/child_repository.dart';

class ChildrenPage extends StatelessWidget {
  const ChildrenPage({
    super.key,
  });

  void _openCreateProfile(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CreateChildProfileIntroPage(),
      ),
    );
  }

  String _childFirstName(
    ChildProfileData child,
    int index,
  ) {
    final firstName = child.identity.firstName?.trim();

    if (firstName != null && firstName.isNotEmpty) {
      return firstName;
    }

    return 'Enfant ${index + 1}';
  }

  String _childHealthSummary(
    ChildProfileData child,
  ) {
    final information = <String>[];

    final pathologyNames = child.pathologies
        .map(
          (pathology) => pathology.name?.trim(),
        )
        .where(
          (name) => name != null && name.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (pathologyNames.isNotEmpty) {
      information.addAll(pathologyNames);
    }

    final allergyNames = child.allergies
        .map(
          (allergy) => allergy.allergen?.trim(),
        )
        .where(
          (allergen) =>
              allergen != null && allergen.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (allergyNames.length == 1) {
      information.add(
        'Allergie : ${allergyNames.first}',
      );
    } else if (allergyNames.length > 1) {
      information.add(
        'Allergies : ${allergyNames.join(', ')}',
      );
    }

    if (information.isEmpty) {
      return 'Aucune information de santé renseignée';
    }

    return information.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final children =
        ChildRepository.instance.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes enfants',
        ),
      ),
      body: SafeArea(
        child: children.isEmpty
            ? Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    const Icon(
                      Icons.child_care,
                      size: 72,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Vous n’avez encore aucun enfant enregistré.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 32),

                    FilledButton.icon(
                      onPressed: () =>
                          _openCreateProfile(
                        context,
                      ),
                      icon:
                          const Icon(Icons.add),
                      label: const Text(
                        'Créer le profil de mon enfant',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      style:
                          FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.all(24),
                children: [
                  for (
                    int index = 0;
                    index < children.length;
                    index++
                  ) ...[
                    Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.child_care,
                          ),
                        ),
                        title: Text(
                          _childFirstName(
                            children[index],
                            index,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              _childHealthSummary(
                                children[index],
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            const Text(
                              'Informations essentielles : complétées',
                            ),
                            const Text(
                              'Profil Activités : à compléter',
                            ),
                          ],
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'L’ouverture complète de la fiche sera ajoutée ensuite.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: () =>
                        _openCreateProfile(
                      context,
                    ),
                    icon:
                        const Icon(Icons.add),
                    label: const Text(
                      'Ajouter un enfant',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}