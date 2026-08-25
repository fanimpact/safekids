import 'dart:async';

import 'package:flutter/material.dart';

import '../brouillons/enregistrement_brouillon.dart';

import '../controllers/transmission_controller.dart';
import '../models/trigger_factor_data.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'treatments_page.dart';

class TriggerFactorsPage extends StatefulWidget {
  final TransmissionController
      transmissionController;

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
  bool? _flashingLights;
  bool? _requiresGlassesOutdoors;

  bool? _heat;
  bool? _fatigueOrLackOfSleep;
  bool? _noise;
  bool? _crowd;
  bool? _confinedSpaces;
  bool? _physicalEffort;
  bool? _stressOrStrongEmotions;

  bool? _waterContact;
  WaterVigilance? _waterVigilance;

  bool? _animals;
  AnimalVigilance? _animalVigilance;

  bool? _height;
  HeightVigilance? _heightVigilance;

  late final TextEditingController
      _otherWaterVigilanceController;

  late final TextEditingController
      _otherAnimalVigilanceController;

  late final TextEditingController
      _otherHeightVigilanceController;

  late final TextEditingController
      _otherController;

  @override
  void initState() {
    super.initState();

    final triggerFactors = widget
        .transmissionController
        .formData
        .triggerFactors;

    _flashingLights =
        triggerFactors.flashingLights;

    _requiresGlassesOutdoors =
        triggerFactors.requiresGlassesOutdoors;

    _heat = triggerFactors.heat;

    _fatigueOrLackOfSleep =
        triggerFactors.fatigueOrLackOfSleep;

    _noise = triggerFactors.noise;

    _crowd = triggerFactors.crowd;

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
      text:
          triggerFactors
              .otherWaterVigilance ??
          '',
    );

    _otherAnimalVigilanceController =
        TextEditingController(
      text:
          triggerFactors
              .otherAnimalVigilance ??
          '',
    );

    _otherHeightVigilanceController =
        TextEditingController(
      text:
          triggerFactors
              .otherHeightVigilance ??
          '',
    );

