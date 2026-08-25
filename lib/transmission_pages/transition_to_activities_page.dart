import 'dart:async';

import 'package:flutter/material.dart';

import '../brouillons/brouillon_profil.dart';
import '../brouillons/enregistrement_brouillon.dart';

import '../activity_profile_pages/activity_profile_entry_page.dart';
import '../children/children_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../controllers/transmission_controller.dart';
import '../models/child_profile_data.dart';
import '../repositories/child_repository.dart';

class TransitionToActivitiesPage extends StatelessWidget {
  final TransmissionController transmissionController;

  const TransitionToActivitiesPage({
    super.key,
    required this.transmissionController,
  });

  Future<ChildProfileData> _saveChild() async {
    final profile =
        transmissionController.validateAndGetProfile();

    await ChildRepository.instance.addChild(profile);

    // Le questionnaire est alle au bout : le brouillon n'a plus de
    // raison d'etre, et il contient des donnees de sante.
    unawaited(
      supprimerBrouillon(
        TypeBrouillon.sante,
        transmissionController.formData.childId,
      ),
    );

    return profile;
  }

  void _showSaveError(
    BuildContext context,
    Object error,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Impossible d'enregistrer le profil pour le "
          'moment. Vérifiez la connexion. ($error)',
        ),
      ),
    );
  }

  Future<void> _finishForNow(
    BuildContext context,
  ) async {
    try {
      await _saveChild();
    } catch (error) {
      if (context.mounted) {
        _showSaveError(context, error);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ChildrenPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _continueToActivities(
    BuildContext context,
  ) async {
    final ChildProfileData childProfile;

    try {
      childProfile = await _saveChild();
    } catch (error) {
      if (context.mounted) {
        _showSaveError(context, error);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    final activityProfileController =
        ActivityProfileController();

    activityProfileController.draft.userId =
        childProfile.userId;

    activityProfileController.draft.childId =
        childProfile.childId;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProfileEntryPage(
          activityProfileController:
              activityProfileController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil de l'enfant",
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.check_circle_outline,
                size: 72,
              ),

              const SizedBox(height: 24),

              const Text(
                "Les informations essentielles de votre enfant sont enregistrées.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Vous venez de terminer la première partie de son profil.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Ces informations permettront notamment de générer une fiche destinée aux services de secours et seront disponibles dans le Mode Urgence.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Vous pouvez poursuivre maintenant en complétant le profil Activités ou revenir plus tard.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Le profil Activités permettra d’adapter automatiquement les recommandations en fonction des activités réalisées par votre enfant.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              FilledButton(
                onPressed: () =>
                    _continueToActivities(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  "Continuer le profil Activités",
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () =>
                    _finishForNow(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  "Terminer pour le moment",
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