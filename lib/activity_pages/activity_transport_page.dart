import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_overnight_stay_page.dart';

class ActivityTransportPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityTransportPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityTransportPage> createState() =>
      _ActivityTransportPageState();
}

class _ActivityTransportPageState
    extends State<ActivityTransportPage> {
  bool? _hasTransport;

  final Set<ActivityTransportType> _transportTypes = {};

  @override
  void initState() {
    super.initState();

    _hasTransport = widget.sessionData.hasTransport;

    _transportTypes.addAll(
      widget.sessionData.transportTypes,
    );
  }

  void _continue() {
    if (_hasTransport == null) {
      _showMissingAnswer();
      return;
    }

    if (_hasTransport == true &&
        _transportTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez au moins un moyen de transport.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasTransport =
        _hasTransport;

    widget.sessionData.transportTypes
      ..clear()
      ..addAll(
        _hasTransport == true
            ? _transportTypes
            : <ActivityTransportType>{},
      );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityOvernightStayPage(
          sessionData: widget.sessionData,
        ),
      ),
    );
  }

  void _showMissingAnswer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Répondez à la question avant de continuer.',
        ),
      ),
    );
  }

  Widget _transportCheckbox({
    required String label,
    required ActivityTransportType type,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity:
          ListTileControlAffinity.leading,
      title: Text(label),
      value: _transportTypes.contains(type),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _transportTypes.add(type);
          } else {
            _transportTypes.remove(type);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transport',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Un ou plusieurs déplacements en véhicule sont-ils prévus dans le cadre de cette activité ?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            RadioListTile<bool>(
              title: const Text('Oui'),
              value: true,
              groupValue: _hasTransport,
              onChanged: (value) {
                setState(() {
                  _hasTransport = value;
                });
              },
            ),

            RadioListTile<bool>(
              title: const Text('Non'),
              value: false,
              groupValue: _hasTransport,
              onChanged: (value) {
                setState(() {
                  _hasTransport = value;
                  _transportTypes.clear();
                });
              },
            ),

            if (_hasTransport == true) ...[
              const SizedBox(height: 24),

              const Text(
                'Quels sont les moyens de transport prévus ?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _transportCheckbox(
                label: 'Voiture',
                type: ActivityTransportType.car,
              ),

              _transportCheckbox(
                label: 'Bus',
                type: ActivityTransportType.bus,
              ),

              _transportCheckbox(
                label: 'Train',
                type: ActivityTransportType.train,
              ),

              _transportCheckbox(
                label: 'Tramway',
                type: ActivityTransportType.tram,
              ),

              _transportCheckbox(
                label: 'Métro',
                type: ActivityTransportType.metro,
              ),

              _transportCheckbox(
                label: 'Avion',
                type: ActivityTransportType.plane,
              ),

              _transportCheckbox(
                label: 'Bateau / Ferry',
                type:
                    ActivityTransportType.boatOrFerry,
              ),

              _transportCheckbox(
                label: 'Autre',
                type: ActivityTransportType.other,
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