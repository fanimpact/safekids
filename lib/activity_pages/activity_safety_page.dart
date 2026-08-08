import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_trigger_factors_page.dart';

class ActivitySafetyPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivitySafetyPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivitySafetyPage> createState() =>
      _ActivitySafetyPageState();
}

class _ActivitySafetyPageState
    extends State<ActivitySafetyPage> {
  bool? _hasHeightActivity;
  bool? _hasAnimalContact;

  @override
  void initState() {
    super.initState();

    _hasHeightActivity =
        widget.sessionData.hasHeightActivity;

    _hasAnimalContact =
        widget.sessionData.hasAnimalContact;
  }

  void _continue() {
    if (_hasHeightActivity == null ||
        _hasAnimalContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez à toutes les questions avant de continuer.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasHeightActivity =
        _hasHeightActivity;

    widget.sessionData.hasAnimalContact =
        _hasAnimalContact;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityTriggerFactorsPage(
          sessionData: widget.sessionData,
        ),
      ),
    );
  }

  Widget _yesNoQuestion({
    required String question,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<bool>(
          groupValue: value,
          onChanged: onChanged,
          child: const Column(
            children: [
              RadioListTile<bool>(
                title: Text('Oui'),
                value: true,
              ),
              RadioListTile<bool>(
                title: Text('Non'),
                value: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sécurité',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _yesNoQuestion(
              question:
                  'L’activité se déroule-t-elle en hauteur ?',
              value: _hasHeightActivity,
              onChanged: (value) {
                setState(() {
                  _hasHeightActivity = value;
                });
              },
            ),

            const SizedBox(height: 24),

            _yesNoQuestion(
              question:
                  'Les enfants seront-ils en contact avec des animaux ?',
              value: _hasAnimalContact,
              onChanged: (value) {
                setState(() {
                  _hasAnimalContact = value;
                });
              },
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
    );
  }
}