import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../models/transport_data.dart';
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
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  late bool _requiresAdaptations;
  late bool _motionSickness;
  late bool _takesMotionSicknessMedication;
  late bool _requiresSpecialEquipment;
  late bool _requiresSpecialAttention;

  late final TextEditingController _specialEquipmentController;
  late final TextEditingController _specialAttentionController;

  final Map<TransportMode, TextEditingController>
      _medicationControllers = {};

  @override
  void initState() {
    super.initState();

    final data =
        widget.activityProfileController.draft.transport;

    _requiresAdaptations = data.requiresAdaptations;
    _motionSickness = data.motionSickness;

    _takesMotionSicknessMedication =
        data.takesMotionSicknessMedication;

    _requiresSpecialEquipment =
        data.requiresSpecialEquipment;

    _requiresSpecialAttention =
        data.requiresSpecialAttention;

    _specialEquipmentController = TextEditingController(
      text: data.specialEquipmentDetails ?? '',
    );

    _specialAttentionController = TextEditingController(
      text: data.specialAttentionDetails ?? '',
    );

    for (final transportMode in TransportMode.values) {
      _medicationControllers[transportMode] =
          TextEditingController(
        text: data.motionSicknessMedicationNames[
                transportMode] ??
            '',
      );
    }
  }

  @override
  void dispose() {
    _specialEquipmentController.dispose();
    _specialAttentionController.dispose();

    for (final controller
        in _medicationControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  String _transportLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return 'Voiture';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.train:
        return 'Train';
      case TransportMode.tram:
        return 'Tramway';
      case TransportMode.metro:
        return 'Métro';
      case TransportMode.plane:
        return 'Avion';
      case TransportMode.boatOrFerry:
        return 'Bateau / Ferry';
      case TransportMode.other:
        return 'Autre';
    }
  }

  void _updateRequiresAdaptations(bool value) {
    final data =
        widget.activityProfileController.draft.transport;

    setState(() {
      _requiresAdaptations = value;

      if (!value) {
        _motionSickness = false;
        _takesMotionSicknessMedication = false;
        _requiresSpecialEquipment = false;
        _requiresSpecialAttention = false;

        _specialEquipmentController.clear();
        _specialAttentionController.clear();

        for (final controller
            in _medicationControllers.values) {
          controller.clear();
        }
      }
    });

    data.requiresAdaptations = value;

    if (!value) {
      data.motionSickness = false;
      data.motionSicknessTransports.clear();

      data.takesMotionSicknessMedication = false;
      data.motionSicknessMedicationNames.clear();

      data.requiresSpecialEquipment = false;
      data.specialEquipmentDetails = null;

      data.requiresSpecialAttention = false;
      data.specialAttentionDetails = null;
    }
  }

  void _updateMotionSickness(bool value) {
    final data =
        widget.activityProfileController.draft.transport;

    setState(() {
      _motionSickness = value;

      if (!value) {
        _takesMotionSicknessMedication = false;

        for (final controller
            in _medicationControllers.values) {
          controller.clear();
        }
      }
    });

    data.motionSickness = value;

    if (!value) {
      data.motionSicknessTransports.clear();
      data.takesMotionSicknessMedication = false;
      data.motionSicknessMedicationNames.clear();
    }
  }

  void _updateMotionSicknessTransport(
    TransportMode transportMode,
    bool? value,
  ) {
    final data =
        widget.activityProfileController.draft.transport;

    final isSelected = value ?? false;

    setState(() {
      if (isSelected) {
        data.motionSicknessTransports.add(
          transportMode,
        );
      } else {
        data.motionSicknessTransports.remove(
          transportMode,
        );

        data.motionSicknessMedicationNames.remove(
          transportMode,
        );

        _medicationControllers[transportMode]?.clear();
      }

      final selectedTransports =
          data.motionSicknessTransports;

      if (selectedTransports.isEmpty) {
        _takesMotionSicknessMedication = false;
        data.takesMotionSicknessMedication = false;
        data.motionSicknessMedicationNames.clear();
      } else if (selectedTransports.length == 1 &&
          _takesMotionSicknessMedication) {
        final onlyTransport =
            selectedTransports.first;

        final existingValue =
            data.motionSicknessMedicationNames[
                    onlyTransport] ??
                '';

        data.motionSicknessMedicationNames
          ..clear()
          ..[onlyTransport] = existingValue;
      }
    });
  }

  void _updateTakesMotionSicknessMedication(
    bool value,
  ) {
    final data =
        widget.activityProfileController.draft.transport;

    setState(() {
      _takesMotionSicknessMedication = value;

      if (!value) {
        data.motionSicknessMedicationNames.clear();

        for (final controller
            in _medicationControllers.values) {
          controller.clear();
        }
      } else if (data
              .motionSicknessTransports.length ==
          1) {
        final onlyTransport =
            data.motionSicknessTransports.first;

        data.motionSicknessMedicationNames[
                onlyTransport] =
            _medicationControllers[onlyTransport]
                    ?.text
                    .trim() ??
                '';
      }
    });

    data.takesMotionSicknessMedication = value;
  }

  void _updateMedicationForTransport(
    TransportMode transportMode,
    bool? value,
  ) {
    final data =
        widget.activityProfileController.draft.transport;

    final isSelected = value ?? false;

    setState(() {
      if (isSelected) {
        data.motionSicknessMedicationNames[
                transportMode] =
            _medicationControllers[transportMode]
                    ?.text
                    .trim() ??
                '';
      } else {
        data.motionSicknessMedicationNames.remove(
          transportMode,
        );

        _medicationControllers[transportMode]?.clear();
      }
    });
  }

  void _updateMedicationName(
    TransportMode transportMode,
    String value,
  ) {
    final data =
        widget.activityProfileController.draft.transport;

    if (!data.motionSicknessMedicationNames
        .containsKey(transportMode)) {
      return;
    }

    data.motionSicknessMedicationNames[
        transportMode] = value.trim();
  }

  void _updateRequiresSpecialEquipment(
    bool value,
  ) {
    final data =
        widget.activityProfileController.draft.transport;

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
    final data =
        widget.activityProfileController.draft.transport;

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
    final transportData =
        widget.activityProfileController.draft.transport;

    final selectedTransports =
        transportData.motionSicknessTransports;

    final hasOneSelectedTransport =
        selectedTransports.length == 1;

    final hasSeveralSelectedTransports =
        selectedTransports.length > 1;

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

            SkYesNoField(
              label:
                  'Votre enfant a-t-il le mal des transports ?',
              value: _motionSickness,
              onChanged: _updateMotionSickness,
            ),

            if (_motionSickness) ...[
              const SizedBox(height: 16),

              const Text(
                'Dans quel(s) moyen(s) de transport votre enfant est-il concerné ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              for (final transportMode
                  in TransportMode.values)
                _buildCheckbox(
                  label:
                      _transportLabel(transportMode),
                  value: selectedTransports.contains(
                    transportMode,
                  ),
                  onChanged: (value) =>
                      _updateMotionSicknessTransport(
                    transportMode,
                    value,
                  ),
                ),

              if (selectedTransports.isNotEmpty) ...[
                const SizedBox(height: 20),

                SkYesNoField(
                  label: hasOneSelectedTransport
                      ? 'Votre enfant prend-il habituellement un médicament avant ce transport ?'
                      : 'Votre enfant prend-il habituellement un médicament avant l’un ou plusieurs de ces transports ?',
                  value:
                      _takesMotionSicknessMedication,
                  onChanged:
                      _updateTakesMotionSicknessMedication,
                ),

                if (_takesMotionSicknessMedication &&
                    hasOneSelectedTransport) ...[
                  const SizedBox(height: 12),

                  SkTextField(
                    label: 'Nom du médicament',
                    controller:
                        _medicationControllers[
                            selectedTransports.first]!,
                    onChanged: (value) =>
                        _updateMedicationName(
                      selectedTransports.first,
                      value,
                    ),
                  ),
                ],

                if (_takesMotionSicknessMedication &&
                    hasSeveralSelectedTransports) ...[
                  const SizedBox(height: 16),

                  const Text(
                    'Pour quel(s) moyen(s) de transport un médicament est-il habituellement pris ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  for (final transportMode
                      in TransportMode.values)
                    if (selectedTransports.contains(
                      transportMode,
                    )) ...[
                      _buildCheckbox(
                        label:
                            _transportLabel(transportMode),
                        value: transportData
                            .motionSicknessMedicationNames
                            .containsKey(
                              transportMode,
                            ),
                        onChanged: (value) =>
                            _updateMedicationForTransport(
                          transportMode,
                          value,
                        ),
                      ),

                      if (transportData
                          .motionSicknessMedicationNames
                          .containsKey(
                            transportMode,
                          )) ...[
                        const SizedBox(height: 8),

                        SkTextField(
                          label:
                              'Nom du médicament – ${_transportLabel(transportMode)}',
                          controller:
                              _medicationControllers[
                                  transportMode]!,
                          onChanged: (value) =>
                              _updateMedicationName(
                            transportMode,
                            value,
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ],
                ],
              ],
            ],

            const SizedBox(height: 24),

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