import 'package:flutter/material.dart';

import '../models/emergency_treatment_data.dart';
import '../utils/emergency_treatment_step.dart';

/// Écran générique de consigne pour le Mode Urgence : affiche soit une
/// liste d'étapes numérotées automatiquement (préparées à l'avance par
/// le parent pour une pathologie/allergie précise), soit un message
/// unique (pas de consigne renseignée, ou cas "Autre urgence").
///
/// Corrigé (19/08/2026) : le traitement d'urgence rattaché à une étape
/// (nom, dosage, condition, mode d'administration) s'affiche
/// directement sous cette étape — au moment où l'accompagnant en a
/// besoin, pas dans un coin de l'écran. Un traitement lié à la
/// situation mais sans étape précisée s'affiche quand même, dans un
/// bloc après la liste (filet de sécurité : rien ne doit jamais rester
/// invisible pendant une crise). `unattachedTreatments` sert aussi au
/// cas "Autre urgence", qui liste alors tous les traitements du
/// profil à titre informatif.
class EmergencyModeInstructionsPage extends StatelessWidget {
  final String title;
  final List<String> steps;
  final String emptyMessage;
  final Map<int, List<EmergencyTreatmentData>>
      treatmentsByStepIndex;
  final List<EmergencyTreatmentData> unattachedTreatments;

  /// Sur "Autre urgence", les traitements listés ne sont pas rattachés
  /// à une situation précise : le libellé du bloc et son ton
  /// (informatif, "voici ce qui existe", pas "faites ceci") changent en
  /// conséquence.
  final bool isGenericFallback;

  const EmergencyModeInstructionsPage({
    super.key,
    required this.title,
    required this.steps,
    required this.emptyMessage,
    this.treatmentsByStepIndex = const {},
    this.unattachedTreatments = const [],
    this.isGenericFallback = false,
  });

  List<String> get _nonEmptySteps {
    return steps
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();
  }

  Widget _buildTreatmentBlock(
    List<EmergencyTreatmentData> treatments,
  ) {
    if (treatments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final treatment in treatments)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                emergencyTreatmentDetailLine(treatment),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _nonEmptySteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Urgence'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (steps.isEmpty)
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                      ),
                    )
                  else
                    for (var index = 0;
                        index < steps.length;
                        index++) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: Text(
                          '${index + 1}. ${steps[index]}',
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: _buildTreatmentBlock(
                          treatmentsByStepIndex[index] ??
                              const [],
                        ),
                      ),
                    ],

                  if (unattachedTreatments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      isGenericFallback
                          ? 'Traitements d’urgence renseignés '
                              'dans le profil'
                          : 'Traitement à disposition pour '
                              'cette urgence',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTreatmentBlock(
                      unattachedTreatments,
                    ),
                  ],
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.red.shade700,
              child: const Text(
                'Appelez les secours (15 ou 112)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
