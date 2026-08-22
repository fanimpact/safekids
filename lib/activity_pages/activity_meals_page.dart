import 'package:flutter/material.dart';

import '../models/activity_session/activity_session_data.dart';
import 'activity_session_complete_page.dart';

/// Dernière question du questionnaire de préparation d'activité. C'est
/// elle qui déclenche l'affichage des recommandations liées aux repas
/// sur la fiche, comme la présence d'eau déclenche celles de la
/// baignade : sans repas prévu, la section Repas du profil de l'enfant
/// ne remonte pas.
class ActivityMealsPage extends StatefulWidget {
  final ActivitySessionData sessionData;

  const ActivityMealsPage({
    super.key,
    required this.sessionData,
  });

  @override
  State<ActivityMealsPage> createState() =>
      _ActivityMealsPageState();
}

class _ActivityMealsPageState extends State<ActivityMealsPage> {
  bool? _hasMeal;

  @override
  void initState() {
    super.initState();

    _hasMeal = widget.sessionData.hasMeal;
  }

  void _continue() {
    if (_hasMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez à la question avant de continuer.',
          ),
        ),
      );
      return;
    }

    widget.sessionData.hasMeal = _hasMeal;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySessionCompletePage(
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
          'Repas',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Cette activité comprend-elle un repas, un goûter ou une collation ?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<bool>(
              groupValue: _hasMeal,
              onChanged: (value) {
                setState(() {
                  _hasMeal = value;
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
