import 'package:flutter/material.dart';

import '../activity_pages/activities_home_page.dart';
import '../activity_profile_pages/activity_profile_entry_page.dart';
import '../care_info/care_info_sheet_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../controllers/transmission_controller.dart';
import '../emergency_info/emergency_info_sheet_page.dart';
import '../emergency_mode/emergency_mode_button_list_page.dart';
import '../models/activity_profile_draft.dart';
import '../models/child_profile_draft.dart';
import '../models/complete_child_profile_data.dart';
import '../questionnaire_recap/activity_questionnaire_recap_page.dart';
import '../questionnaire_recap/medical_questionnaire_recap_page.dart';
import '../transmission_pages/identity_page.dart';
import '../utils/age_utils.dart';
import '../utils/child_name_utils.dart';

class ChildProfilePage extends StatelessWidget {
  final CompleteChildProfileData child;

  const ChildProfilePage({
    super.key,
    required this.child,
  });

  String get _displayName {
    return childFullName(
      child.essentialInformation.identity,
    );
  }

  String get _age {
    return formatAge(
          child
              .essentialInformation
              .identity
              .dateOfBirth,
        ) ??
        '';
  }

  List<String> get _pathologies {
    final values = child
        .essentialInformation
        .pathologies
        .map(
          (pathology) => pathology.name?.trim(),
        )
        .where(
          (name) => name != null && name.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ['Aucune'];
    }

    return values;
  }

  List<String> get _allergies {
    final values = child
        .essentialInformation
        .allergies
        .map(
          (allergy) => allergy.allergen?.trim(),
        )
        .where(
          (allergen) =>
              allergen != null && allergen.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ['Aucune'];
    }

    return values;
  }

  void _openActivities(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesHomePage(
          selectedChild: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.only(
                bottom: 6,
              ),
              child: Text(
                value,
                style: const TextStyle(
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
    required String completedText,
    required String incompleteText,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
            completed
                ? completedText
                : incompleteText,
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
            fontWeight: FontWeight.bold,
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

  void _openActivityProfile(BuildContext context) {
    final existingProfile = child.activityProfile;

    final activityProfileController = ActivityProfileController(
      initialDraft: existingProfile == null
          ? ActivityProfileDraft(
              userId: child.userId,
              childId: child.childId,
            )
          : ActivityProfileDraft.fromActivityProfileData(
              existingProfile,
              userId: child.userId,
              childId: child.childId,
            ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProfileEntryPage(
          activityProfileController: activityProfileController,
        ),
      ),
    );
  }

  void _showTemporaryMessage({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
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
          _displayName,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.child_care,
              size: 72,
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_age.isNotEmpty) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _age,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            _sectionTitle(
              'Pathologies',
            ),

            _bulletList(
              _pathologies,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              'Allergies',
            ),

            _bulletList(
              _allergies,
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'Utiliser ce profil',
            ),

            _actionButton(
              icon: Icons.event,
              color: Colors.blue,
              title: 'Préparer une activité',
              subtitle:
                  'Créer une préparation adaptée à cet enfant.',
              onPressed: () =>
                  _openActivities(context),
            ),

            _actionButton(
              icon: Icons.warning,
              color: Colors.red,
              title: 'Mode Urgence',
              subtitle:
                  'Accéder immédiatement au protocole d’urgence.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyModeButtonListPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.description,
              color: Colors.green,
              title:
                  'Informations pour les secours',
              subtitle:
                  'Afficher la fiche destinée aux services de secours.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyInfoSheetPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.fact_check_outlined,
              color: Colors.teal,
              title:
                  'Questionnaire santé (récapitulatif)',
              subtitle:
                  'Voir et imprimer toutes les questions et réponses du questionnaire santé.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MedicalQuestionnaireRecapPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.checklist_rtl,
              color: Colors.indigo,
              title:
                  'Questionnaire activité (récapitulatif)',
              subtitle:
                  'Voir et imprimer toutes les questions et réponses du profil Activités.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ActivityQuestionnaireRecapPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.family_restroom,
              color: Colors.brown,
              title: "Ce qu'il faut savoir sur $_displayName",
              subtitle:
                  'Informations à connaître pour un accompagnement de plusieurs jours (ex. grands-parents).',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CareInfoSheetPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'État du profil',
            ),

            _statusLine(
              completed:
                  child.essentialInformationCompleted,
              completedText:
                  'Informations essentielles : complétées',
              incompleteText:
                  'Informations essentielles : à compléter',
            ),

            const SizedBox(height: 12),

            _statusLine(
              completed:
                  child.activityProfileCompleted,
              completedText:
                  'Profil Activités : complété',
              incompleteText:
                  'Profil Activités : à compléter',
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'Partages',
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.people,
                  ),
                ),
                title: const Text(
                  'Aucun partage actif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Vous pourrez partager le profil de votre enfant avec les personnes de votre choix.',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showTemporaryMessage(
                    context: context,
                    message:
                        'La gestion des partages sera ajoutée prochainement.',
                  );
                },
              ),
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'Modifier le profil',
            ),

            _actionButton(
              icon: Icons.edit_document,
              color: Colors.orange,
              title:
                  'Informations essentielles',
              subtitle:
                  'Modifier les informations destinées aux secours.',
              onPressed: () {
                final transmissionController =
                    TransmissionController(
                  initialDraft:
                      ChildProfileDraft.fromChildProfileData(
                    child.essentialInformation,
                  ),
                  isEditing: true,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IdentityPage(
                      transmissionController:
                          transmissionController,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.edit,
              color: Colors.deepPurple,
              title: 'Profil Activités',
              subtitle:
                  'Modifier les informations utilisées pour préparer les activités.',
              onPressed: () => _openActivityProfile(context),
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'Gestion',
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.delete,
                  ),
                ),
                title: const Text(
                  'Supprimer le profil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Cette action supprimera définitivement le profil de cet enfant.',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showTemporaryMessage(
                    context: context,
                    message:
                        'La suppression du profil sera ajoutée ultérieurement.',
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
