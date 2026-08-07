import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_water_page.dart';

class ActivitySessionStartPage extends StatefulWidget {
  const ActivitySessionStartPage({
    super.key,
  });

  @override
  State<ActivitySessionStartPage> createState() =>
      _ActivitySessionStartPageState();
}

class _ActivitySessionStartPageState
    extends State<ActivitySessionStartPage> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
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
        _nameController.text.trim();

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

    final sessionData = ActivitySessionData(
      activityName: activityName,
      date: _selectedDate,
      location:
          _locationController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityWaterPage(
          sessionData: sessionData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créer une activité',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
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

            TextField(
              controller:
                  _locationController,
              decoration: const InputDecoration(
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
                'Commencer le questionnaire',
              ),
            ),
          ],
        ),
      ),
    );
  }
}