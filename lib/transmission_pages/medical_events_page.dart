import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../utils/text_controller_cache.dart';
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
  final _controllers = TextControllerCache();

  @override
  void initState() {
    super.initState();
    widget.transmissionController.ensureFirstMedicalEvent();
    widget.transmissionController
        .ensureFirstMedicalObservation();
  }

  @override
  void dispose() {
    _controllers.disposeAll();
    super.dispose();
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

  void _addMedicalObservation() {
    setState(() {
      widget.transmissionController
          .addMedicalObservation();
    });
  }

  void _removeMedicalObservation(int index) {
    setState(() {
      widget.transmissionController
          .removeMedicalObservation(index);
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

    final medicalObservations = widget
        .transmissionController
        .formData
        .medicalObservations;

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
              controller: _controllers.of(
                'medicalEvent_${index}_description',
                medicalEvents[index].description ?? '',
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
              controller: _controllers.of(
                'medicalEvent_${index}_date',
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
                controller: _controllers.of(
                  'medicalEvent_${index}_hospitalizationDuration',
                  medicalEvents[index]
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
                controller: _controllers.of(
                  'medicalEvent_${index}_importantExaminations',
                  medicalEvents[index]
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
                controller: _controllers.of(
                  'medicalEvent_${index}_ongoingConsequences',
                  medicalEvents[index]
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
            "Observations médicales",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Un fait médical ponctuel, déjà examiné, mais qui ne "
            "nécessite pas de suivi actif (par exemple un souffle "
            "au cœur détecté sans conséquence identifiée).",
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          for (
            int index = 0;
            index < medicalObservations.length;
            index++
          ) ...[
            Text(
              "Observation n°${index + 1}",
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SkTextField(
              label: "Quel fait médical a été observé ?",
              controller: _controllers.of(
                'medicalObservation_${index}_description',
                medicalObservations[index].description ??
                    '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updateMedicalObservationDescription(
                  index,
                  value,
                );
              },
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Date ou période approximative",
              controller: _controllers.of(
                'medicalObservation_${index}_date',
                medicalObservations[index]
                        .approximateDate ??
                    '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updateMedicalObservationDate(
                  index,
                  value,
                );
              },
            ),

            const SizedBox(height: 20),

            SkTextField(
              label:
                  "Conclusion (ex. « Sans conséquence identifiée »)",
              controller: _controllers.of(
                'medicalObservation_${index}_conclusion',
                medicalObservations[index].conclusion ??
                    '',
              ),
              onChanged: (value) {
                widget.transmissionController
                    .updateMedicalObservationConclusion(
                  index,
                  value,
                );
              },
            ),

            if (medicalObservations.length > 1) ...[
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _removeMedicalObservation(index),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Supprimer"),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],

          OutlinedButton.icon(
            onPressed: _addMedicalObservation,
            icon: const Icon(Icons.add),
            label:
                const Text("Ajouter une observation"),
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
            controller: _controllers.of(
              'primaryCareDoctor_name',
              primaryCareDoctor.name ?? '',
            ),
            onChanged: widget
                .transmissionController
                .updatePrimaryCareDoctorName,
          ),

          const SizedBox(height: 20),

          SkTextField(
            label: "Lieu d'exercice",
            controller: _controllers.of(
              'primaryCareDoctor_workplace',
              primaryCareDoctor.workplace ?? '',
            ),
            onChanged: widget
                .transmissionController
                .updatePrimaryCareDoctorWorkplace,
          ),

          const SizedBox(height: 20),

          SkTextField(
            label: "Téléphone (facultatif)",
            controller: _controllers.of(
              'primaryCareDoctor_phone',
              primaryCareDoctor.phoneNumber ?? '',
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