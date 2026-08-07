import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_session_complete_page.dart';

class ActivityClothingChangePage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityClothingChangePage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityClothingChangePage> createState() =>
      _ActivityClothingChangePageState();
}

class _ActivityClothingChangePageState
    extends State<ActivityClothingChangePage> {
  bool? _hasClothingChange;

  @override
  void initState() {
    super.initState();

    _hasClothingChange =
        widget.sessionData.hasClothingChange;
  }

  void _continue() {
    if (_hasClothingChange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez à la question avant de continuer.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasClothingChange =
        _hasClothingChange;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivitySessionCompletePage(
          sessionData: widget.sessionData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Changement de tenue',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Cette activité nécessite-t-elle un changement de tenue ?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<bool>(
              groupValue: _hasClothingChange,
              onChanged: (value) {
                setState(() {
                  _hasClothingChange = value;
                });
              },
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