    _otherController =
        TextEditingController(
      text: triggerFactors.other ?? '',
    );
  }

  @override
  void dispose() {
    _otherWaterVigilanceController
        .dispose();
    _otherAnimalVigilanceController
        .dispose();
    _otherHeightVigilanceController
        .dispose();
    _otherController.dispose();

    super.dispose();
  }

  void _updateFlashingLights(
    bool value,
  ) {
    setState(() {
      _flashingLights = value;

      if (!value) {
        _requiresGlassesOutdoors =
            null;
      }
    });

    widget.transmissionController
        .updateFlashingLights(value);
  }

  void _updateRequiresGlassesOutdoors(
    bool value,
  ) {
    setState(() {
      _requiresGlassesOutdoors =
          value;
    });

    widget.transmissionController
        .updateRequiresGlassesOutdoors(
      value,
    );
  }

  void _updateHeat(bool value) {
    setState(() {
      _heat = value;
    });

    widget.transmissionController
        .updateHeat(value);
  }

  void _updateFatigueOrLackOfSleep(
    bool value,
  ) {
    setState(() {
      _fatigueOrLackOfSleep = value;
    });

    widget.transmissionController
        .updateFatigueOrLackOfSleep(
      value,
    );
  }

  void _updateNoise(bool value) {
    setState(() {
      _noise = value;
    });

    widget.transmissionController
        .updateNoise(value);
  }

  void _updateCrowd(bool value) {
    setState(() {
      _crowd = value;
    });

    widget.transmissionController
        .updateCrowd(value);
  }

  void _updateConfinedSpaces(
    bool value,
  ) {
    setState(() {
      _confinedSpaces = value;
    });

    widget.transmissionController
        .updateConfinedSpaces(value);
  }

  void _updatePhysicalEffort(
    bool value,
  ) {
    setState(() {
      _physicalEffort = value;
    });

    widget.transmissionController
        .updatePhysicalEffort(value);
  }

  void _updateStressOrStrongEmotions(
    bool value,
  ) {
    setState(() {
      _stressOrStrongEmotions = value;
    });

    widget.transmissionController
        .updateStressOrStrongEmotions(
      value,
    );
  }

  void _updateWaterContact(
    bool value,
  ) {
    setState(() {
      _waterContact = value;

      if (!value) {
        _waterVigilance = null;
        _otherWaterVigilanceController
            .clear();
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

      if (value !=
          WaterVigilance.other) {
        _otherWaterVigilanceController
            .clear();
      }
    });

    widget.transmissionController
        .updateWaterVigilance(value);
  }

  void _updateAnimals(
    bool value,
  ) {
    setState(() {
      _animals = value;

      if (!value) {
        _animalVigilance = null;
        _otherAnimalVigilanceController
            .clear();
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

      if (value !=
          AnimalVigilance.other) {
        _otherAnimalVigilanceController
            .clear();
      }
    });

    widget.transmissionController
        .updateAnimalVigilance(value);
  }

  void _updateHeight(
    bool value,
  ) {
    setState(() {
      _height = value;

      if (!value) {
        _heightVigilance = null;
        _otherHeightVigilanceController
            .clear();
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

      if (value !=
          HeightVigilance.other) {
        _otherHeightVigilanceController
            .clear();
      }
    });

    widget.transmissionController
        .updateHeightVigilance(value);
  }

  void _continue() {
    final hasUnansweredFactor =
        _flashingLights == null ||
            (_flashingLights == true &&
                _requiresGlassesOutdoors == null) ||
            _heat == null ||
            _fatigueOrLackOfSleep == null ||
            _noise == null ||
            _crowd == null ||
            _confinedSpaces == null ||
            _physicalEffort == null ||
            _stressOrStrongEmotions == null ||
            _waterContact == null ||
            _animals == null ||
            _height == null;

    if (hasUnansweredFactor) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Répondez par oui ou par non à chaque facteur déclencheur avant de continuer.",
          ),
        ),
      );

      return;
    }

    // Le brouillon est ecrit a chaque ecran valide : sans cela, un
    // parent interrompu au cinquieme des six ecrans perdait les cinq.
    unawaited(
      enregistrerBrouillonSante(
        widget.transmissionController.formData,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TreatmentsPage(
          transmissionController:
              widget
                  .transmissionController,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWaterQuestions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Contact avec l’eau',
        ),
        SkYesNoField(
          label:
              'Le contact avec l’eau nécessite-t-il une vigilance particulière pour votre enfant ?',
          value: _waterContact,
          onChanged:
              _updateWaterContact,
        ),
        if (_waterContact == true) ...[
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          RadioGroup<WaterVigilance>(
            groupValue:
                _waterVigilance,
            onChanged:
                _updateWaterVigilance,
            child: const Column(
              children: [
                RadioListTile<
                    WaterVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Risque de se jeter dans l’eau',
                  ),
                  value:
                      WaterVigilance
                          .mayJumpIntoWater,
                ),
                RadioListTile<
                    WaterVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Ne sait pas nager',
                  ),
                  value:
                      WaterVigilance
                          .cannotSwim,
                ),
                RadioListTile<
                    WaterVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title:
                      Text('Autre'),
                  value:
                      WaterVigilance
                          .other,
                ),
              ],
            ),
          ),
          if (_waterVigilance ==
              WaterVigilance.other) ...[
            const SizedBox(
              height: 8,
            ),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire avec l’eau',
              controller:
                  _otherWaterVigilanceController,
              onChanged: widget
                  .transmissionController
                  .updateOtherWaterVigilance,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAnimalQuestions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Présence d’animaux',
        ),
        SkYesNoField(
          label:
              'La présence d’animaux nécessite-t-elle une vigilance particulière pour votre enfant ?',
          value: _animals,
          onChanged:
              _updateAnimals,
        ),
        if (_animals == true) ...[
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          RadioGroup<
              AnimalVigilance>(
            groupValue:
                _animalVigilance,
            onChanged:
                _updateAnimalVigilance,
            child: const Column(
              children: [
                RadioListTile<
                    AnimalVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Peur importante des animaux',
                  ),
                  value:
                      AnimalVigilance
                          .importantFear,
                ),
                RadioListTile<
                    AnimalVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Tendance à s’approcher des animaux sans percevoir le danger',
                  ),
                  value:
                      AnimalVigilance
                          .approachesWithoutPerceivingDanger,
                ),
                RadioListTile<
                    AnimalVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title:
                      Text('Autre'),
                  value:
                      AnimalVigilance
                          .other,
                ),
              ],
            ),
          ),
          if (_animalVigilance ==
              AnimalVigilance.other) ...[
            const SizedBox(
              height: 8,
            ),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire avec les animaux',
              controller:
                  _otherAnimalVigilanceController,
              onChanged: widget
                  .transmissionController
                  .updateOtherAnimalVigilance,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildHeightQuestions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Hauteur',
        ),
        SkYesNoField(
          label:
              'La hauteur nécessite-t-elle une vigilance particulière pour votre enfant ?',
          value: _height,
          onChanged:
              _updateHeight,
        ),
        if (_height == true) ...[
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Quelle vigilance est nécessaire ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          RadioGroup<
              HeightVigilance>(
            groupValue:
                _heightVigilance,
            onChanged:
                _updateHeightVigilance,
            child: const Column(
              children: [
                RadioListTile<
                    HeightVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Absence de perception du danger',
                  ),
                  value:
                      HeightVigilance
                          .doesNotPerceiveDanger,
                ),
                RadioListTile<
                    HeightVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text(
                    'Vertige ou peur importante',
                  ),
                  value:
                      HeightVigilance
                          .vertigoOrImportantFear,
                ),
                RadioListTile<
                    HeightVigilance>(
                  contentPadding:
                      EdgeInsets.zero,
                  title:
                      Text('Autre'),
                  value:
                      HeightVigilance
                          .other,
                ),
              ],
            ),
          ),
          if (_heightVigilance ==
              HeightVigilance.other) ...[
            const SizedBox(
              height: 8,
            ),
            SkTextField(
              label:
                  'Précisez la vigilance nécessaire concernant la hauteur',
              controller:
                  _otherHeightVigilanceController,
              onChanged: widget
                  .transmissionController
                  .updateOtherHeightVigilance,
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return QuestionnairePage(
      barreTitre: 'Questionnaire santé',
      etape: 4,
      total: 6,
      title: 'Facteurs déclenchants',
      subtitle:
          'Ce qui peut provoquer un problème, pour que l’accompagnant l’évite ou s’y prépare.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Répondez à chaque question ci-dessous.',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SkYesNoField(
              label:
                  'Les lumières clignotantes (photosensibilité) nécessitent-elles une vigilance particulière pour votre enfant ?',
              value:
                  _flashingLights,
              onChanged:
                  _updateFlashingLights,
            ),

            if (_flashingLights == true) ...[
              const SizedBox(
                height: 12,
              ),

              SkYesNoField(
                label:
                    'Le port de lunettes est-il nécessaire lors des activités en extérieur ?',
                value:
                    _requiresGlassesOutdoors,
                onChanged:
                    _updateRequiresGlassesOutdoors,
              ),
            ],

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'La chaleur nécessite-t-elle une vigilance particulière pour votre enfant ?',
              value: _heat,
              onChanged:
                  _updateHeat,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'La fatigue ou le manque de sommeil nécessitent-ils une vigilance particulière pour votre enfant ?',
              value:
                  _fatigueOrLackOfSleep,
              onChanged:
                  _updateFatigueOrLackOfSleep,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'Le bruit nécessite-t-il une vigilance particulière pour votre enfant ?',
              value: _noise,
              onChanged:
                  _updateNoise,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'La foule nécessite-t-elle une vigilance particulière pour votre enfant ?',
              value: _crowd,
              onChanged:
                  _updateCrowd,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'Les espaces confinés nécessitent-ils une vigilance particulière pour votre enfant ?',
              value:
                  _confinedSpaces,
              onChanged:
                  _updateConfinedSpaces,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'L’effort physique nécessite-t-il une vigilance particulière pour votre enfant ?',
              value:
                  _physicalEffort,
              onChanged:
                  _updatePhysicalEffort,
            ),

            const SizedBox(
              height: 24,
            ),

            SkYesNoField(
              label:
                  'Le stress ou les émotions fortes nécessitent-ils une vigilance particulière pour votre enfant ?',
              value:
                  _stressOrStrongEmotions,
              onChanged:
                  _updateStressOrStrongEmotions,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildWaterQuestions(),
            _buildAnimalQuestions(),
            _buildHeightQuestions(),

            const SizedBox(
              height: 24,
            ),

            SkTextField(
              label:
                  'Autre facteur déclencheur ou sensibilité',
              controller:
                  _otherController,
              onChanged: widget
                  .transmissionController
                  .updateOtherTriggerFactor,
            ),

          const SizedBox(
            height: 30,
          ),

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