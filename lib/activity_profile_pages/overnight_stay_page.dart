import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../models/medical_device_data.dart';
import '../repositories/child_repository.dart';
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
  late bool _usesNightDevice;
  late bool _requiresElectricity;
  late bool _powerFailureIsCritical;
  late bool _requiresNightSupervision;

  late final TextEditingController
      _nightSupervisionController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    _usesNightDevice = data.usesNightDevice;

    _requiresElectricity = data.requiresElectricity;

    _powerFailureIsCritical =
        data.powerFailureIsCritical;

    _requiresNightSupervision =
        data.requiresNightSupervision;

    _nightSupervisionController =
        TextEditingController(
      text: data.nightSupervisionDetails ?? '',
    );
  }

  @override
  void dispose() {
    _nightSupervisionController.dispose();

    super.dispose();
  }

  List<MedicalDeviceData> get _declaredMedicalDevices {
    final childId =
        widget.activityProfileController.draft.childId;

    if (childId == null) {
      return [];
    }

    final child =
        ChildRepository.instance.findByChildId(childId);

    return child?.essentialInformation.medicalDevices ??
        [];
  }

  void _toggleNightDeviceId(
    String deviceId,
    bool selected,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .overnightStay;

    setState(() {
      if (selected) {
        data.nightDeviceIds.add(deviceId);
      } else {
        data.nightDeviceIds.remove(deviceId);
      }
    });
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
      }
    });

    data.usesNightDevice = value;

    if (!value) {
      data.nightDeviceIds.clear();
      data.requiresElectricity = false;
      data.powerFailureIsCritical = false;
    }
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
                'Votre enfant utilise-t-il un appareillage pendant la nuit ?',
              value: _usesNightDevice,
              onChanged: _updateUsesNightDevice,
            ),

            if (_usesNightDevice) ...[
              const SizedBox(height: 12),

              if (_declaredMedicalDevices.isEmpty)
                const Text(
                  'Aucun dispositif médical renseigné pour cet enfant. Ajoutez-le d’abord dans le profil santé, section « Dispositifs médicaux », pour pouvoir le sélectionner ici.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else ...[
                const Text(
                  'Lequel (ou lesquels) ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                for (final device
                    in _declaredMedicalDevices)
                  CheckboxListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    controlAffinity:
                        ListTileControlAffinity
                            .leading,
                    title: Text(
                      device.deviceName
                              ?.trim()
                              .isNotEmpty ==
                              true
                          ? device.deviceName!
                          : 'Dispositif sans nom',
                    ),
                    value: widget
                        .activityProfileController
                        .draft
                        .overnightStay
                        .nightDeviceIds
                        .contains(device.deviceId),
                    onChanged: (selected) {
                      _toggleNightDeviceId(
                        device.deviceId,
                        selected ?? false,
                      );
                    },
                  ),
              ],

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