import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import 'safety_page.dart';

class TransitionsPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const TransitionsPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<TransitionsPage> createState() =>
      _TransitionsPageState();
}

class _TransitionsPageState
    extends State<TransitionsPage> {
  late bool _transitionsMayCauseStress;
  late bool _changesMustBeAnnounced;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .transitions;

    _transitionsMayCauseStress =
        data.transitionsMayCauseStress;

    _changesMustBeAnnounced =
        data.changesMustBeAnnounced;
  }

  void _updateTransitionsMayCauseStress(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _transitionsMayCauseStress = newValue;
    });

    widget
        .activityProfileController
        .draft
        .transitions
        .transitionsMayCauseStress = newValue;
  }

  void _updateChangesMustBeAnnounced(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _changesMustBeAnnounced = newValue;
    });

    widget
        .activityProfileController
        .draft
        .transitions
        .changesMustBeAnnounced = newValue;
  }

  void _continue() {
    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SafetyPage(
          activityProfileController:
              widget.activityProfileController,
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity:
          ListTileControlAffinity.leading,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title:
          'Transitions / changements d’activité',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildCheckbox(
            label:
                'Les changements d’activité peuvent provoquer un stress important.',
            value:
                _transitionsMayCauseStress,
            onChanged:
                _updateTransitionsMayCauseStress,
          ),

          _buildCheckbox(
            label:
                'Les changements de programme doivent être annoncés à l’avance.',
            value:
                _changesMustBeAnnounced,
            onChanged:
                _updateChangesMustBeAnnounced,
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