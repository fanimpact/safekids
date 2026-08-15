import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../utils/date_format_utils.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_number_field.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'diagnosed_pathologies_page.dart';
import 'medical_events_page.dart';

class IdentityPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const IdentityPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  DateTime? _dateOfBirth;
  DateTime? _measurementsUpdatedAt;
  bool? _hasDiagnosedPathologies;

  @override
  void initState() {
    super.initState();

    final identity =
        widget.transmissionController.formData.identity;

    _firstNameController = TextEditingController(
      text: identity.firstName ?? '',
    );

    _lastNameController = TextEditingController(
      text: identity.lastName ?? '',
    );

    _heightController = TextEditingController(
      text: identity.heightCm?.toString() ?? '',
    );

    _weightController = TextEditingController(
      text: identity.weightKg?.toString() ?? '',
    );

    _dateOfBirth = identity.dateOfBirth;
    _measurementsUpdatedAt =
        identity.measurementsUpdatedAt;
    _hasDiagnosedPathologies =
        identity.hasDiagnosedPathologies;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ?? DateTime(now.year - 8),
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Sélectionner la date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _dateOfBirth = selectedDate;
    });

    widget.transmissionController
        .updateDateOfBirth(selectedDate);
  }

  Future<void> _selectMeasurementsUpdatedAt() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _measurementsUpdatedAt ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
      helpText:
          'Sélectionner la date de mesure',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _measurementsUpdatedAt = selectedDate;
    });

    widget.transmissionController
        .updateMeasurementsUpdatedAt(selectedDate);
  }

  void _updateDiagnosedPathologies(bool value) {
    setState(() {
      _hasDiagnosedPathologies = value;
    });

    widget.transmissionController
        .updateHasDiagnosedPathologies(value);
  }

  void _continue() {
    if (_hasDiagnosedPathologies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Répondez à la question concernant la santé de votre enfant.",
          ),
        ),
      );
      return;
    }

    if (_hasDiagnosedPathologies == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DiagnosedPathologiesPage(
            transmissionController:
                widget.transmissionController,
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
    return QuestionnairePage(
      title: "Identité de l’enfant",
      subtitle: "Qui est l’enfant pris en charge ?",
      child: Form(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            SkTextField(
              label: "Prénom de l’enfant",
              controller: _firstNameController,
              onChanged: widget
                  .transmissionController
                  .updateFirstName,
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Nom de famille de l’enfant",
              controller: _lastNameController,
              onChanged: widget
                  .transmissionController
                  .updateLastName,
            ),

            const SizedBox(height: 20),

            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date de naissance",
                  border: OutlineInputBorder(),
                  suffixIcon:
                      Icon(Icons.calendar_month),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? "Sélectionner une date"
                      : formatShortDate(_dateOfBirth!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SkNumberField(
              label: "Taille de l’enfant en cm",
              controller: _heightController,
              onChanged: (value) {
                widget.transmissionController
                    .updateHeightCm(value);

                setState(() {});
              },
            ),

            const SizedBox(height: 20),

            SkNumberField(
              label: "Poids de l’enfant en kg",
              controller: _weightController,
              onChanged: (value) {
                widget.transmissionController
                    .updateWeightKg(value);

                setState(() {});
              },
            ),

            if (_heightController.text.trim().isNotEmpty ||
                _weightController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 20),

              InkWell(
                onTap: _selectMeasurementsUpdatedAt,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText:
                        "À quelle date ces valeurs ont-elles été mesurées ? (facultatif)",
                    border: OutlineInputBorder(),
                    suffixIcon:
                        Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    _measurementsUpdatedAt == null
                        ? "Sélectionner une date"
                        : formatShortDate(
                            _measurementsUpdatedAt!,
                          ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            SkYesNoField(
              label:
                  "Votre enfant présente-t-il une ou plusieurs pathologies diagnostiquées ou allergies importantes nécessitant une vigilance particulière ?",
              value: _hasDiagnosedPathologies,
              onChanged:
                  _updateDiagnosedPathologies,
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: _continue,
              child: const Text("Continuer"),
            ),
          ],
        ),
      ),
    );
  }
}