import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../models/meals_data.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'other_information_page.dart';

/// Section "Repas" du profil Activités (22/08/2026). Aucune question
/// filtre : les neuf questions sont posées à tous les parents, comme
/// les autres sections depuis la correction du 19/08/2026.
///
/// Les allergies alimentaires et leurs traitements ne sont jamais
/// redemandés ici — l'encart en tête de section le dit au parent, et
/// c'est `MealsRules` qui va les chercher dans le profil santé quand
/// l'activité comprend un repas.
class MealsPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const MealsPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  bool? _hasChokingRisk;
  bool? _requiresSpecificSeating;
  bool? _hasWarningSigns;
  bool? _requiresAssistance;
  MealAssistanceLevel? _assistanceLevel;
  bool? _requiresSpecialEquipment;
  bool? _requiresIncreasedHydration;
  bool? _hasDietaryRestrictions;
  bool? _hasFoodRefusals;
  MealRefusalStance? _refusalStance;
  bool? _hasOtherInformation;

  late final TextEditingController _otherPreparationController;
  late final TextEditingController _seatingController;
  late final TextEditingController _warningSignsController;
  late final TextEditingController _specialEquipmentController;
  late final TextEditingController _otherRestrictionController;
  late final TextEditingController _foodRefusalController;
  late final TextEditingController _otherInformationController;

  static const Map<MealPreparation, String> _preparationLabels = {
    MealPreparation.smallPieces: 'Couper en petits morceaux',
    MealPreparation.minced: 'Alimentation hachée',
    MealPreparation.blended: 'Alimentation mixée',
    MealPreparation.thickenedDrinks: 'Boissons épaissies',
    MealPreparation.other: 'Autre',
  };

  static const Map<MealAssistanceLevel, String> _assistanceLabels = {
    MealAssistanceLevel.adultNearby:
        'Il mange seul mais quelqu’un doit rester à côté de lui',
    MealAssistanceLevel.helpWithSomeGestures:
        'Il a besoin d’aide sur certains gestes (couper, ouvrir, '
            'porter à la bouche)',
    MealAssistanceLevel.fullyFedByAdult:
        'Il doit être nourri entièrement par un adulte',
  };

  static const Map<MealDietaryRestriction, String> _restrictionLabels = {
    MealDietaryRestriction.glutenFree: 'Sans gluten',
    MealDietaryRestriction.lactoseFree: 'Sans lactose',
    MealDietaryRestriction.porkFree: 'Sans porc',
    MealDietaryRestriction.vegetarian: 'Végétarien',
    MealDietaryRestriction.other: 'Autre',
  };

  static const Map<MealRefusalStance, String> _refusalStanceLabels = {
    MealRefusalStance.insist: 'Oui',
    MealRefusalStance.doNotInsist: 'Non',
  };

  MealsData get _data =>
      widget.activityProfileController.draft.meals;

  @override
  void initState() {
    super.initState();

    final data = _data;

    _hasChokingRisk = data.hasChokingRisk;
    _requiresSpecificSeating = data.requiresSpecificSeating;
    _hasWarningSigns = data.hasWarningSigns;
    _requiresAssistance = data.requiresAssistance;
    _assistanceLevel = data.assistanceLevel;
    _requiresSpecialEquipment = data.requiresSpecialEquipment;
    _requiresIncreasedHydration = data.requiresIncreasedHydration;
    _hasDietaryRestrictions = data.hasDietaryRestrictions;
    _hasFoodRefusals = data.hasFoodRefusals;
    _refusalStance = data.refusalStance;
    _hasOtherInformation = data.hasOtherInformation;

    _otherPreparationController = TextEditingController(
      text: data.otherPreparationDetails ?? '',
    );
    _seatingController = TextEditingController(
      text: data.seatingDetails ?? '',
    );
    _warningSignsController = TextEditingController(
      text: data.warningSignsDetails ?? '',
    );
    _specialEquipmentController = TextEditingController(
      text: data.specialEquipmentDetails ?? '',
    );
    _otherRestrictionController = TextEditingController(
      text: data.otherDietaryRestrictionDetails ?? '',
    );
    _foodRefusalController = TextEditingController(
      text: data.foodRefusalDetails ?? '',
    );
    _otherInformationController = TextEditingController(
      text: data.otherInformationDetails ?? '',
    );
  }

  @override
  void dispose() {
    _otherPreparationController.dispose();
    _seatingController.dispose();
    _warningSignsController.dispose();
    _specialEquipmentController.dispose();
    _otherRestrictionController.dispose();
    _foodRefusalController.dispose();
    _otherInformationController.dispose();

    super.dispose();
  }

  String? _trimmedOrNull(String value) {
    final trimmedValue = value.trim();

    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _updateHasChokingRisk(bool value) {
    setState(() {
      _hasChokingRisk = value;

      if (!value) {
        _otherPreparationController.clear();
      }
    });

    _data.hasChokingRisk = value;

    if (!value) {
      _data.preparations.clear();
      _data.otherPreparationDetails = null;
    }
  }

  void _updatePreparation(MealPreparation preparation, bool selected) {
    setState(() {
      if (selected) {
        _data.preparations.add(preparation);
      } else {
        _data.preparations.remove(preparation);

        if (preparation == MealPreparation.other) {
          _otherPreparationController.clear();
          _data.otherPreparationDetails = null;
        }
      }
    });
  }

  void _updateRequiresSpecificSeating(bool value) {
    setState(() {
      _requiresSpecificSeating = value;

      if (!value) {
        _seatingController.clear();
      }
    });

    _data.requiresSpecificSeating = value;

    if (!value) {
      _data.seatingDetails = null;
    }
  }

  void _updateHasWarningSigns(bool value) {
    setState(() {
      _hasWarningSigns = value;

      if (!value) {
        _warningSignsController.clear();
      }
    });

    _data.hasWarningSigns = value;

    if (!value) {
      _data.warningSignsDetails = null;
    }
  }

  void _updateRequiresAssistance(bool value) {
    setState(() {
      _requiresAssistance = value;

      if (!value) {
        _assistanceLevel = null;
      }
    });

    _data.requiresAssistance = value;

    if (!value) {
      _data.assistanceLevel = null;
    }
  }

  void _updateAssistanceLevel(MealAssistanceLevel? value) {
    setState(() {
      _assistanceLevel = value;
    });

    _data.assistanceLevel = value;
  }

  void _updateRequiresSpecialEquipment(bool value) {
    setState(() {
      _requiresSpecialEquipment = value;

      if (!value) {
        _specialEquipmentController.clear();
      }
    });

    _data.requiresSpecialEquipment = value;

    if (!value) {
      _data.specialEquipmentDetails = null;
    }
  }

  void _updateRequiresIncreasedHydration(bool value) {
    setState(() {
      _requiresIncreasedHydration = value;
    });

    _data.requiresIncreasedHydration = value;
  }

  void _updateHasDietaryRestrictions(bool value) {
    setState(() {
      _hasDietaryRestrictions = value;

      if (!value) {
        _otherRestrictionController.clear();
      }
    });

    _data.hasDietaryRestrictions = value;

    if (!value) {
      _data.dietaryRestrictions.clear();
      _data.otherDietaryRestrictionDetails = null;
    }
  }

  void _updateDietaryRestriction(
    MealDietaryRestriction restriction,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _data.dietaryRestrictions.add(restriction);
      } else {
        _data.dietaryRestrictions.remove(restriction);

        if (restriction == MealDietaryRestriction.other) {
          _otherRestrictionController.clear();
          _data.otherDietaryRestrictionDetails = null;
        }
      }
    });
  }

  void _updateHasFoodRefusals(bool value) {
    setState(() {
      _hasFoodRefusals = value;

      if (!value) {
        _foodRefusalController.clear();
        _refusalStance = null;
      }
    });

    _data.hasFoodRefusals = value;

    if (!value) {
      _data.foodRefusalDetails = null;
      _data.refusalStance = null;
    }
  }

  void _updateRefusalStance(MealRefusalStance? value) {
    setState(() {
      _refusalStance = value;
    });

    _data.refusalStance = value;
  }

  void _updateHasOtherInformation(bool value) {
    setState(() {
      _hasOtherInformation = value;

      if (!value) {
        _otherInformationController.clear();
      }
    });

    _data.hasOtherInformation = value;

    if (!value) {
      _data.otherInformationDetails = null;
    }
  }

  void _continue() {
    final hasUnansweredQuestion = _hasChokingRisk == null ||
        _requiresSpecificSeating == null ||
        _hasWarningSigns == null ||
        _requiresAssistance == null ||
        _requiresSpecialEquipment == null ||
        _requiresIncreasedHydration == null ||
        _hasDietaryRestrictions == null ||
        _hasFoodRefusals == null ||
        _hasOtherInformation == null;

    if (hasUnansweredQuestion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez par oui ou par non à chaque question avant de continuer.',
          ),
        ),
      );

      return;
    }

    widget.activityProfileController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherInformationPage(
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSingleChoice<T extends Enum>({
    required String label,
    required Map<T, String> labels,
    required T? value,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        RadioGroup<T>(
          groupValue: value,
          onChanged: onChanged,
          child: Column(
            children: [
              for (final entry in labels.entries)
                RadioListTile<T>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  value: entry.key,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Repas',
      subtitle:
          'Répondez aux questions concernant votre enfant.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Si votre enfant a des allergies alimentaires, inutile '
              'de les ressaisir ici : elles seront reprises '
              'automatiquement depuis son profil santé.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildSectionTitle('Sécurité pendant le repas'),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                'Votre enfant présente-t-il un risque de fausse route ou d’étouffement ?',
            value: _hasChokingRisk,
            onChanged: _updateHasChokingRisk,
          ),

          if (_hasChokingRisk == true) ...[
            const SizedBox(height: 12),

            const Text(
              'Comment faut-il préparer ses repas et ses boissons ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            for (final entry in _preparationLabels.entries)
              _buildCheckbox(
                label: entry.value,
                value: _data.preparations.contains(entry.key),
                onChanged: (value) => _updatePreparation(
                  entry.key,
                  value ?? false,
                ),
              ),

            if (_data.preparations.contains(
              MealPreparation.other,
            )) ...[
              const SizedBox(height: 12),

              SkTextField(
                label: 'Précisez cette préparation',
                controller: _otherPreparationController,
                onChanged: (value) {
                  _data.otherPreparationDetails =
                      _trimmedOrNull(value);
                },
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),
            ],
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Votre enfant doit-il être installé d’une façon particulière pour manger ?',
            value: _requiresSpecificSeating,
            onChanged: _updateRequiresSpecificSeating,
          ),

          if (_requiresSpecificSeating == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label: 'Précisez cette installation',
              controller: _seatingController,
              onChanged: (value) {
                _data.seatingDetails = _trimmedOrNull(value);
              },
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Y a-t-il des signes qui doivent alerter l’accompagnant pendant ou après le repas ?',
            value: _hasWarningSigns,
            onChanged: _updateHasWarningSigns,
          ),

          if (_hasWarningSigns == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label: 'Lesquels, et que faire dans ce cas',
              controller: _warningSignsController,
              onChanged: (value) {
                _data.warningSignsDetails = _trimmedOrNull(value);
              },
              maxLength: 300,
              maxLines: 3,
              helperText:
                  'Décrivez les signes et la conduite à tenir.',
            ),
          ],

          const SizedBox(height: 36),

          _buildSectionTitle('Autonomie au repas'),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                'Votre enfant a-t-il besoin d’aide pendant la prise du repas ?',
            value: _requiresAssistance,
            onChanged: _updateRequiresAssistance,
          ),

          if (_requiresAssistance == true) ...[
            const SizedBox(height: 12),

            _buildSingleChoice<MealAssistanceLevel>(
              label: 'De quelle aide s’agit-il ?',
              labels: _assistanceLabels,
              value: _assistanceLevel,
              onChanged: _updateAssistanceLevel,
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Votre enfant a-t-il besoin de matériel particulier pour manger dans de bonnes conditions ?',
            value: _requiresSpecialEquipment,
            onChanged: _updateRequiresSpecialEquipment,
          ),

          if (_requiresSpecialEquipment == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label: 'Matériel nécessaire',
              controller: _specialEquipmentController,
              onChanged: (value) {
                _data.specialEquipmentDetails =
                    _trimmedOrNull(value);
              },
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),

            const SizedBox(height: 8),

            const Text(
              'Exemples : couverts adaptés, verre à bec, set antidérapant, casque anti-bruit, autre…',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Votre enfant a-t-il besoin d’une hydratation renforcée pour raison médicale ?',
            value: _requiresIncreasedHydration,
            onChanged: _updateRequiresIncreasedHydration,
          ),

          const SizedBox(height: 36),

          _buildSectionTitle('Alimentation'),

          const SizedBox(height: 20),

          SkYesNoField(
            label:
                'Y a-t-il des aliments que votre enfant ne doit pas manger ?',
            value: _hasDietaryRestrictions,
            onChanged: _updateHasDietaryRestrictions,
          ),

          if (_hasDietaryRestrictions == true) ...[
            const SizedBox(height: 12),

            for (final entry in _restrictionLabels.entries)
              _buildCheckbox(
                label: entry.value,
                value: _data.dietaryRestrictions.contains(entry.key),
                onChanged: (value) => _updateDietaryRestriction(
                  entry.key,
                  value ?? false,
                ),
              ),

            if (_data.dietaryRestrictions.contains(
              MealDietaryRestriction.other,
            )) ...[
              const SizedBox(height: 12),

              SkTextField(
                label: 'Précisez ce régime',
                controller: _otherRestrictionController,
                onChanged: (value) {
                  _data.otherDietaryRestrictionDetails =
                      _trimmedOrNull(value);
                },
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),
            ],
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Y a-t-il des aliments que votre enfant refuse ou ne tolère pas ?',
            value: _hasFoodRefusals,
            onChanged: _updateHasFoodRefusals,
          ),

          if (_hasFoodRefusals == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label: 'Lesquels',
              controller: _foodRefusalController,
              onChanged: (value) {
                _data.foodRefusalDetails = _trimmedOrNull(value);
              },
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),

            const SizedBox(height: 16),

            _buildSingleChoice<MealRefusalStance>(
              label: 'L’accompagnant doit-il insister ?',
              labels: _refusalStanceLabels,
              value: _refusalStance,
              onChanged: _updateRefusalStance,
            ),
          ],

          const SizedBox(height: 24),

          SkYesNoField(
            label:
                'Y a-t-il autre chose d’important à savoir sur les repas de votre enfant ?',
            value: _hasOtherInformation,
            onChanged: _updateHasOtherInformation,
          ),

          if (_hasOtherInformation == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label: 'Précisez cette information',
              controller: _otherInformationController,
              onChanged: (value) {
                _data.otherInformationDetails =
                    _trimmedOrNull(value);
              },
              maxLength: 300,
              maxLines: 3,
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
