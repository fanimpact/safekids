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
  @override
  void initState() {
    super.initState();
    widget.transmissionController.ensureFirstPathology();
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

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalEventsPage(
          transmissionController: widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pathologies =
        widget.transmissionController.formData.pathologies;

    return QuestionnairePage(
      title: "",
      subtitle:
          "Quelle pathologie a été diagnostiquée par un professionnel de santé ?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                text:
                    pathologies[index].approximateDiagnosisDate ??
                        '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updatePathologyDiagnosisDate(index, value);
              },
            ),

            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  "Cette pathologie est-elle suivie par un professionnel de santé référent ?",
              value:
                  pathologies[index].hasReferringProfessional,
              onChanged: (value) {
                _updateHasReferringProfessional(index, value);
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
                      .updateProfessionalName(index, value);
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
                      .updateProfessionalSpecialty(index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label: "Lieu d’exercice",
                controller: TextEditingController(
                  text: pathologies[index]
                          .referringProfessional
                          ?.workplace ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateProfessionalWorkplace(index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label: "Numéro de téléphone (facultatif)",
                controller: TextEditingController(
                  text: pathologies[index]
                          .referringProfessional
                          ?.phoneNumber ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateProfessionalPhone(index, value);
                },
              ),
            ],

            if (pathologies.length > 1) ...[
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removePathology(index),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Supprimer"),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],

          OutlinedButton.icon(
            onPressed: _addPathology,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter une pathologie"),
          ),

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