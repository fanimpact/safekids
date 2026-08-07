import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_walking_effort_page.dart';

class ActivityWaterPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityWaterPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityWaterPage> createState() =>
      _ActivityWaterPageState();
}

class _ActivityWaterPageState
    extends State<ActivityWaterPage> {
  bool? _hasWaterNearby;
  bool? _childrenWillEnterWater;
  bool? _swimmingSupervisedByLifeguard;

  @override
  void initState() {
    super.initState();

    _hasWaterNearby =
        widget.sessionData.hasWaterNearby;

    _childrenWillEnterWater =
        widget.sessionData.childrenWillEnterWater;

    _swimmingSupervisedByLifeguard =
        widget
            .sessionData
            .swimmingSupervisedByLifeguard;
  }

  void _showMissingAnswer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Répondez à toutes les questions affichées avant de continuer.',
        ),
      ),
    );
  }

  void _continue() {
    if (_hasWaterNearby == null) {
      _showMissingAnswer();
      return;
    }

    if (_hasWaterNearby == true &&
        _childrenWillEnterWater == null) {
      _showMissingAnswer();
      return;
    }

    if (_childrenWillEnterWater == true &&
        _swimmingSupervisedByLifeguard == null) {
      _showMissingAnswer();
      return;
    }

    widget.sessionData.hasWaterNearby =
        _hasWaterNearby;

    widget.sessionData.childrenWillEnterWater =
        _hasWaterNearby == true
            ? _childrenWillEnterWater
            : false;

    widget
            .sessionData
            .swimmingSupervisedByLifeguard =
        _childrenWillEnterWater == true
            ? _swimmingSupervisedByLifeguard
            : false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityWalkingEffortPage(
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
          'Eau',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _yesNoQuestion(
              question:
                  'L’activité se déroule-t-elle à proximité d’un point d’eau ?',
              value: _hasWaterNearby,
              onChanged: (value) {
                setState(() {
                  _hasWaterNearby = value;

                  if (value != true) {
                    _childrenWillEnterWater = null;

                    _swimmingSupervisedByLifeguard =
                        null;
                  }
                });
              },
            ),

            if (_hasWaterNearby == true) ...[
              const SizedBox(height: 24),

              _yesNoQuestion(
                question:
                    'Les enfants seront-ils amenés à entrer dans l’eau ?',
                value:
                    _childrenWillEnterWater,
                onChanged: (value) {
                  setState(() {
                    _childrenWillEnterWater =
                        value;

                    if (value != true) {
                      _swimmingSupervisedByLifeguard =
                          null;
                    }
                  });
                },
              ),
            ],

            if (_childrenWillEnterWater ==
                true) ...[
              const SizedBox(height: 24),

              _yesNoQuestion(
                question:
                    'La baignade sera-t-elle surveillée par un maître-nageur ?',
                value:
                    _swimmingSupervisedByLifeguard,
                onChanged: (value) {
                  setState(() {
                    _swimmingSupervisedByLifeguard =
                        value;
                  });
                },
              ),
            ],

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