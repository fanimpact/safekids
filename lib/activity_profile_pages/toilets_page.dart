import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_yes_no_field.dart';
import 'communication_page.dart';

class ToiletsPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const ToiletsPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<ToiletsPage> createState() =>
      _ToiletsPageState();
}

class _ToiletsPageState extends State<ToiletsPage> {
  bool? _requiresAssistance;

  @override
  void initState() {
    super.initState();

    _requiresAssistance = widget
        .activityProfileController
        .draft
        .toilets
        .requiresAssistance;
  }

  void _updateRequiresAssistance(bool value) {
    setState(() {
      _requiresAssistance = value;
    });

    widget
        .activityProfileController
        .draft
        .toilets
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
        builder: (context) => CommunicationPage(
          activityProfileController:
              widget.activityProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Toilettes',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il qu’un adulte dédié l’accompagne aux toilettes, par rapport à un enfant de son âge ?',
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