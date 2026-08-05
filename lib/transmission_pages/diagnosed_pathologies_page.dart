import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
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

  @override
  void initState() {
    super.initState();

    final draft = widget.transmissionController.formData;

    if (draft.pathologies.isNotEmpty) {
      _hasPathologies = true;
    }

    if (draft.allergies.isNotEmpty) {
      _hasAllergies = true;
    }
  }

  void _updateHasPathologies(bool value) {
    setState(() {
      _hasPathologies = value;

      if (value) {
        widget.transmissionController.ensureFirstPathology();
      } else {
        widget.transmissionController.formData.pathologies.clear();
      }
    });
  }

  void _updateHasAllergies(bool value) {
    setState(() {
      _hasAllergies = value;

      if (value) {
        widget.transmissionController.ensureFirstAllergy();
      } else {
        widget.transmissionController.formData.allergies.clear();
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
                controller: TextEditingController(
                  text: pathologies[index].name ?? '',
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
                controller: TextEditingController(
                  text: pathologies[index]
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
                  .hasReferringProfessional) ...[
                const SizedBox(height: 20),

                SkTextField(
                  label: "Nom du professionnel référent",
                  controller: TextEditingController(
                    text: pathologies[index]
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
                  controller: TextEditingController(
                    text: pathologies[index]
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
                  controller: TextEditingController(
                    text: pathologies[index]
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
                  controller: TextEditingController(
                    text: pathologies[index]
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

              SkTextField(
                label:
                    "À quoi votre enfant est-il allergique ?",
                controller: TextEditingController(
                  text: allergies[index]
                          .allergen ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateAllergen(
                          index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label:
                    "Réaction déjà observée",
                controller: TextEditingController(
                  text: allergies[index]
                          .observedReaction ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateAllergyObservedReaction(
                          index, value);
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