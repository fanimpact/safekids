import 'package:flutter/material.dart';

import '../models/activity_session/activity_answer.dart';
import '../models/activity_session/activity_session_data.dart';
import 'activity_safety_page.dart';

class ActivityOvernightStayPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityOvernightStayPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityOvernightStayPage> createState() =>
      _ActivityOvernightStayPageState();
}

class _ActivityOvernightStayPageState
    extends State<ActivityOvernightStayPage> {
  bool? _hasOvernightStay;
  bool? _collectiveAccommodation;

  ActivityThreeStateAnswer? _electricityMayBeUnavailable;
  ActivityThreeStateAnswer? _phoneNetworkMayBeUnavailable;

  @override
  void initState() {
    super.initState();

    _hasOvernightStay =
        widget.sessionData.hasOvernightStay;

    _collectiveAccommodation =
        widget.sessionData.collectiveAccommodation;

    _electricityMayBeUnavailable =
        widget.sessionData.electricityMayBeUnavailable;

    _phoneNetworkMayBeUnavailable =
        widget.sessionData.phoneNetworkMayBeUnavailable;
  }

  void _continue() {
    if (_hasOvernightStay == null) {
      _showMissingAnswer();
      return;
    }

    if (_hasOvernightStay == true &&
        (_collectiveAccommodation == null ||
            _electricityMayBeUnavailable == null ||
            _phoneNetworkMayBeUnavailable == null)) {
      _showMissingAnswer();
      return;
    }

    widget.sessionData.hasOvernightStay =
        _hasOvernightStay;

    if (_hasOvernightStay == true) {
      widget.sessionData.collectiveAccommodation =
          _collectiveAccommodation;

      widget.sessionData.electricityMayBeUnavailable =
          _electricityMayBeUnavailable;

      widget.sessionData.phoneNetworkMayBeUnavailable =
          _phoneNetworkMayBeUnavailable;
    } else {
      widget.sessionData.collectiveAccommodation =
          false;

      widget.sessionData.electricityMayBeUnavailable =
          null;

      widget.sessionData.phoneNetworkMayBeUnavailable =
          null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivitySafetyPage(
          sessionData: widget.sessionData,
        ),
      ),
    );
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
          'Nuitée',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _yesNoQuestion(
              question:
                  'L’activité comporte-t-elle une ou plusieurs nuitées ?',
              value: _hasOvernightStay,
              onChanged: (value) {
                setState(() {
                  _hasOvernightStay = value;

                  if (value != true) {
                    _collectiveAccommodation = null;
                    _electricityMayBeUnavailable =
                        null;
                    _phoneNetworkMayBeUnavailable =
                        null;
                  }
                });
              },
            ),

            if (_hasOvernightStay == true) ...[
              const SizedBox(height: 24),

              _yesNoQuestion(
                question:
                    'Les enfants dormiront-ils en hébergement collectif ?',
                value: _collectiveAccommodation,
                onChanged: (value) {
                  setState(() {
                    _collectiveAccommodation =
                        value;
                  });
                },
              ),

              const SizedBox(height: 24),

              _threeStateQuestion(
                question:
                    'Le lieu d’hébergement est-il susceptible de ne pas disposer d’électricité ?',
                value:
                    _electricityMayBeUnavailable,
                onChanged: (value) {
                  setState(() {
                    _electricityMayBeUnavailable =
                        value;
                  });
                },
              ),

              const SizedBox(height: 24),

              _threeStateQuestion(
                question:
                    'Le réseau téléphonique risque-t-il d’être indisponible pendant tout ou partie de l’activité ?',
                value:
                    _phoneNetworkMayBeUnavailable,
                onChanged: (value) {
                  setState(() {
                    _phoneNetworkMayBeUnavailable =
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