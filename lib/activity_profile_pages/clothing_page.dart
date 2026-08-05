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
  late bool _requiresAssistance;

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
      title: 'Changement de tenue',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
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