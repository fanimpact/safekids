import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_number_field.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';

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
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  DateTime? _dateOfBirth;
  bool? _hasDiagnosedPathologies;

  @override
  void initState() {
    super.initState();

    final identity = widget.transmissionController.formData.identity;

    _lastNameController = TextEditingController(
      text: identity.lastName ?? '',
    );

    _firstNameController = TextEditingController(
      text: identity.firstName ?? '',
    );

    _heightController = TextEditingController(
      text: identity.heightCm?.toString() ?? '',
    );

    _weightController = TextEditingController(
      text: identity.weightKg?.toString() ?? '',
    );

    _dateOfBirth = identity.dateOfBirth;
    _hasDiagnosedPathologies = identity.hasDiagnosedPathologies;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 8),
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

    widget.transmissionController.updateDateOfBirth(selectedDate);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _updateDiagnosedPathologies(bool? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _hasDiagnosedPathologies = value;
    });

    widget.transmissionController.updateHasDiagnosedPathologies(value);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: "Identité de l’enfant",
      subtitle: "Qui est l’enfant pris en charge ?",
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkTextField(
              label: "Nom de l’enfant",
              controller: _lastNameController,
              onChanged: widget.transmissionController.updateLastName,
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Prénom de l’enfant",
              controller: _firstNameController,
              onChanged: widget.transmissionController.updateFirstName,
            ),

            const SizedBox(height: 20),

            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date de naissance",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? "Sélectionner une date"
                      : _formatDate(_dateOfBirth!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SkNumberField(
              label: "Taille de l’enfant en cm",
              controller: _heightController,
              onChanged: widget.transmissionController.updateHeightCm,
            ),

            const SizedBox(height: 20),

            SkNumberField(
              label: "Poids de l’enfant en kg",
              controller: _weightController,
              onChanged: widget.transmissionController.updateWeightKg,
            ),

            const SizedBox(height: 30),

            SkYesNoField(
              label:
                  "Un professionnel de santé a-t-il diagnostiqué une ou plusieurs pathologies chez votre enfant ?",
              value: _hasDiagnosedPathologies,
              onChanged: _updateDiagnosedPathologies,
            ),
          ],
        ),
      ),
    );
  }
}