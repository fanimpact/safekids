import 'dart:async';

import 'package:flutter/material.dart';

import '../brouillons/enregistrement_brouillon.dart';

import '../controllers/transmission_controller.dart';
import '../utils/date_format_utils.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_number_field.dart';
import '../widgets/sk_text_field.dart';
import 'diagnosed_pathologies_page.dart';

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

  void _continue() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Renseignez le prénom et le nom de l’enfant avant de continuer.",
          ),
        ),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Sélectionnez la date de naissance avant de continuer.",
          ),
        ),
      );
      return;
    }

    // Le brouillon est ecrit a chaque ecran valide : sans cela, un
    // parent interrompu au cinquieme des six ecrans perdait les cinq.
    unawaited(
      enregistrerBrouillonSante(
        widget.transmissionController.formData,
      ),
    );

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
  }
    @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      barreTitre: 'Questionnaire santé',
      etape: 1,
      total: 6,
      title: 'Identité de l’enfant',
      subtitle:
          'Ces informations figurent en tête de toutes les fiches de votre enfant.',
      consigne:
          'Le prénom, le nom et la date de naissance sont '
          'nécessaires pour créer la fiche. La taille et le poids '
          'peuvent être ajoutés plus tard.',
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