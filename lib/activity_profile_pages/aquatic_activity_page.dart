import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'transport_page.dart';

class AquaticActivityPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const AquaticActivityPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<AquaticActivityPage> createState() =>
      _AquaticActivityPageState();
}

class _AquaticActivityPageState
    extends State<AquaticActivityPage> {
  late bool _requiresAdaptations;

  late bool _mayJumpIntoWater;
  late bool _canSwim;
  late bool _requiresFlotationVestNearWater;
  late bool _requiresDedicatedAdultNearWater;

  late bool _requiresSpecialEquipment;
  late bool _requiresAdaptedSupervision;
  late bool _notifyLifeguard;
  late bool _requiresDedicatedAdult;
  late bool _requiresOtherAdaptation;

  late final TextEditingController
      _specialEquipmentController;

  late final TextEditingController
      _otherSupervisionController;

  late final TextEditingController
      _otherAdaptationController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .aquaticActivity;

    _requiresAdaptations =
        data.requiresAdaptations;

    _mayJumpIntoWater =
        data.mayJumpIntoWater;

    _canSwim =
        data.canSwim;

    _requiresFlotationVestNearWater =
        data.requiresFlotationVestNearWater;

    _requiresDedicatedAdultNearWater =
        data.requiresDedicatedAdultNearWater;

    _requiresSpecialEquipment =
        data.requiresSpecialEquipment;

    _requiresAdaptedSupervision =
        data.requiresAdaptedSupervision;

    _notifyLifeguard =
        data.notifyLifeguard;

    _requiresDedicatedAdult =
        data.requiresDedicatedAdult;

    _requiresOtherAdaptation =
        data.requiresOtherAdaptation;

    _specialEquipmentController =
        TextEditingController(
      text: data.specialEquipmentDetails ?? '',
    );

    _otherSupervisionController =
        TextEditingController(
      text: data.otherSupervisionDetails ?? '',
    );

    _otherAdaptationController =
        TextEditingController(
      text: data.otherAdaptationDetails ?? '',
    );
  }

  @override
  void dispose() {
    _specialEquipmentController.dispose();
    _otherSupervisionController.dispose();
    _otherAdaptationController.dispose();

    super.dispose();
  }

  void _updateRequiresAdaptations(
    bool value,
  ) {
    setState(() {
      _requiresAdaptations = value;
    });

    widget
        .activityProfileController
        .draft
        .aquaticActivity
        .requiresAdaptations = value;
  }

  void _updateMayJumpIntoWater(
    bool value,
  ) {
    setState(() {
      _mayJumpIntoWater = value;
    });

    widget
        .activityProfileController
        .draft
        .aquaticActivity
        .mayJumpIntoWater = value;
  }

  void _updateCanSwim(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .aquaticActivity;

    setState(() {
      _canSwim = value;

      if (value) {
        _requiresFlotationVestNearWater =
            false;
      }
    });

    data.canSwim = value;

    if (value) {
      data.requiresFlotationVestNearWater =
          false;
    }
  }

  void _updateRequiresFlotationVestNearWater(
    bool value,
  ) {
    setState(() {
      _requiresFlotationVestNearWater =
          value;
    });

    widget
            .activityProfileController
            .draft
            .aquaticActivity
            .requiresFlotationVestNearWater =
        value;
  }

  void _updateRequiresDedicatedAdultNearWater(
    bool value,
  ) {
    setState(() {
      _requiresDedicatedAdultNearWater =
          value;
    });

    widget
            .activityProfileController
            .draft
            .aquaticActivity
            .requiresDedicatedAdultNearWater =
        value;
  }

  void _updateRequiresSpecialEquipment(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .aquaticActivity;

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
            .aquaticActivity
            .specialEquipmentDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _updateRequiresAdaptedSupervision(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .aquaticActivity;

    setState(() {
      _requiresAdaptedSupervision = value;

      if (!value) {
        _notifyLifeguard = false;
        _requiresDedicatedAdult = false;
        _otherSupervisionController.clear();
      }
    });

    data.requiresAdaptedSupervision = value;

    if (!value) {
      data.notifyLifeguard = false;
      data.requiresDedicatedAdult = false;
      data.otherSupervisionDetails = null;
    }
  }

  void _updateNotifyLifeguard(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _notifyLifeguard = newValue;
    });

    widget
        .activityProfileController
        .draft
        .aquaticActivity
        .notifyLifeguard = newValue;
  }

  void _updateRequiresDedicatedAdult(
    bool? value,
  ) {
    final newValue = value ?? false;

    setState(() {
      _requiresDedicatedAdult = newValue;
    });

    widget
        .activityProfileController
        .draft
        .aquaticActivity
        .requiresDedicatedAdult = newValue;
  }

  void _updateOtherSupervisionDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .aquaticActivity
            .otherSupervisionDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _updateRequiresOtherAdaptation(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .aquaticActivity;

    setState(() {
      _requiresOtherAdaptation = value;

      if (!value) {
        _otherAdaptationController.clear();
      }
    });

    data.requiresOtherAdaptation = value;

    if (!value) {
      data.otherAdaptationDetails = null;
    }
  }

  void _updateOtherAdaptationDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .aquaticActivity
            .otherAdaptationDetails =
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
            TransportPage(
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

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title:
          'Baignade / À proximité d’un point d’eau',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il des adaptations particulières en présence d’un point d’eau (baignade ou hors baignade) ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),

          const SizedBox(height: 32),

          _buildSectionTitle(
            'À proximité d’un point d’eau',
          ),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                'Votre enfant risque-t-il de se jeter dans l’eau ?',
            value: _mayJumpIntoWater,
            onChanged:
                _updateMayJumpIntoWater,
          ),

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Votre enfant sait-il nager ?',
            value: _canSwim,
            onChanged:
                _updateCanSwim,
          ),

          if (!_canSwim) ...[
            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Votre enfant doit-il disposer d’un gilet de flottaison lorsqu’il se trouve à proximité d’un point d’eau ?',
              value:
                  _requiresFlotationVestNearWater,
              onChanged:
                  _updateRequiresFlotationVestNearWater,
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Votre enfant a-t-il besoin d’un adulte dédié à proximité d’un point d’eau pour assurer sa sécurité ?',
            value:
                _requiresDedicatedAdultNearWater,
            onChanged:
                _updateRequiresDedicatedAdultNearWater,
          ),

          const SizedBox(height: 36),

          _buildSectionTitle(
            'Baignade',
          ),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il un équipement particulier ?',
            value:
                _requiresSpecialEquipment,
            onChanged:
                _updateRequiresSpecialEquipment,
          ),

          if (_requiresSpecialEquipment) ...[
            const SizedBox(height: 12),

            SkTextField(
              label:
                  'Équipement nécessaire',
              controller:
                  _specialEquipmentController,
              onChanged:
                  _updateSpecialEquipmentDetails,
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),

            const SizedBox(height: 8),

            const Text(
              'Exemples : bouchons d’oreilles, bonnet, lunettes spécifiques…',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Une adaptation particulière de la surveillance est-elle nécessaire ?',
            value:
                _requiresAdaptedSupervision,
            onChanged:
                _updateRequiresAdaptedSupervision,
          ),

          if (_requiresAdaptedSupervision) ...[
            const SizedBox(height: 12),

            _buildCheckbox(
              label:
                  'Prévenir le maître-nageur',
              value:
                  _notifyLifeguard,
              onChanged:
                  _updateNotifyLifeguard,
            ),

            _buildCheckbox(
              label:
                  'Prévoir un adulte dédié',
              value:
                  _requiresDedicatedAdult,
              onChanged:
                  _updateRequiresDedicatedAdult,
            ),

            const SizedBox(height: 12),

            SkTextField(
              label:
                  'Autre adaptation de la surveillance',
              controller:
                  _otherSupervisionController,
              onChanged:
                  _updateOtherSupervisionDetails,
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Une autre adaptation importante est-elle nécessaire ?',
            value:
                _requiresOtherAdaptation,
            onChanged:
                _updateRequiresOtherAdaptation,
          ),

          if (_requiresOtherAdaptation) ...[
            const SizedBox(height: 12),

            SkTextField(
              label:
                  'Précisez cette adaptation',
              controller:
                  _otherAdaptationController,
              onChanged:
                  _updateOtherAdaptationDetails,
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),
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