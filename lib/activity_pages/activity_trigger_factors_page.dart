import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_clothing_change_page.dart';

class ActivityTriggerFactorsPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityTriggerFactorsPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityTriggerFactorsPage> createState() =>
      _ActivityTriggerFactorsPageState();
}

class _ActivityTriggerFactorsPageState
    extends State<ActivityTriggerFactorsPage> {
  bool? _hasLoudEnvironment;
  bool? _hasLargeCrowd;
  bool? _hasConfinedSpace;

  @override
  void initState() {
    super.initState();

    _hasLoudEnvironment =
        widget.sessionData.hasLoudEnvironment;

    _hasLargeCrowd =
        widget.sessionData.hasLargeCrowd;

    _hasConfinedSpace =
        widget.sessionData.hasConfinedSpace;
  }

  void _continue() {
    if (_hasLoudEnvironment == null ||
        _hasLargeCrowd == null ||
        _hasConfinedSpace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez à toutes les questions avant de continuer.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasLoudEnvironment =
        _hasLoudEnvironment;

    widget.sessionData.hasLargeCrowd =
        _hasLargeCrowd;

    widget.sessionData.hasConfinedSpace =
        _hasConfinedSpace;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityClothingChangePage(
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
        RadioListTile<bool>(
          title: const Text('Oui'),
          value: true,
          groupValue: value,
          onChanged: onChanged,
        ),
        RadioListTile<bool>(
          title: const Text('Non'),
          value: false,
          groupValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Facteurs déclenchants',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _yesNoQuestion(
              question:
                  'L’activité se déroule-t-elle dans un environnement particulièrement bruyant ?',
              value: _hasLoudEnvironment,
              onChanged: (value) {
                setState(() {
                  _hasLoudEnvironment = value;
                });
              },
            ),

            const SizedBox(height: 24),

            _yesNoQuestion(
              question:
                  'Une foule importante est-elle attendue pendant cette activité ?',
              value: _hasLargeCrowd,
              onChanged: (value) {
                setState(() {
                  _hasLargeCrowd = value;
                });
              },
            ),

            const SizedBox(height: 24),

            _yesNoQuestion(
              question:
                  'L’activité se déroule-t-elle principalement dans un espace confiné ?',
              value: _hasConfinedSpace,
              onChanged: (value) {
                setState(() {
                  _hasConfinedSpace = value;
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