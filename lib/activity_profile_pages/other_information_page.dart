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
  bool? _hasOtherInformation;
  late bool _showSecondInformation;
  late bool _showThirdInformation;
  late bool _showFourthInformation;

  late final TextEditingController
      _otherInformationController;

  late final TextEditingController
      _secondInformationController;

  late final TextEditingController
      _thirdInformationController;

  late final TextEditingController
      _fourthInformationController;

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

    _thirdInformationController =
        TextEditingController(
      text: data.thirdDetails ?? '',
    );

    _fourthInformationController =
        TextEditingController(
      text: data.fourthDetails ?? '',
    );

    _showSecondInformation =
        data.secondDetails != null &&
        data.secondDetails!.trim().isNotEmpty;

    _showThirdInformation =
        data.thirdDetails != null &&
        data.thirdDetails!.trim().isNotEmpty;

    _showFourthInformation =
        data.fourthDetails != null &&
        data.fourthDetails!.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _otherInformationController.dispose();
    _secondInformationController.dispose();
    _thirdInformationController.dispose();
    _fourthInformationController.dispose();
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
        _showThirdInformation = false;
        _showFourthInformation = false;
        _otherInformationController.clear();
        _secondInformationController.clear();
        _thirdInformationController.clear();
        _fourthInformationController.clear();
      }
    });

    data.hasOtherInformation = value;

    if (!value) {
      data.details = null;
      data.secondDetails = null;
      data.thirdDetails = null;
      data.fourthDetails = null;
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
      _showThirdInformation = false;
      _showFourthInformation = false;
      _secondInformationController.clear();
      _thirdInformationController.clear();
      _fourthInformationController.clear();
    });

    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    data.secondDetails = null;
    data.thirdDetails = null;
    data.fourthDetails = null;
  }

  void _updateThirdInformation(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .otherInformation
            .thirdDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _addThirdInformation() {
    setState(() {
      _showThirdInformation = true;
    });
  }

  void _removeThirdInformation() {
    setState(() {
      _showThirdInformation = false;
      _showFourthInformation = false;
      _thirdInformationController.clear();
      _fourthInformationController.clear();
    });

    final data = widget
        .activityProfileController
        .draft
        .otherInformation;

    data.thirdDetails = null;
    data.fourthDetails = null;
  }

  void _updateFourthInformation(
    String value,
  ) {
    final trimmedValue = value.trim();

    widget
            .activityProfileController
            .draft
            .otherInformation
            .fourthDetails =
        trimmedValue.isEmpty
            ? null
            : trimmedValue;
  }

  void _addFourthInformation() {
    setState(() {
      _showFourthInformation = true;
    });
  }

  void _removeFourthInformation() {
    setState(() {
      _showFourthInformation = false;
      _fourthInformationController.clear();
    });

    widget
        .activityProfileController
        .draft
        .otherInformation
        .fourthDetails = null;
  }

  Future<void> _finish() async {
    // Corrigé (19/08/2026) : aucune page voisine du questionnaire ne
    // laisse "Continuer"/"Terminer" passer sans réponse — celle-ci ne
    // le faisait pas non plus jusqu'ici.
    if (_hasOtherInformation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Répondez par oui ou par non avant de continuer.',
          ),
        ),
      );

      return;
    }

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

    try {
      await ChildRepository.instance
          .saveActivityProfile(
        childId: childId,
        activityProfile: activityProfile,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Impossible d'enregistrer le profil pour le "
              'moment. Vérifiez la connexion. ($error)',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

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

          if (_hasOtherInformation == true) ...[
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

              if (!_showThirdInformation) ...[
                const SizedBox(height: 4),

                TextButton.icon(
                  onPressed:
                      _addThirdInformation,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Ajouter une autre information',
                  ),
                ),
              ],
            ],

            if (_showThirdInformation) ...[
              const SizedBox(height: 20),

              SkTextField(
                label:
                    'Troisième information',
                controller:
                    _thirdInformationController,
                onChanged:
                    _updateThirdInformation,
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      _removeThirdInformation,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Supprimer cette information',
                  ),
                ),
              ),

              if (!_showFourthInformation) ...[
                const SizedBox(height: 4),

                TextButton.icon(
                  onPressed:
                      _addFourthInformation,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Ajouter une autre information',
                  ),
                ),
              ],
            ],

            if (_showFourthInformation) ...[
              const SizedBox(height: 20),

              SkTextField(
                label:
                    'Quatrième information',
                controller:
                    _fourthInformationController,
                onChanged:
                    _updateFourthInformation,
                maxLength: 100,
                helperText:
                    'Réponse courte recommandée (quelques mots ou une phrase courte).',
              ),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      _removeFourthInformation,
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