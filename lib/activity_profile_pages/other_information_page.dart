import 'package:flutter/material.dart';

import '../children/children_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../repositories/child_repository.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import '../widgets/sk_yes_no_field.dart';

class OtherInformationPage extends StatefulWidget {
  final ActivityProfileController activityProfileController;

  const OtherInformationPage({
    super.key,
    required this.activityProfileController,
  });

  @override
  State<OtherInformationPage> createState() =>
      _OtherInformationPageState();
}

class _OtherInformationPageState
    extends State<OtherInformationPage> {
  late bool _hasOtherInformation;
  late bool _showSecondInformation;

  late final TextEditingController
      _otherInformationController;

  late final TextEditingController
      _secondInformationController;

  @override
  void initState() {
    super.initState();

    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    _hasOtherInformation =
        data.hasOtherInformation;

    _otherInformationController =
        TextEditingController(
      text: data.details ?? '',
    );

    _secondInformationController =
        TextEditingController(
      text: data.secondDetails ?? '',
    );

    _showSecondInformation =
        data.secondDetails != null &&
        data.secondDetails!.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _otherInformationController.dispose();
    _secondInformationController.dispose();
    super.dispose();
  }

  void _updateHasOtherInformation(
    bool value,
  ) {
    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    setState(() {
      _hasOtherInformation = value;

      if (!value) {
        _showSecondInformation = false;
        _otherInformationController.clear();
        _secondInformationController.clear();
      }
    });

    data.hasOtherInformation = value;

    if (!value) {
      data.details = null;
      data.secondDetails = null;
    }
  }

  void _updateOtherInformation(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .otherInformation
            .details =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _updateSecondInformation(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .otherInformation
            .secondDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _addSecondInformation() {
    setState(() {
      _showSecondInformation = true;
    });
  }

  void _removeSecondInformation() {
    setState(() {
      _showSecondInformation = false;
      _secondInformationController.clear();
    });

    widget
        .activityProfileController
        .draft
        .otherInformation
        .secondDetails = null;
  }

  void _finish() {
    final activityProfileController =
        widget.activityProfileController;

    final childId =
        activityProfileController
            .draft
            .childId;

    final activityProfile =
        activityProfileController
            .validateAndGetProfile();

    if (childId == null ||
        childId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de retrouver le profil de l’enfant.',
          ),
        ),
      );

      return;
    }

    ChildRepository.instance
        .saveActivityProfile(
      childId: childId,
      activityProfile: activityProfile,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ChildrenPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnairePage(
      title: 'Autres informations',
      subtitle:
          'Dernière étape du questionnaire.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SkYesNoField(
            label:
                "Y a-t-il une autre information importante concernant l'accompagnement de votre enfant que nous n'avons pas abordée ?",
            value:
                _hasOtherInformation,
            onChanged:
                _updateHasOtherInformation,
          ),

          if (_hasOtherInformation) ...[
            const SizedBox(height: 24),

            SkTextField(
              label:
                  'Précisez cette information',
              controller:
                  _otherInformationController,
              onChanged:
                  _updateOtherInformation,
              maxLength: 100,
              helperText:
                  'Réponse courte recommandée (quelques mots ou une phrase courte).',
            ),

            if (!_showSecondInformation) ...[
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed:
                    _addSecondInformation,
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Ajouter une autre information',
                ),
              ),
            ],

            if (_showSecondInformation) ...[
              const SizedBox(height: 20),

              SkTextField(
                label:
                    'Deuxième information',
                controller:
                    _secondInformationController,
                onChanged:
                    _updateSecondInformation,
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      _removeSecondInformation,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Supprimer cette information',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            const Text(
              'Ces informations seront ajoutées au profil de votre enfant et pourront être transmises aux personnes que vous autoriserez.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 32),

          const Text(
            "Important : tout matériel ou équipement spécifique indiqué dans ce questionnaire doit être fourni par le parent ou le responsable légal. Il n'est pas à la charge de l'accompagnant.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: _finish,
            child: const Text(
              'Terminer',
            ),
          ),
        ],
      ),
    );
  }
}