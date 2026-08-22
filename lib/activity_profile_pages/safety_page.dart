import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';
import 'meals_page.dart';

class SafetyPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const SafetyPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<SafetyPage> createState() =>
      _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  bool? _mayLeaveGroupSuddenly;
  bool? _requiresSafetyEquipment;

  late final TextEditingController
      _safetyEquipmentController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .safety;

    _mayLeaveGroupSuddenly =
        data.mayLeaveGroupSuddenly;

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

  void _updateMayLeaveGroupSuddenly(
    bool value,
  ) {
    setState(() {
      _mayLeaveGroupSuddenly = value;
    });

    widget
        .activityProfileController
        .draft
        .safety
        .mayLeaveGroupSuddenly = value;
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
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _continue() {
    if (_mayLeaveGroupSuddenly == null ||
        _requiresSafetyEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez par oui ou par non à chaque question avant de continuer.',
          ),
        ),
      );

      return;
    }

    widget.activityProfileController
        .validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MealsPage(
          activityProfileController:
              widget
                  .activityProfileController,
        ),
      ),
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
                'Votre enfant est-il susceptible de quitter brusquement le groupe ?',
            value:
                _mayLeaveGroupSuddenly,
            onChanged:
                _updateMayLeaveGroupSuddenly,
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

          if (_requiresSafetyEquipment == true) ...[
            const SizedBox(height: 12),

            SkTextField(
              label:
                  'Précisez l’équipement de sécurité nécessaire',
              controller:
                  _safetyEquipmentController,
              onChanged:
                  _updateSafetyEquipmentDetails,
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),

            const SizedBox(height: 8),

            const Text(
              'Exemples : casque de protection, autre équipement indispensable à sa sécurité.',
              style: TextStyle(
                fontSize: 14,
              ),
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