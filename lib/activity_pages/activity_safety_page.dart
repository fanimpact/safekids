import 'package:flutter/material.dart';

import '../models/activity_session/activity_answer.dart';
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
  ActivityThreeStateAnswer? _phoneNetworkMayBeUnavailable;

  @override
  void initState() {
    super.initState();

    _hasHeightActivity =
        widget.sessionData.hasHeightActivity;

    _hasAnimalContact =
        widget.sessionData.hasAnimalContact;

    _phoneNetworkMayBeUnavailable =
        widget.sessionData.phoneNetworkMayBeUnavailable;
  }

  void _continue() {
    if (_hasHeightActivity == null ||
        _hasAnimalContact == null ||
        _phoneNetworkMayBeUnavailable == null) {
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

    widget.sessionData.phoneNetworkMayBeUnavailable =
        _phoneNetworkMayBeUnavailable;

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

  Widget _threeStateQuestion({
    required String question,
    required ActivityThreeStateAnswer? value,
    required ValueChanged<ActivityThreeStateAnswer?> onChanged,
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
        RadioGroup<ActivityThreeStateAnswer>(
          groupValue: value,
          onChanged: onChanged,
          child: const Column(
            children: [
              RadioListTile<ActivityThreeStateAnswer>(
                title: Text('Oui'),
                value: ActivityThreeStateAnswer.yes,
              ),
              RadioListTile<ActivityThreeStateAnswer>(
                title: Text('Non'),
                value: ActivityThreeStateAnswer.no,
              ),
              RadioListTile<ActivityThreeStateAnswer>(
                title: Text('Je ne sais pas'),
                value: ActivityThreeStateAnswer.unknown,
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

            const SizedBox(height: 24),

            _threeStateQuestion(
              question:
                  'Le réseau téléphonique risque-t-il d’être indisponible pendant tout ou partie de l’activité ?',
              value: _phoneNetworkMayBeUnavailable,
              onChanged: (value) {
                setState(() {
                  _phoneNetworkMayBeUnavailable =
                      value;
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