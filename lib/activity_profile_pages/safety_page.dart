import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'other_information_page.dart';

class SafetyPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const SafetyPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  late bool _requiresAdaptations;
  late bool _mayLeaveGroupSuddenly;
  late bool _cannotSwim;
  late bool _waterDanger;
  late bool _requiresSafetyEquipment;

  late final TextEditingController
      _safetyEquipmentController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .safety;

    _requiresAdaptations =
        data.requiresAdaptations;

    _mayLeaveGroupSuddenly =
        data.mayLeaveGroupSuddenly;

    _cannotSwim =
        data.cannotSwim;

    _waterDanger =
        data.waterDanger;

    _requiresSafetyEquipment =
        data.requiresSafetyEquipment;

    _safetyEquipmentController =
        TextEditingController(
      text: data.safetyEquipmentDetails ?? '',
    );
  }

  @override
  void dispose() {
    _safetyEquipmentController.dispose();
    super.dispose();
  }

  void _updateRequiresAdaptations(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .safety;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _mayLeaveGroupSuddenly = false;
        _cannotSwim = false;
        _waterDanger = false;
        _requiresSafetyEquipment = false;
        _safetyEquipmentController.clear();
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.mayLeaveGroupSuddenly = false;
      data.cannotSwim = false;
      data.waterDanger = false;
      data.requiresSafetyEquipment = false;
      data.safetyEquipmentDetails = null;
    }
  }

  void _updateMayLeaveGroupSuddenly(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _mayLeaveGroupSuddenly = newValue;
    });

    widget
        .activityProfileController
        .draft
        .safety
        .mayLeaveGroupSuddenly = newValue;
  }

  void _updateCannotSwim(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _cannotSwim = newValue;
    });

    widget
        .activityProfileController
        .draft
        .safety
        .cannotSwim = newValue;
  }

  void _updateWaterDanger(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _waterDanger = newValue;
    });

    widget
        .activityProfileController
        .draft
        .safety
        .waterDanger = newValue;
  }

  void _updateRequiresSafetyEquipment(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .safety;

    setState(() {
      _requiresSafetyEquipment = value;

      if (!value) {
        _safetyEquipmentController.clear();
      }
    });

    data.requiresSafetyEquipment = value;

    if (!value) {
      data.safetyEquipmentDetails = null;
    }
  }

  void _updateSafetyEquipmentDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .safety
            .safetyEquipmentDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _continue() {
    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtherInformationPage(
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
      title: 'Sécurité',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il des adaptations particulières concernant sa sécurité, par rapport à un enfant de son âge ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),

          if (_requiresAdaptations) ...[
            const SizedBox(height: 24),

            _buildCheckbox(
              label:
                  'Votre enfant a déjà quitté brusquement un groupe.',
              value:
                  _mayLeaveGroupSuddenly,
              onChanged:
                  _updateMayLeaveGroupSuddenly,
            ),

            _buildCheckbox(
              label:
                  'Votre enfant ne sait pas nager.',
              value: _cannotSwim,
              onChanged: _updateCannotSwim,
            ),

            _buildCheckbox(
              label:
                  'Votre enfant présente un risque particulier à proximité d’un point d’eau.',
              value: _waterDanger,
              onChanged: _updateWaterDanger,
            ),

            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Votre enfant nécessite-t-il un équipement de sécurité particulier ?',
              value:
                  _requiresSafetyEquipment,
              onChanged:
                  _updateRequiresSafetyEquipment,
            ),

            if (_requiresSafetyEquipment) ...[
              const SizedBox(height: 12),

              SkTextField(
                label:
                    'Précisez l’équipement de sécurité nécessaire',
                controller:
                    _safetyEquipmentController,
                onChanged:
                    _updateSafetyEquipmentDetails,
              ),

              const SizedBox(height: 8),

              const Text(
                'Exemples : gilet de flottaison spécifique, casque de protection, autre équipement indispensable à sa sécurité.',
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