import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'walking_effort_page.dart';

class TransportPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const TransportPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<TransportPage> createState() =>
      _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  late bool _requiresAdaptations;
  late bool _motionSickness;
  late bool _requiresSpecialEquipment;
  late bool _requiresSpecialAttention;

  late final TextEditingController
      _specialEquipmentController;

  late final TextEditingController
      _specialAttentionController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .transport;

    _requiresAdaptations = data.requiresAdaptations;
    _motionSickness = data.motionSickness;

    _requiresSpecialEquipment =
        data.requiresSpecialEquipment;

    _requiresSpecialAttention =
        data.requiresSpecialAttention;

    _specialEquipmentController =
        TextEditingController(
      text: data.specialEquipmentDetails ?? '',
    );

    _specialAttentionController =
        TextEditingController(
      text: data.specialAttentionDetails ?? '',
    );
  }

  @override
  void dispose() {
    _specialEquipmentController.dispose();
    _specialAttentionController.dispose();

    super.dispose();
  }

  void _updateRequiresAdaptations(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .transport;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _motionSickness = false;
        _requiresSpecialEquipment = false;
        _requiresSpecialAttention = false;

        _specialEquipmentController.clear();
        _specialAttentionController.clear();
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.motionSickness = false;

      data.requiresSpecialEquipment = false;
      data.specialEquipmentDetails = null;

      data.requiresSpecialAttention = false;
      data.specialAttentionDetails = null;
    }
  }

  void _updateMotionSickness(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _motionSickness = newValue;
    });

    widget
        .activityProfileController
        .draft
        .transport
        .motionSickness = newValue;
  }

  void _updateRequiresSpecialEquipment(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .transport;

    setState(() {
      _requiresSpecialEquipment = value;

      if (!value) {
        _specialEquipmentController.clear();
      }
    });

    data.requiresSpecialEquipment = value;

    if (!value) {
      data.specialEquipmentDetails = null;
    }
  }

  void _updateSpecialEquipmentDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .transport
            .specialEquipmentDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _updateRequiresSpecialAttention(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .transport;

    setState(() {
      _requiresSpecialAttention = value;

      if (!value) {
        _specialAttentionController.clear();
      }
    });

    data.requiresSpecialAttention = value;

    if (!value) {
      data.specialAttentionDetails = null;
    }
  }

  void _updateSpecialAttentionDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .transport
            .specialAttentionDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _continue() {
    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalkingEffortPage(
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
      title: 'Transport',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il des adaptations particulières lors des transports ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),

          if (_requiresAdaptations) ...[
            const SizedBox(height: 24),

            _buildCheckbox(
              label: 'Mal des transports',
              value: _motionSickness,
              onChanged: _updateMotionSickness,
            ),

            const SizedBox(height: 16),

            SkYesNoField(
              label:
                  'Votre enfant a-t-il besoin d’un équipement particulier pendant le transport ?',
              value:
                  _requiresSpecialEquipment,
              onChanged:
                  _updateRequiresSpecialEquipment,
            ),

            if (_requiresSpecialEquipment) ...[
              const SizedBox(height: 12),

              SkTextField(
                label: 'Équipement nécessaire',
                controller:
                    _specialEquipmentController,
                onChanged:
                    _updateSpecialEquipmentDetails,
              ),

              const SizedBox(height: 8),

              const Text(
                'Exemples : casque antibruit, coussin de positionnement, harnais spécifique…',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Votre enfant nécessite-t-il une attention particulière pendant le transport ?',
              value:
                  _requiresSpecialAttention,
              onChanged:
                  _updateRequiresSpecialAttention,
            ),

            if (_requiresSpecialAttention) ...[
              const SizedBox(height: 12),

              SkTextField(
                label:
                    'Précisez l’attention nécessaire',
                controller:
                    _specialAttentionController,
                onChanged:
                    _updateSpecialAttentionDetails,
              ),

              const SizedBox(height: 8),

              const Text(
                'Exemples : enlève sa ceinture, panique, a besoin d’être rassuré, tente de quitter sa place…',
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