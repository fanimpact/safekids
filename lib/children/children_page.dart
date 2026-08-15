import 'package:flutter/material.dart';

import '../child_profile_pages/create_child_profile_intro_page.dart';
import '../controllers/transmission_controller.dart';
import '../models/complete_child_profile_data.dart';
import '../repositories/child_repository.dart';
import '../transmission_pages/identity_page.dart';
import '../utils/child_name_utils.dart';
import 'child_profile_page.dart';

class ChildrenPage extends StatelessWidget {
  const ChildrenPage({
    super.key,
  });

  void _openFirstChildProfile(
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

  void _openAnotherChildProfile(
    BuildContext context,
  ) {
    final transmissionController =
        TransmissionController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdentityPage(
          transmissionController:
              transmissionController,
        ),
      ),
    );
  }

  void _openChildProfile(
    BuildContext context,
    CompleteChildProfileData child,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildProfilePage(
          child: child,
        ),
      ),
    );
  }

  String _childDisplayName(
    CompleteChildProfileData child,
    int index,
  ) {
    return childFullName(
      child.essentialInformation.identity,
      fallback: 'Enfant ${index + 1}',
    );
  }

  String _childHealthSummary(
    CompleteChildProfileData child,
  ) {
    final essentialInformation =
        child.essentialInformation;

    final information = <String>[];

    final pathologyNames = essentialInformation.pathologies
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

    final allergyNames = essentialInformation.allergies
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

  Widget _buildCompletionLine({
    required bool completed,
    required String completedText,
    required String incompleteText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          completed
              ? Icons.check_circle
              : Icons.hourglass_top,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            completed
                ? completedText
                : incompleteText,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard({
    required BuildContext context,
    required CompleteChildProfileData child,
    required int index,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: const CircleAvatar(
            child: Icon(
              Icons.child_care,
            ),
          ),
          title: Text(
            _childDisplayName(
              child,
              index,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(
              top: 6,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _childHealthSummary(child),
                ),
                const SizedBox(height: 12),
                _buildCompletionLine(
                  completed:
                      child.essentialInformationCompleted,
                  completedText:
                      'Informations essentielles : complétées',
                  incompleteText:
                      'Informations essentielles : à compléter',
                ),
                const SizedBox(height: 6),
                _buildCompletionLine(
                  completed:
                      child.activityProfileCompleted,
                  completedText:
                      'Profil Activités : complété',
                  incompleteText:
                      'Profil Activités : à compléter',
                ),
              ],
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () => _openChildProfile(
            context,
            child,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () =>
                _openFirstChildProfile(context),
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Créer le profil de mon enfant',
              style: TextStyle(
                fontSize: 17,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 18,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildChildrenList(
    BuildContext context,
    List<CompleteChildProfileData> children,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (
          int index = 0;
          index < children.length;
          index++
        ) ...[
          _buildChildCard(
            context: context,
            child: children[index],
            index: index,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () =>
              _openAnotherChildProfile(context),
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            'Créer un autre profil enfant',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Revenir sur cette page (ex. après une suppression) ne la
    // reconstruit pas automatiquement de lui-même côté Flutter : sans
    // ça, elle continuerait d'afficher une liste figée au moment où
    // elle a été ouverte, même si un enfant vient d'être supprimé ou
    // ajouté entre-temps.
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) {
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
                ? _buildEmptyState(context)
                : _buildChildrenList(
                    context,
                    children,
                  ),
          ),
        );
      },
    );
  }
}