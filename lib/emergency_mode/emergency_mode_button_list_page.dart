import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import 'emergency_mode_instructions_page.dart';

const String _noStepsMessage =
    'Aucune consigne particulière renseignée par le parent — appelez les secours.';

const String _otherEmergencyMessage =
    'Mettez l’enfant en sécurité et appelez les secours (15 ou 112).';

/// Menu du Mode Urgence pour un enfant : un bouton par pathologie et par
/// allergie renseignées dans son profil, plus un bouton "Autre urgence"
/// toujours présent. Chaque bouton mène à la consigne préparée à
/// l'avance par le parent pour cette situation précise.
class EmergencyModeButtonListPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const EmergencyModeButtonListPage({
    super.key,
    required this.child,
  });

  String get _displayName {
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

  void _openInstructions(
    BuildContext context, {
    required String title,
    required List<String> steps,
    required String emptyMessage,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmergencyModeInstructionsPage(
          title: title,
          steps: steps,
          emptyMessage: emptyMessage,
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            alignment: Alignment.centerLeft,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pathologies = child.essentialInformation
        .pathologies
        .where(
          (pathology) =>
              pathology.name != null &&
              pathology.name!.trim().isNotEmpty,
        )
        .toList();

    final allergies = child.essentialInformation
        .allergies
        .where(
          (allergy) =>
              allergy.allergen != null &&
              allergy.allergen!.trim().isNotEmpty,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mode Urgence — $_displayName'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Quelle est la situation ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            for (final pathology in pathologies)
              _buildButton(
                context: context,
                icon: Icons.medical_information_outlined,
                label:
                    'Urgence liée à : ${pathology.name!.trim()}',
                onPressed: () => _openInstructions(
                  context,
                  title:
                      'Urgence liée à : ${pathology.name!.trim()}',
                  steps:
                      pathology.emergencyInstructionSteps,
                  emptyMessage: _noStepsMessage,
                ),
              ),

            for (final allergy in allergies)
              _buildButton(
                context: context,
                icon: Icons.warning_amber_rounded,
                label:
                    'Urgence liée à : Allergie (${allergy.allergen!.trim()})',
                onPressed: () => _openInstructions(
                  context,
                  title:
                      'Urgence liée à : Allergie (${allergy.allergen!.trim()})',
                  steps:
                      allergy.emergencyInstructionSteps,
                  emptyMessage: _noStepsMessage,
                ),
              ),

            _buildButton(
              context: context,
              icon: Icons.help_outline,
              label: 'Autre urgence',
              onPressed: () => _openInstructions(
                context,
                title: 'Autre urgence',
                steps: const [],
                emptyMessage: _otherEmergencyMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
