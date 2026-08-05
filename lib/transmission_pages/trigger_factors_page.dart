import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../models/trigger_factor_data.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'treatments_page.dart';

class TriggerFactorsPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const TriggerFactorsPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<TriggerFactorsPage> createState() =>
      _TriggerFactorsPageState();
}

class _TriggerFactorsPageState
    extends State<TriggerFactorsPage> {
  late bool _hasTriggerFactors;

  late bool _flashingLights;
  late bool _heat;
  late bool _fatigueOrLackOfSleep;
  late bool _noise;
  late bool _crowd;
  late bool _confinedSpaces;
  late bool _physicalEffort;
  late bool _stressOrStrongEmotions;

  late bool _waterContact;
  WaterVigilance? _waterVigilance;

  late bool _animals;
  AnimalVigilance? _animalVigilance;

  late bool _height;
  HeightVigilance? _heightVigilance;

  late final TextEditingController
      _otherWaterVigilanceController;

  late final TextEditingController
      _otherAnimalVigilanceController;

  late final TextEditingController
      _otherHeightVigilanceController;

  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();

    final triggerFactors =
        widget.transmissionController.formData.triggerFactors;

    _hasTriggerFactors =
        triggerFactors.hasTriggerFactors;

    _flashingLights =
        triggerFactors.flashingLights;

    _heat =
        triggerFactors.heat;

    _fatigueOrLackOfSleep =
        triggerFactors.fatigueOrLackOfSleep;

    _noise =
        triggerFactors.noise;

    _crowd =
        triggerFactors.crowd;

    _confinedSpaces =
        triggerFactors.confinedSpaces;

    _physicalEffort =
        triggerFactors.physicalEffort;

    _stressOrStrongEmotions =
        triggerFactors.stressOrStrongEmotions;

    _waterContact =
        triggerFactors.waterContact;

    _waterVigilance =
        triggerFactors.waterVigilance;

    _animals =
        triggerFactors.animals;

    _animalVigilance =
        triggerFactors.animalVigilance;

    _height =
        triggerFactors.height;

    _heightVigilance =
        triggerFactors.heightVigilance;

    _otherWaterVigilanceController =
        TextEditingController(
      text: triggerFactors.otherWaterVigilance ?? '',
    );

    _otherAnimalVigilanceController =
        TextEditingController(
      text: triggerFactors.otherAnimalVigilance ?? '',
    );

    _otherHeightVigilanceController =
        TextEditingController(
      text: triggerFactors.otherHeightVigilance ?? '',
    );

    _otherController = TextEditingController(
      text: triggerFactors.other ?? '',
    );
  }

  @override
  void dispose() {
    _otherWaterVigilanceController.dispose();
    _otherAnimalVigilanceController.dispose();
    _otherHeightVigilanceController.dispose();
    _otherController.dispose();

    super.dispose();
  }

  void _updateHasTriggerFactors(bool value) {
    setState(() {
      _hasTriggerFactors = value;

      if (!value) {
        _flashingLights = false;
        _heat = false;
        _fatigueOrLackOfSleep = false;
        _noise = false;
        _crowd = false;
        _confinedSpaces = false;
        _physicalEffort = false;
        _stressOrStrongEmotions = false;

        _waterContact = false;
        _waterVigilance = null;
        _otherWaterVigilanceController.clear();

        _animals = false;
        _animalVigilance = null;
        _otherAnimalVigilanceController.clear();

        _height = false;
        _heightVigilance = null;
        _otherHeightVigilanceController.clear();

        _otherController.clear();
      }
    });

    widget.transmissionController
        .updateHasTriggerFactors(value);
  }

  void _updateFlashingLights(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _flashingLights = newValue;
    });

    widget.transmissionController
        .updateFlashingLights(newValue);
  }

  void _updateHeat(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _heat = newValue;
    });

    widget.transmissionController
        .updateHeat(newValue);
  }

  void _updateFatigueOrLackOfSleep(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _fatigueOrLackOfSleep = newValue;
    });

    widget.transmissionController
        .updateFatigueOrLackOfSleep(newValue);
  }

  void _updateNoise(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _noise = newValue;
    });

    widget.transmissionController
        .updateNoise(newValue);
  }

  void _updateCrowd(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _crowd = newValue;
    });

    widget.transmissionController
        .updateCrowd(newValue);
  }

  void _updateConfinedSpaces(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _confinedSpaces = newValue;
    });

    widget.transmissionController
        .updateConfinedSpaces(newValue);
  }

  void _updatePhysicalEffort(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _physicalEffort = newValue;
    });

    widget.transmissionController
        .updatePhysicalEffort(newValue);
  }

  void _updateStressOrStrongEmotions(bool? value) {
    final newValue = value ?? false;

    setState(() {
      _stressOrStrongEmotions = newValue;
    });

    widget.transmissionController
        .updateStressOrStrongEmotions(newValue);
  }

  void _updateWaterContact(bool value) {
    setState(() {
      _waterContact = value;

      if (!value) {
        _waterVigilance = null;
        _otherWaterVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateWaterContact(value);
  }

  void _updateWaterVigilance(
    WaterVigilance? value,
  ) {
    setState(() {
      _waterVigilance = value;

      if (value != WaterVigilance.other) {
        _otherWaterVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateWaterVigilance(value);
  }

  void _updateAnimals(bool value) {
    setState(() {
      _animals = value;

      if (!value) {
        _animalVigilance = null;
        _otherAnimalVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateAnimals(value);
  }

  void _updateAnimalVigilance(
    AnimalVigilance? value,
  ) {
    setState(() {
      _animalVigilance = value;

      if (value != AnimalVigilance.other) {
        _otherAnimalVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateAnimalVigilance(value);
  }

  void _updateHeight(bool value) {
    setState(() {
      _height = value;

      if (!value) {
        _heightVigilance = null;
        _otherHeightVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateHeight(value);
  }

  void _updateHeightVigilance(
    HeightVigilance? value,
  ) {
    setState(() {
      _heightVigilance = value;

      if (value != HeightVigilance.other) {
        _otherHeightVigilanceController.clear();
      }
    });

    widget.transmissionController
        .updateHeightVigilance(value);
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreatmentsPage(
          transmissionController:
              widget.transmissionController,
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
      controlAffinity: ListTileControlAffinity.leading,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWaterQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Contact avec l’eau',
        ),
        SkYesNoField(
          label:
              'Le contact avec l’eau nécessite-t-il une vigilance particulière pour votre enfant ?',
          value: _waterContact,
          onChanged: _updateWaterContact,
        ),
        if (_waterContact) ...[
          const SizedBox(height: 12),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RadioGroup<WaterVigilance>(
            groupValue: _waterVigilance,
            onChanged: _updateWaterVigilance,
            child: Column(
              children: const [
                RadioListTile<WaterVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Risque de se jeter dans l’eau',
                  ),
                  value:
                      WaterVigilance.mayJumpIntoWater,
                ),
                RadioListTile<WaterVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Ne sait pas nager',
                  ),
                  value: WaterVigilance.cannotSwim,
                ),
                RadioListTile<WaterVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Autre',
                  ),
                  value: WaterVigilance.other,
                ),
              ],
            ),
          ),
          if (_waterVigilance ==
              WaterVigilance.other) ...[
            const SizedBox(height: 8),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire avec l’eau',
              controller:
                  _otherWaterVigilanceController,
              onChanged: widget.transmissionController
                  .updateOtherWaterVigilance,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAnimalQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Présence d’animaux',
        ),
        SkYesNoField(
          label:
              'La présence d’animaux nécessite-t-elle une vigilance particulière pour votre enfant ?',
          value: _animals,
          onChanged: _updateAnimals,
        ),
        if (_animals) ...[
          const SizedBox(height: 12),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RadioGroup<AnimalVigilance>(
            groupValue: _animalVigilance,
            onChanged: _updateAnimalVigilance,
            child: Column(
              children: const [
                RadioListTile<AnimalVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Peur importante des animaux',
                  ),
                  value:
                      AnimalVigilance.importantFear,
                ),
                RadioListTile<AnimalVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Tendance à s’approcher des animaux sans percevoir le danger',
                  ),
                  value: AnimalVigilance
                      .approachesWithoutPerceivingDanger,
                ),
                RadioListTile<AnimalVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Autre',
                  ),
                  value: AnimalVigilance.other,
                ),
              ],
            ),
          ),
          if (_animalVigilance ==
              AnimalVigilance.other) ...[
            const SizedBox(height: 8),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire avec les animaux',
              controller:
                  _otherAnimalVigilanceController,
              onChanged: widget.transmissionController
                  .updateOtherAnimalVigilance,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildHeightQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Hauteur',
        ),
        SkYesNoField(
          label:
              'La hauteur nécessite-t-elle une vigilance particulière pour votre enfant ?',
          value: _height,
          onChanged: _updateHeight,
        ),
        if (_height) ...[
          const SizedBox(height: 12),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RadioGroup<HeightVigilance>(
            groupValue: _heightVigilance,
            onChanged: _updateHeightVigilance,
            child: Column(
              children: const [
                RadioListTile<HeightVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Absence de perception du danger',
                  ),
                  value: HeightVigilance
                      .doesNotPerceiveDanger,
                ),
                RadioListTile<HeightVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Vertige ou peur importante',
                  ),
                  value: HeightVigilance
                      .vertigoOrImportantFear,
                ),
                RadioListTile<HeightVigilance>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Autre',
                  ),
                  value: HeightVigilance.other,
                ),
              ],
            ),
          ),
          if (_heightVigilance ==
              HeightVigilance.other) ...[
            const SizedBox(height: 8),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire concernant la hauteur',
              controller:
                  _otherHeightVigilanceController,
              onChanged: widget.transmissionController
                  .updateOtherHeightVigilance,
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: '',
      subtitle:
          'Votre enfant présente-t-il des facteurs déclencheurs ou des sensibilités nécessitant une vigilance particulière ?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                'Votre enfant présente-t-il des facteurs déclencheurs ou des sensibilités nécessitant une vigilance particulière ?',
            value: _hasTriggerFactors,
            onChanged: _updateHasTriggerFactors,
          ),
          if (_hasTriggerFactors) ...[
            const SizedBox(height: 24),
            const Text(
              'Sélectionnez les facteurs déclencheurs qui concernent votre enfant.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckbox(
              label:
                  'Lumières clignotantes (photosensibilité)',
              value: _flashingLights,
              onChanged: _updateFlashingLights,
            ),
            _buildCheckbox(
              label: 'Chaleur',
              value: _heat,
              onChanged: _updateHeat,
            ),
            _buildCheckbox(
              label: 'Fatigue ou manque de sommeil',
              value: _fatigueOrLackOfSleep,
              onChanged: _updateFatigueOrLackOfSleep,
            ),
            _buildCheckbox(
              label: 'Bruit',
              value: _noise,
              onChanged: _updateNoise,
            ),
            _buildCheckbox(
              label: 'Foule',
              value: _crowd,
              onChanged: _updateCrowd,
            ),
            _buildCheckbox(
              label: 'Espaces confinés',
              value: _confinedSpaces,
              onChanged: _updateConfinedSpaces,
            ),
            _buildCheckbox(
              label: 'Effort physique',
              value: _physicalEffort,
              onChanged: _updatePhysicalEffort,
            ),
            _buildCheckbox(
              label: 'Stress ou émotions fortes',
              value: _stressOrStrongEmotions,
              onChanged:
                  _updateStressOrStrongEmotions,
            ),
            _buildWaterQuestions(),
            _buildAnimalQuestions(),
            _buildHeightQuestions(),
            const SizedBox(height: 24),
            SkTextField(
              label:
                  'Autre facteur déclencheur ou sensibilité',
              controller: _otherController,
              onChanged: widget.transmissionController
                  .updateOtherTriggerFactor,
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