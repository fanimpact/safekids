
import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';

class ChildProfilePage extends StatelessWidget {
  final CompleteChildProfileData child;

  const ChildProfilePage({
    super.key,
    required this.child,
  });

  String get _firstName {
    final value = child
        .essentialInformation
        .identity
        .firstName;

    if (value == null || value.trim().isEmpty) {
      return "Enfant";
    }

    return value;
  }

  String get _age {
    // L'âge sera calculé automatiquement
    // à partir de la date de naissance
    // dans une prochaine étape.
    return "";
  }

  List<String> get _pathologies {
    final values = child
        .essentialInformation
        .pathologies
        .map(
          (e) => e.name?.trim(),
        )
        .where(
          (e) => e != null && e.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ["Aucune"];
    }

    return values;
  }

  List<String> get _allergies {
    final values = child
        .essentialInformation
        .allergies
        .map(
          (e) => e.allergen?.trim(),
        )
        .where(
          (e) => e != null && e.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ["Aucune"];
    }

    return values;
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bulletList(
    List<String> values,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: values
          .map(
            (value) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 6,
              ),
              child: Text(
                "• $value",
                style:
                    const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
    Widget _statusLine({
    required bool completed,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          completed
              ? Icons.check_circle
              : Icons.hourglass_top,
          color: completed
              ? Colors.green
              : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(alpha: 0.15),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onPressed,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _firstName,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(
            24,
          ),
          children: [
            const Icon(
              Icons.child_care,
              size: 72,
            ),

            const SizedBox(
              height: 20,
            ),

            Center(
              child: Text(
                _firstName,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            if (_age.isNotEmpty) ...[
              const SizedBox(
                height: 6,
              ),
              Center(
                child: Text(
                  _age,
                  style:
                      const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              "Pathologies",
            ),

            _bulletList(
              _pathologies,
            ),

            const SizedBox(
              height: 24,
            ),

            _sectionTitle(
              "Allergies",
            ),

            _bulletList(
              _allergies,
            ),

            const SizedBox(
              height: 36,
            ),
                        _sectionTitle(
              "Utiliser ce profil",
            ),

            _actionButton(
              icon: Icons.event,
              color: Colors.blue,
              title:
                  "Préparer une activité",
              subtitle:
                  "Créer une préparation adaptée à cet enfant.",
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "La préparation des activités sera reliée ici.",
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.warning,
              color: Colors.red,
              title: "Mode Urgence",
              subtitle:
                  "Accéder immédiatement au protocole d'urgence.",
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Le Mode Urgence sera relié ici.",
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.description,
              color: Colors.green,
              title:
                  "Informations pour les secours",
              subtitle:
                  "Afficher la fiche destinée aux services de secours.",
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "La fiche de transmission sera reliée ici.",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 36,
            ),

            _sectionTitle(
              "État du profil",
            ),

            _statusLine(
              completed: child
                  .essentialInformationCompleted,
              title:
                  "Informations essentielles : complétées",
            ),

            const SizedBox(
              height: 12,
            ),

            _statusLine(
              completed: child
                  .activityProfileCompleted,
              title:
                  "Profil Activités : complété",
            ),

            const SizedBox(
              height: 36,
            ),
                        _sectionTitle(
              "Partages",
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.people,
                  ),
                ),
                title: const Text(
                  "Aucun partage actif",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Vous pourrez partager le profil de votre enfant avec les personnes de votre choix.",
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "La gestion des partages sera ajoutée prochainement.",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 36,
            ),

            _sectionTitle(
              "Modifier le profil",
            ),

            _actionButton(
              icon: Icons.edit_document,
              color: Colors.orange,
              title:
                  "Informations essentielles",
              subtitle:
                  "Modifier les informations destinées aux secours.",
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "La modification des informations essentielles sera reliée ici.",
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.edit,
              color: Colors.deepPurple,
              title:
                  "Profil Activités",
              subtitle:
                  "Modifier les informations utilisées pour préparer les activités.",
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "La modification du profil Activités sera reliée ici.",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 36,
            ),
                        _sectionTitle(
              "Gestion",
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.delete,
                  ),
                ),
                title: const Text(
                  "Supprimer le profil",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Cette action supprimera définitivement le profil de cet enfant.",
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "La suppression du profil sera ajoutée ultérieurement.",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}