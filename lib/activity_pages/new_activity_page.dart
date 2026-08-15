import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../utils/child_name_utils.dart';
import 'activity_characteristics_page.dart';

class NewActivityPage extends StatefulWidget {
  final CompleteChildProfileData? selectedChild;

  const NewActivityPage({
    super.key,
    this.selectedChild,
  });

  @override
  State<NewActivityPage> createState() =>
      _NewActivityPageState();
}

class _NewActivityPageState
    extends State<NewActivityPage> {
  final TextEditingController
      _activityNameController =
      TextEditingController();

  final TextEditingController
      _locationController =
      TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _activityNameController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(
        DateTime.now().year + 5,
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  String _formattedDate() {
    final date = _selectedDate;

    if (date == null) {
      return 'Choisir une date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _continue() {
    final activityName =
        _activityNameController.text.trim();

    if (activityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indiquez un nom pour cette activité.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivityCharacteristicsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = widget.selectedChild;

    final childName = selectedChild == null
        ? null
        : childFullName(
            selectedChild.essentialInformation.identity,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Préparer une activité',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              if (childName != null &&
                  childName.isNotEmpty) ...[
                Text(
                  'Enfant concerné : $childName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Informations générales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Ces informations vous permettront de reconnaître facilement cette activité.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller:
                    _activityNameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nom de l’activité',
                  hintText:
                      'Exemple : sortie au musée',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(
                  Icons.calendar_month,
                ),
                label: Text(
                  _formattedDate(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller:
                    _locationController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Lieu (facultatif)',
                  hintText:
                      'Exemple : musée de Pau',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: _continue,
                child: const Text(
                  'Continuer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}