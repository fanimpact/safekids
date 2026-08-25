import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_yes_no_field.dart';
import 'toilets_page.dart';

class ClothingPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const ClothingPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<ClothingPage> createState() =>
      _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  bool? _requiresAssistance;

  @override
  void initState() {
    super.initState();

    _requiresAssistance = widget
        .activityProfileController
        .draft
        .clothing
        .requiresAssistance;
  }

  void _updateRequiresAssistance(bool value) {
    setState(() {
      _requiresAssistance = value;
    });

    widget
        .activityProfileController
        .draft
        .clothing
        .requiresAssistance = value;
  }

  void _continue() {
    if (_requiresAssistance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez par oui ou par non avant de continuer.',
          ),
        ),
      );

      return;
    }

    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToiletsPage(
          activityProfileController:
              widget.activityProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      barreTitre: 'Profil Activités',
      etape: 5,
      total: 11,
      title: 'Changement de tenue',
      subtitle:
          'Se déshabiller et se rhabiller : ce que votre enfant fait seul, et où il a besoin d’aide.',
      consigne:
          'Toutes les questions oui / non sont à renseigner pour '
          'continuer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il qu’un adulte dédié l’aide lors d’un changement de tenue, par rapport à un enfant de son âge ?',
            value: _requiresAssistance,
            onChanged: _updateRequiresAssistance,
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: _continue,
            child: const Text(
              'Continuer',
            ),
          ),
        ],
      ),
    );
  }
}