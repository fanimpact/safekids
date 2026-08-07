import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_transport_page.dart';

class ActivityWalkingEffortPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityWalkingEffortPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityWalkingEffortPage> createState() =>
      _ActivityWalkingEffortPageState();
}

class _ActivityWalkingEffortPageState
    extends State<ActivityWalkingEffortPage> {
  bool? _hasProlongedWalking;
  bool? _hasSignificantPhysicalEffort;

  @override
  void initState() {
    super.initState();

    _hasProlongedWalking =
        widget.sessionData.hasProlongedWalking;

    _hasSignificantPhysicalEffort =
        widget.sessionData.hasSignificantPhysicalEffort;
  }

  void _continue() {
    if (_hasProlongedWalking == null ||
        _hasSignificantPhysicalEffort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez à toutes les questions avant de continuer.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasProlongedWalking =
        _hasProlongedWalking;

    widget.sessionData.hasSignificantPhysicalEffort =
        _hasSignificantPhysicalEffort;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityTransportPage(
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
          'Marche / effort',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _yesNoQuestion(
              question:
                  'L’activité prévoit-elle une marche prolongée ?',
              value: _hasProlongedWalking,
              onChanged: (value) {
                setState(() {
                  _hasProlongedWalking = value;
                });
              },
            ),

            const SizedBox(height: 24),

            _yesNoQuestion(
              question:
                  'L’activité demande-t-elle un effort physique important ?',
              value:
                  _hasSignificantPhysicalEffort,
              onChanged: (value) {
                setState(() {
                  _hasSignificantPhysicalEffort =
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