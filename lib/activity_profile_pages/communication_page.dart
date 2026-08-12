import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'transitions_page.dart';

class CommunicationPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const CommunicationPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<CommunicationPage> createState() =>
      _CommunicationPageState();
}

class _CommunicationPageState
    extends State<CommunicationPage> {
  late bool _requiresAdaptations;
  late bool _useSimpleInstructions;
  late bool _mayAppearToUnderstand;
  late bool _verifyUnderstandingIndividually;
  late bool _usesCommunicationSupport;

  late final TextEditingController
      _communicationSupportController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .communication;

    _requiresAdaptations =
        data.requiresAdaptations;
    _useSimpleInstructions =
        data.useSimpleInstructions;
    _mayAppearToUnderstand =
        data.mayAppearToUnderstand;
    _verifyUnderstandingIndividually =
        data.verifyUnderstandingIndividually;
    _usesCommunicationSupport =
        data.usesCommunicationSupport;

    _communicationSupportController =
        TextEditingController(
      text:
          data.communicationSupportDetails ??
              '',
    );
  }

  @override
  void dispose() {
    _communicationSupportController.dispose();
    super.dispose();
  }

  void _updateRequiresAdaptations(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .communication;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _useSimpleInstructions = false;
        _mayAppearToUnderstand = false;
        _verifyUnderstandingIndividually =
            false;
        _usesCommunicationSupport = false;
        _communicationSupportController
            .clear();
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.useSimpleInstructions = false;
      data.mayAppearToUnderstand = false;
      data.verifyUnderstandingIndividually =
          false;
      data.usesCommunicationSupport = false;
      data.communicationSupportDetails =
          null;
    }
  }

  void _updateUseSimpleInstructions(
      bool? value) {
    final newValue = value ?? false;

    setState(() {
      _useSimpleInstructions = newValue;
    });

    widget
        .activityProfileController
        .draft
        .communication
        .useSimpleInstructions = newValue;
  }

  void _updateMayAppearToUnderstand(
      bool? value) {
    final newValue = value ?? false;

    setState(() {
      _mayAppearToUnderstand = newValue;
    });

    widget
        .activityProfileController
        .draft
        .communication
        .mayAppearToUnderstand = newValue;
  }

  void
      _updateVerifyUnderstandingIndividually(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _verifyUnderstandingIndividually =
          newValue;
    });

    widget
            .activityProfileController
            .draft
            .communication
            .verifyUnderstandingIndividually =
        newValue;
  }

  void _updateUsesCommunicationSupport(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .communication;

    setState(() {
      _usesCommunicationSupport = value;

      if (!value) {
        _communicationSupportController
            .clear();
      }
    });

    data.usesCommunicationSupport = value;

    if (!value) {
      data.communicationSupportDetails =
          null;
    }
  }

  void _updateCommunicationSupportDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .communication
            .communicationSupportDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _continue() {
    widget.activityProfileController
        .validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransitionsPage(
          activityProfileController:
              widget
                  .activityProfileController,
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
      title: 'Communication',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il des adaptations particulières concernant la communication, par rapport à un enfant de son âge ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),
          if (_requiresAdaptations) ...[
            const SizedBox(height: 24),
            _buildCheckbox(
              label:
                  'Les consignes doivent être formulées avec des mots simples.',
              value:
                  _useSimpleInstructions,
              onChanged:
                  _updateUseSimpleInstructions,
            ),
            _buildCheckbox(
              label:
                  'Votre enfant peut donner l’impression d’avoir compris une consigne alors que ce n’est pas le cas.',
              value:
                  _mayAppearToUnderstand,
              onChanged:
                  _updateMayAppearToUnderstand,
            ),
            _buildCheckbox(
              label:
                  'Il est préférable de vérifier individuellement que les consignes ont été comprises.',
              value:
                  _verifyUnderstandingIndividually,
              onChanged:
                  _updateVerifyUnderstandingIndividually,
            ),
            const SizedBox(height: 24),
            SkYesNoField(
              label:
                  'Votre enfant utilise-t-il un support de communication particulier ?',
              value:
                  _usesCommunicationSupport,
              onChanged:
                  _updateUsesCommunicationSupport,
            ),
            if (_usesCommunicationSupport) ...[
              const SizedBox(height: 12),
              SkTextField(
                label:
                    'Précisez le support de communication utilisé',
                controller:
                    _communicationSupportController,
                onChanged:
                    _updateCommunicationSupportDetails,
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),
              const SizedBox(height: 8),
              const Text(
                'Exemples : pictogrammes, tablette de communication, classeur de communication…',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ],
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