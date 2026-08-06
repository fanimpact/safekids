import 'package:flutter/material.dart';

class ActivityCharacteristicsPage extends StatefulWidget {
  const ActivityCharacteristicsPage({
    super.key,
  });

  @override
  State<ActivityCharacteristicsPage> createState() =>
      _ActivityCharacteristicsPageState();
}

class _ActivityCharacteristicsPageState
    extends State<ActivityCharacteristicsPage> {
  bool _water = false;
  bool _transport = false;
  bool _prolongedWalking = false;
  bool _significantPhysicalEffort = false;
  bool _severalHours = false;
  bool _overnightStay = false;
  bool _meal = false;
  bool _clothingChange = false;

  bool _outdoors = false;
  bool _flashingLights = false;
  bool _importantNoise = false;
  bool _importantCrowd = false;
  bool _animals = false;
  bool _height = false;

  bool _prolongedWaiting = false;
  bool _remainCalmOrStill = false;
  bool _dangerousTools = false;
  bool _otherCharacteristic = false;

  final TextEditingController
      _otherCharacteristicController =
      TextEditingController();

  @override
  void dispose() {
    _otherCharacteristicController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 28,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
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

  void _continue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La suite du questionnaire sera ajoutée à l’étape suivante.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Caractéristiques de l’activité',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Indiquez ce qui est réellement prévu pendant cette activité.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                ),
              ),

              _buildSectionTitle(
                'Déroulement de l’activité',
              ),

              _buildCheckbox(
                label:
                    'Contact avec l’eau ou proximité d’un point d’eau',
                value: _water,
                onChanged: (value) {
                  setState(() {
                    _water = value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label: 'Transport prévu',
                value: _transport,
                onChanged: (value) {
                  setState(() {
                    _transport = value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Marche prolongée ou distance importante à parcourir',
                value: _prolongedWalking,
                onChanged: (value) {
                  setState(() {
                    _prolongedWalking =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Effort physique important',
                value:
                    _significantPhysicalEffort,
                onChanged: (value) {
                  setState(() {
                    _significantPhysicalEffort =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Activité d’une durée de plusieurs heures',
                value: _severalHours,
                onChanged: (value) {
                  setState(() {
                    _severalHours =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Séjour avec une ou plusieurs nuitées',
                value: _overnightStay,
                onChanged: (value) {
                  setState(() {
                    _overnightStay =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label: 'Repas ou goûter prévu',
                value: _meal,
                onChanged: (value) {
                  setState(() {
                    _meal = value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Changement de tenue nécessaire',
                value: _clothingChange,
                onChanged: (value) {
                  setState(() {
                    _clothingChange =
                        value ?? false;
                  });
                },
              ),

              _buildSectionTitle(
                'Environnement',
              ),

              _buildCheckbox(
                label:
                    'Activité principalement en extérieur',
                value: _outdoors,
                onChanged: (value) {
                  setState(() {
                    _outdoors = value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Lumières clignotantes, flashs ou effets lumineux',
                value: _flashingLights,
                onChanged: (value) {
                  setState(() {
                    _flashingLights =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Bruit important ou environnement sonore intense',
                value: _importantNoise,
                onChanged: (value) {
                  setState(() {
                    _importantNoise =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Foule ou forte fréquentation',
                value: _importantCrowd,
                onChanged: (value) {
                  setState(() {
                    _importantCrowd =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Présence ou proximité d’animaux',
                value: _animals,
                onChanged: (value) {
                  setState(() {
                    _animals = value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Présence de hauteur, vide, escaliers importants ou plateformes',
                value: _height,
                onChanged: (value) {
                  setState(() {
                    _height = value ?? false;
                  });
                },
              ),

              _buildSectionTitle(
                'Organisation et vigilance',
              ),

              _buildCheckbox(
                label:
                    'Attente prolongée ou temps morts importants',
                value: _prolongedWaiting,
                onChanged: (value) {
                  setState(() {
                    _prolongedWaiting =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Nécessité de rester calme ou immobile longtemps',
                value: _remainCalmOrStill,
                onChanged: (value) {
                  setState(() {
                    _remainCalmOrStill =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Utilisation d’outils, de matériel ou d’équipements présentant un risque',
                value: _dangerousTools,
                onChanged: (value) {
                  setState(() {
                    _dangerousTools =
                        value ?? false;
                  });
                },
              ),

              _buildCheckbox(
                label:
                    'Autre caractéristique importante',
                value: _otherCharacteristic,
                onChanged: (value) {
                  final newValue =
                      value ?? false;

                  setState(() {
                    _otherCharacteristic =
                        newValue;

                    if (!newValue) {
                      _otherCharacteristicController
                          .clear();
                    }
                  });
                },
              ),

              if (_otherCharacteristic) ...[
                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      _otherCharacteristicController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Précisez cette caractéristique',
                    border:
                        OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],

              const SizedBox(height: 36),

              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}