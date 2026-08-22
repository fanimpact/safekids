import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../models/allergy_data.dart';
import '../utils/allergy_category_labels.dart';
import '../utils/text_controller_cache.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'medical_events_page.dart';

class DiagnosedPathologiesPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const DiagnosedPathologiesPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<DiagnosedPathologiesPage> createState() =>
      _DiagnosedPathologiesPageState();
}

class _DiagnosedPathologiesPageState
    extends State<DiagnosedPathologiesPage> {
  bool? _hasPathologies;
  bool? _hasAllergies;

  final _controllers = TextControllerCache();

  @override
  void initState() {
    super.initState();

    final draft = widget.transmissionController.formData;

    // La réponse explicite (Oui/Non) est prioritaire : elle seule
    // permet de distinguer "Non" de "jamais répondu". Les profils
    // enregistrés avant l'ajout de ce champ n'ont que la liste : on
    // déduit alors "Oui" si elle contient déjà des éléments.
    _hasPathologies = draft.hasPathologies ??
        (draft.pathologies.isNotEmpty ? true : null);

    _hasAllergies = draft.hasAllergies ??
        (draft.allergies.isNotEmpty ? true : null);
  }

  @override
  void dispose() {
    _controllers.disposeAll();
    super.dispose();
  }

  void _updateHasPathologies(bool value) {
    setState(() {
      _hasPathologies = value;

      widget.transmissionController.updateHasPathologies(value);

      if (value) {
        widget.transmissionController.ensureFirstPathology();
      } else {
        widget.transmissionController.clearPathologies();
      }
    });
  }

  void _updateHasAllergies(bool value) {
    setState(() {
      _hasAllergies = value;

      widget.transmissionController.updateHasAllergies(value);

      if (value) {
        widget.transmissionController.ensureFirstAllergy();
      } else {
        widget.transmissionController.clearAllergies();
      }
    });
  }

  void _addPathology() {
    setState(() {
      widget.transmissionController.addPathology();
    });
  }

  void _removePathology(int index) {
    setState(() {
      widget.transmissionController.removePathology(index);
    });
  }

  void _updateHasReferringProfessional(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateHasReferringProfessional(index, value);
    });
  }

  void _addAllergy() {
    setState(() {
      widget.transmissionController.addAllergy();
    });
  }

  void _removeAllergy(int index) {
    setState(() {
      widget.transmissionController.removeAllergy(index);
    });
  }

  void _addPathologyEmergencyStep(int pathologyIndex) {
    setState(() {
      widget.transmissionController
          .addPathologyEmergencyStep(pathologyIndex);
    });
  }

  void _removePathologyEmergencyStep(
    int pathologyIndex,
    int stepIndex,
  ) {
    setState(() {
      widget.transmissionController
          .removePathologyEmergencyStep(
        pathologyIndex,
        stepIndex,
      );
    });
  }

  void _addAllergyEmergencyStep(int allergyIndex) {
    setState(() {
      widget.transmissionController
          .addAllergyEmergencyStep(allergyIndex);
    });
  }

  void _removeAllergyEmergencyStep(
    int allergyIndex,
    int stepIndex,
  ) {
    setState(() {
      widget.transmissionController
          .removeAllergyEmergencyStep(
        allergyIndex,
        stepIndex,
      );
    });
  }

  Widget _buildEmergencyStepsSection({
    required String label,
    required String controllerKeyPrefix,
    required List<String> steps,
    required VoidCallback onAddStep,
    required void Function(int stepIndex) onRemoveStep,
    required void Function(
      int stepIndex,
      String value,
    ) onUpdateStep,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Exemple (à titre indicatif, à ne pas recopier)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "1. Mettre en position latérale de sécurité\n"
                "2. Déclencher un chronomètre\n"
                "3. Donner le traitement d'urgence après le délai indiqué",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        for (
          int stepIndex = 0;
          stepIndex < steps.length;
          stepIndex++
        ) ...[
          const SizedBox(height: 16),

          SkTextField(
            label: "Étape ${stepIndex + 1}",
            controller: _controllers.of(
              '${controllerKeyPrefix}_emergencyStep_$stepIndex',
              steps[stepIndex],
            ),
            onChanged: (value) =>
                onUpdateStep(stepIndex, value),
            // La touche Entrée ne doit rien déclencher d'autre
            // (notamment pas ajouter une nouvelle étape).
            onFieldSubmitted: (_) {},
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  onRemoveStep(stepIndex),
              icon: const Icon(
                  Icons.delete_outline),
              label: const Text(
                  "Supprimer cette étape"),
            ),
          ),
        ],

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: onAddStep,
          icon: const Icon(Icons.add),
          label: const Text("Ajouter une étape"),
        ),
      ],
    );
  }

  /// Remplace l'ancien champ unique "À quoi votre enfant est-il
  /// allergique ?" : le type est coché, et c'est sa sous-question qui
  /// porte la précision. Un seul endroit de saisie par information,
  /// donc — le parent ne redit pas dans un champ libre ce que la case
  /// dit déjà.
  ///
  /// Le type conditionne l'endroit où l'allergie ressort : une
  /// allergie alimentaire remonte au moment du repas (voir
  /// `AllergyData.concernsMeals`).
  Widget _buildAllergyCategories(
    int index,
    AllergyData allergy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "De quel type est cette allergie ?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        for (final category in AllergyCategory.values) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              allergyCategoryLabels[category]!,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            value: allergy.categories.contains(category),
            onChanged: (value) {
              setState(() {
                widget.transmissionController
                    .updateAllergyCategory(
                  index,
                  category,
                  value ?? false,
                );
              });
            },
          ),

          if (allergy.categories.contains(category)) ...[
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                bottom: 8,
              ),
              child: SkTextField(
                label: allergyDetailLabels[category]!,
                controller: _controllers.of(
                  '${allergy.allergyId}_detail_${category.name}',
                  allergy.details[category] ?? '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateAllergyDetail(
                    index,
                    category,
                    value,
                  );
                },
                maxLength: 100,
                helperText:
                    "Réponse courte recommandée (quelques mots ou une phrase courte).",
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _continue() {
    if (_hasPathologies == null || _hasAllergies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Répondez aux questions sur les pathologies et les allergies.",
          ),
        ),
      );
      return;
    }

    final draft = widget.transmissionController.formData;

    final hasUnansweredPathology = _hasPathologies == true &&
        draft.pathologies.any(
          (pathology) => pathology.hasReferringProfessional == null,
        );

    // Le nom est ce qui fait exister la pathologie sur les fiches :
    // sans lui, elle est sautée par le moteur comme par les deux
    // fiches de référence (voir HealthConditionsRules). Elle serait
    // donc enregistrée et affichée nulle part — un silence bien plus
    // dangereux qu'un blocage de saisie (arbitrage Fanny du
    // 22/08/2026).
    final hasUnnamedPathology = _hasPathologies == true &&
        draft.pathologies.any(
          (pathology) => (pathology.name ?? '').trim().isEmpty,
        );

    if (hasUnnamedPathology) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Nommez chaque pathologie avant de continuer.",
          ),
        ),
      );
      return;
    }

    // Le type conditionne l'endroit où l'allergie ressort sur les
    // fiches (une allergie alimentaire remonte au moment du repas) :
    // une allergie sans type cochée n'est donc pas exploitable, d'où
    // l'obligation — même exigence que les Oui/Non ailleurs dans les
    // questionnaires.
    final hasUntypedAllergy = _hasAllergies == true &&
        draft.allergies.any(
          (allergy) => allergy.categories.isEmpty,
        );

    if (hasUntypedAllergy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Indiquez le type de chaque allergie avant de continuer.",
          ),
        ),
      );
      return;
    }

    // Même raison que le nom de la pathologie : c'est la précision du
    // type coché qui compose le libellé affiché (`AllergyData.label`).
    // Un type coché sans précision donne un libellé vide, et
    // l'allergie disparaît de toutes les fiches sans que rien ne le
    // signale.
    final hasCategoryWithoutDetail = _hasAllergies == true &&
        draft.allergies.any(
          (allergy) => allergy.categories.any(
            (category) =>
                (allergy.details[category] ?? '').trim().isEmpty,
          ),
        );

    if (hasCategoryWithoutDetail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Précisez chaque type d'allergie coché avant de continuer.",
          ),
        ),
      );
      return;
    }

    if (hasUnansweredPathology) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Répondez par oui ou par non à chaque question avant de continuer.",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalEventsPage(
          transmissionController:
              widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.transmissionController.formData;
    final pathologies = draft.pathologies;
    final allergies = draft.allergies;

    return QuestionnairePage(
      title: "",
      subtitle: "Santé de votre enfant",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Pathologies diagnostiquées",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                "Votre enfant présente-t-il une ou plusieurs pathologies diagnostiquées par un professionnel de santé ?",
            value: _hasPathologies,
            onChanged: _updateHasPathologies,
          ),

          if (_hasPathologies == true) ...[
            const SizedBox(height: 28),

            for (
              int index = 0;
              index < pathologies.length;
              index++
            ) ...[
              Text(
                "Pathologie n°${index + 1}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              SkTextField(
                label: "Nom de la pathologie",
                controller: _controllers.of(
                  '${pathologies[index].pathologyId}_name',
                  pathologies[index].name ?? '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updatePathologyName(index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label:
                    "Date ou année approximative du diagnostic",
                controller: _controllers.of(
                  '${pathologies[index].pathologyId}_diagnosisDate',
                  pathologies[index]
                          .approximateDiagnosisDate ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updatePathologyDiagnosisDate(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(height: 24),

              SkYesNoField(
                label:
                    "Cette pathologie est-elle suivie par un professionnel de santé référent ?",
                value: pathologies[index]
                    .hasReferringProfessional,
                onChanged: (value) {
                  _updateHasReferringProfessional(
                    index,
                    value,
                  );
                },
              ),
              if (pathologies[index]
                      .hasReferringProfessional ==
                  true) ...[
                const SizedBox(height: 20),

                SkTextField(
                  label: "Nom du professionnel référent",
                  controller: _controllers.of(
                    '${pathologies[index].pathologyId}_professionalName',
                    pathologies[index]
                            .referringProfessional
                            ?.name ??
                        '',
                  ),
                  onChanged: (value) {
                    widget.transmissionController
                        .updateProfessionalName(
                            index, value);
                  },
                ),

                const SizedBox(height: 20),

                SkTextField(
                  label: "Spécialité",
                  controller: _controllers.of(
                    '${pathologies[index].pathologyId}_professionalSpecialty',
                    pathologies[index]
                            .referringProfessional
                            ?.specialty ??
                        '',
                  ),
                  onChanged: (value) {
                    widget.transmissionController
                        .updateProfessionalSpecialty(
                            index, value);
                  },
                ),

                const SizedBox(height: 20),

                SkTextField(
                  label: "Lieu d'exercice",
                  controller: _controllers.of(
                    '${pathologies[index].pathologyId}_professionalWorkplace',
                    pathologies[index]
                            .referringProfessional
                            ?.workplace ??
                        '',
                  ),
                  onChanged: (value) {
                    widget.transmissionController
                        .updateProfessionalWorkplace(
                            index, value);
                  },
                ),

                const SizedBox(height: 20),

                SkTextField(
                  label:
                      "Téléphone (facultatif)",
                  controller: _controllers.of(
                    '${pathologies[index].pathologyId}_professionalPhone',
                    pathologies[index]
                            .referringProfessional
                            ?.phoneNumber ??
                        '',
                  ),
                  onChanged: (value) {
                    widget.transmissionController
                        .updateProfessionalPhone(
                            index, value);
                  },
                ),
              ],

              _buildEmergencyStepsSection(
                label:
                    "Que faire en cas d'urgence liée à cette pathologie ? (facultatif)",
                controllerKeyPrefix:
                    pathologies[index].pathologyId,
                steps: pathologies[index]
                    .emergencyInstructionSteps,
                onAddStep: () =>
                    _addPathologyEmergencyStep(index),
                onRemoveStep: (stepIndex) =>
                    _removePathologyEmergencyStep(
                  index,
                  stepIndex,
                ),
                onUpdateStep: (stepIndex, value) {
                  widget.transmissionController
                      .updatePathologyEmergencyStep(
                    index,
                    stepIndex,
                    value,
                  );
                },
              ),

              if (pathologies.length > 1) ...[
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _removePathology(index),
                    icon: const Icon(
                        Icons.delete_outline),
                    label:
                        const Text("Supprimer"),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],

            OutlinedButton.icon(
              onPressed: _addPathology,
              icon: const Icon(Icons.add),
              label: const Text(
                  "Ajouter une pathologie"),
            ),
          ],

          const SizedBox(height: 40),

          const Divider(),

          const SizedBox(height: 30),

          const Text(
            "Allergies importantes",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                "Votre enfant présente-t-il une ou plusieurs allergies nécessitant une vigilance particulière ?",
            value: _hasAllergies,
            onChanged: _updateHasAllergies,
          ),

          if (_hasAllergies == true) ...[
            const SizedBox(height: 28),

            for (
              int index = 0;
              index < allergies.length;
              index++
            ) ...[
              Text(
                "Allergie n°${index + 1}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildAllergyCategories(
                index,
                allergies[index],
              ),

              const SizedBox(height: 20),

              SkTextField(
                label:
                    "Réaction déjà observée",
                controller: _controllers.of(
                  '${allergies[index].allergyId}_observedReaction',
                  allergies[index]
                          .observedReaction ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateAllergyObservedReaction(
                          index, value);
                },
              ),

              _buildEmergencyStepsSection(
                label:
                    "Que faire en cas d'urgence liée à cette allergie ? (facultatif)",
                controllerKeyPrefix:
                    allergies[index].allergyId,
                steps: allergies[index]
                    .emergencyInstructionSteps,
                onAddStep: () =>
                    _addAllergyEmergencyStep(index),
                onRemoveStep: (stepIndex) =>
                    _removeAllergyEmergencyStep(
                  index,
                  stepIndex,
                ),
                onUpdateStep: (stepIndex, value) {
                  widget.transmissionController
                      .updateAllergyEmergencyStep(
                    index,
                    stepIndex,
                    value,
                  );
                },
              ),

              if (allergies.length > 1) ...[
                const SizedBox(height: 12),

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _removeAllergy(index),
                    icon: const Icon(
                        Icons.delete_outline),
                    label:
                        const Text("Supprimer"),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],

            OutlinedButton.icon(
              onPressed: _addAllergy,
              icon: const Icon(Icons.add),
              label: const Text(
                  "Ajouter une allergie"),
            ),
          ],
                    const SizedBox(height: 30),

          FilledButton(
            onPressed: _continue,
            child: const Text("Continuer"),
          ),
        ],
      ),
    );
  }
}