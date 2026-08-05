import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'clothing_page.dart';

class OvernightStayPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const OvernightStayPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<OvernightStayPage> createState() =>
      _OvernightStayPageState();
}

class _OvernightStayPageState
    extends State<OvernightStayPage> {
  late bool _requiresAdaptations;
  late bool _usesNightDevice;
  late bool _requiresElectricity;
  late bool _powerFailureIsCritical;
  late bool _requiresNightSupervision;

  late final TextEditingController
      _nightDeviceController;

  late final TextEditingController
      _nightSupervisionController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    _requiresAdaptations = data.requiresAdaptations;

    _usesNightDevice = data.usesNightDevice;

    _requiresElectricity = data.requiresElectricity;

    _powerFailureIsCritical =
        data.powerFailureIsCritical;

    _requiresNightSupervision =
        data.requiresNightSupervision;

    _nightDeviceController = TextEditingController(
      text: data.nightDeviceDetails ?? '',
    );

    _nightSupervisionController =
        TextEditingController(
      text: data.nightSupervisionDetails ?? '',
    );
  }

  @override
  void dispose() {
    _nightDeviceController.dispose();
    _nightSupervisionController.dispose();

    super.dispose();
  }

  void _updateRequiresAdaptations(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _usesNightDevice = false;
        _requiresElectricity = false;
        _powerFailureIsCritical = false;
        _requiresNightSupervision = false;

        _nightDeviceController.clear();
        _nightSupervisionController.clear();
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.usesNightDevice = false;
      data.nightDeviceDetails = null;

      data.requiresElectricity = false;
      data.powerFailureIsCritical = false;

      data.requiresNightSupervision = false;
      data.nightSupervisionDetails = null;
    }
  }

  void _updateUsesNightDevice(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    setState(() {
      _usesNightDevice = value;

      if (!value) {
        _requiresElectricity = false;
        _powerFailureIsCritical = false;
        _nightDeviceController.clear();
      }
    });

    data.usesNightDevice = value;

    if (!value) {
      data.nightDeviceDetails = null;
      data.requiresElectricity = false;
      data.powerFailureIsCritical = false;
    }
  }

  void _updateNightDeviceDetails(String value) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .overnightStay
            .nightDeviceDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _updateRequiresElectricity(bool value) {
    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    setState(() {
      _requiresElectricity = value;

      if (!value) {
        _powerFailureIsCritical = false;
      }
    });

    data.requiresElectricity = value;

    if (!value) {
      data.powerFailureIsCritical = false;
    }
  }

  void _updatePowerFailureIsCritical(bool value) {
    setState(() {
      _powerFailureIsCritical = value;
    });

    widget
        .activityProfileController
        .draft
        .overnightStay
        .powerFailureIsCritical = value;
  }

  void _updateRequiresNightSupervision(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    setState(() {
      _requiresNightSupervision = value;

      if (!value) {
        _nightSupervisionController.clear();
      }
    });

    data.requiresNightSupervision = value;

    if (!value) {
      data.nightSupervisionDetails = null;
    }
  }

  void _updateNightSupervisionDetails(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .overnightStay
            .nightSupervisionDetails =
        trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _continue() {
    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClothingPage(
          activityProfileController:
              widget.activityProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Séjour avec nuitée',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant nécessite-t-il des adaptations particulières lors d’un séjour avec nuitée, par rapport à un enfant de son âge ?',
            value: _requiresAdaptations,
            onChanged:
                _updateRequiresAdaptations,
          ),

          if (_requiresAdaptations) ...[
            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Votre enfant utilise-t-il un appareillage pendant la nuit ?',
              value: _usesNightDevice,
              onChanged: _updateUsesNightDevice,
            ),

            if (_usesNightDevice) ...[
              const SizedBox(height: 12),

              SkTextField(
                label:
                    'Précisez l’appareillage utilisé',
                controller:
                    _nightDeviceController,
                onChanged:
                    _updateNightDeviceDetails,
              ),

              const SizedBox(height: 24),

              SkYesNoField(
                label:
                    'Cet appareillage nécessite-t-il une alimentation électrique ?',
                value: _requiresElectricity,
                onChanged:
                    _updateRequiresElectricity,
              ),

              if (_requiresElectricity) ...[
                const SizedBox(height: 24),

                SkYesNoField(
                  label:
                      'Une panne d’électricité peut-elle compromettre la sécurité ou la santé de votre enfant ?',
                  value:
                      _powerFailureIsCritical,
                  onChanged:
                      _updatePowerFailureIsCritical,
                ),
              ],
            ],

            const SizedBox(height: 24),

            SkYesNoField(
              label:
                  'Une adaptation particulière de la surveillance est-elle nécessaire pendant la nuit ?',
              value:
                  _requiresNightSupervision,
              onChanged:
                  _updateRequiresNightSupervision,
            ),

            if (_requiresNightSupervision) ...[
              const SizedBox(height: 12),

              SkTextField(
                label:
                    'Précisez la surveillance nécessaire',
                controller:
                    _nightSupervisionController,
                onChanged:
                    _updateNightSupervisionDetails,
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