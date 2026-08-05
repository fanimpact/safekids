import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'trigger_factors_page.dart';

class MedicalEventsPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const MedicalEventsPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<MedicalEventsPage> createState() =>
      _MedicalEventsPageState();
}

class _MedicalEventsPageState extends State<MedicalEventsPage> {
  @override
  void initState() {
    super.initState();
    widget.transmissionController.ensureFirstMedicalEvent();
  }

  void _addMedicalEvent() {
    setState(() {
      widget.transmissionController.addMedicalEvent();
    });
  }

  void _removeMedicalEvent(int index) {
    setState(() {
      widget.transmissionController.removeMedicalEvent(index);
    });
  }

  void _updateEmergencyServicesCalled(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateEmergencyServicesCalled(index, value);
    });
  }

  void _updateHospitalized(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateHospitalized(index, value);
    });
  }

  void _updateImportantExaminationsPerformed(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateImportantExaminationsPerformed(index, value);
    });
  }

  void _updateHasOngoingConsequences(
    int index,
    bool value,
  ) {
    setState(() {
      widget.transmissionController
          .updateHasOngoingConsequences(index, value);
    });
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TriggerFactorsPage(
          transmissionController:
              widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicalEvents =
        widget.transmissionController.formData.medicalEvents;

    final primaryCareDoctor =
        widget.transmissionController.formData.primaryCareDoctor;

    return QuestionnairePage(
      title: "",
      subtitle:
          "Quels événements médicaux importants se sont déjà produits ?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            int index = 0;
            index < medicalEvents.length;
            index++
          ) ...[
            Text(
              "Événement n°${index + 1}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Résumez l’événement en une ou deux phrases maximum. "
              "Les secours doivent comprendre l’essentiel "
              "en quelques secondes.",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            SkTextField(
              label:
                  "Quel événement médical important s’est produit ?",
              controller: TextEditingController(
                text: medicalEvents[index].description ?? '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updateMedicalEventDescription(
                  index,
                  value,
                );
              },
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Date ou année approximative",
              controller: TextEditingController(
                text:
                    medicalEvents[index].approximateDate ?? '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updateMedicalEventDate(
                  index,
                  value,
                );
              },
            ),

            const SizedBox(height: 24),

            SkYesNoField(
              label: "Les secours sont-ils intervenus ?",
              value:
                  medicalEvents[index].emergencyServicesCalled,
              onChanged: (value) {
                _updateEmergencyServicesCalled(
                  index,
                  value,
                );
              },
            ),

            const SizedBox(height: 24),

            SkYesNoField(
              label: "L’enfant a-t-il été hospitalisé ?",
              value: medicalEvents[index].hospitalized,
              onChanged: (value) {
                _updateHospitalized(
                  index,
                  value,
                );
              },
            ),

            if (medicalEvents[index].hospitalized == true) ...[
              const SizedBox(height: 20),

              SkTextField(
                label:
                    "Durée de l’hospitalisation (facultatif)",
                controller: TextEditingController(
                  text: medicalEvents[index]
                          .hospitalizationDuration ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateHospitalizationDuration(
                    index,
                    value,
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  "Des examens médicaux importants ont-ils été réalisés ?",
              value: medicalEvents[index]
                  .importantExaminationsPerformed,
              onChanged: (value) {
                _updateImportantExaminationsPerformed(
                  index,
                  value,
                );
              },
            ),

            if (medicalEvents[index]
                    .importantExaminationsPerformed ==
                true) ...[
              const SizedBox(height: 20),

              SkTextField(
                label: "Lesquels ?",
                controller: TextEditingController(
                  text: medicalEvents[index]
                          .importantExaminations ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateImportantExaminations(
                    index,
                    value,
                  );
                },
              ),
            ],
                        const SizedBox(height: 24),

            SkYesNoField(
              label:
                  "Cet événement a-t-il laissé des conséquences médicales ?",
              value: medicalEvents[index]
                  .hasOngoingConsequences,
              onChanged: (value) {
                _updateHasOngoingConsequences(
                  index,
                  value,
                );
              },
            ),

            if (medicalEvents[index]
                    .hasOngoingConsequences ==
                true) ...[
              const SizedBox(height: 20),

              const Text(
                "Résumez uniquement les conséquences encore présentes aujourd'hui.",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 10),

              SkTextField(
                label: "Lesquelles ?",
                controller: TextEditingController(
                  text: medicalEvents[index]
                          .ongoingConsequences ??
                      '',
                ),
                onChanged: (value) {
                  widget.transmissionController
                      .updateOngoingConsequences(
                    index,
                    value,
                  );
                },
              ),
            ],

            if (medicalEvents.length > 1) ...[
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _removeMedicalEvent(index),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Supprimer"),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],

          OutlinedButton.icon(
            onPressed: _addMedicalEvent,
            icon: const Icon(Icons.add),
            label:
                const Text("Ajouter un événement médical"),
          ),

          const SizedBox(height: 40),

          const Divider(),

          const SizedBox(height: 30),

          const Text(
            "Médecin traitant",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SkTextField(
            label: "Nom du médecin traitant",
            controller: TextEditingController(
              text: primaryCareDoctor.name ?? '',
            ),
            onChanged: widget
                .transmissionController
                .updatePrimaryCareDoctorName,
          ),

          const SizedBox(height: 20),

          SkTextField(
            label: "Lieu d'exercice",
            controller: TextEditingController(
              text: primaryCareDoctor.workplace ?? '',
            ),
            onChanged: widget
                .transmissionController
                .updatePrimaryCareDoctorWorkplace,
          ),

          const SizedBox(height: 20),

          SkTextField(
            label: "Téléphone (facultatif)",
            controller: TextEditingController(
              text: primaryCareDoctor.phoneNumber ?? '',
            ),
            onChanged: widget
                .transmissionController
                .updatePrimaryCareDoctorPhone,
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