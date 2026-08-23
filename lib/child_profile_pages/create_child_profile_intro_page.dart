import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../consentement/consentement_sante_page.dart';

class CreateChildProfileIntroPage extends StatelessWidget {
  const CreateChildProfileIntroPage({
    super.key,
  });

  void _startProfile(BuildContext context) {
    final transmissionController =
        TransmissionController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsentementSantePage(
          transmissionController:
              transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créer le profil de votre enfant',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.child_care,
                size: 72,
              ),

              const SizedBox(height: 28),

              const Text(
                'Créer le profil de votre enfant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Le profil de votre enfant regroupe toutes les informations qui permettront de personnaliser son accompagnement.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Il ne sera créé qu’une seule fois, puis pourra être mis à jour à tout moment.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Toutes les fonctionnalités de l’application s’appuieront ensuite sur ces informations, notamment :',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '• la préparation des activités ;\n'
                '• la génération des informations essentielles destinées aux services de secours ;\n'
                '• le Mode Urgence.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Prenez simplement le temps de compléter ce profil avec soin.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'La création du profil est la première étape. Une fois celui-ci terminé, vous pourrez souscrire un abonnement afin d’accéder à l’ensemble des fonctionnalités de l’application.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Cet abonnement est prévu pour une famille. Il vous permettra notamment :',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '• d’inviter jusqu’à deux personnes de confiance à gérer les profils de vos enfants, par exemple l’autre parent ou un responsable légal ;\n'
                '• de partager, sans limite, des liens sécurisés avec les personnes qui accompagnent ponctuellement votre enfant : enseignants, animateurs, clubs sportifs, centres de loisirs, proches, etc.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Les accompagnants recevront uniquement les informations que vous choisirez de partager avec eux. Vous pourrez modifier ou supprimer ces autorisations à tout moment.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: () =>
                    _startProfile(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  'Commencer le profil de mon enfant',
                  textAlign: TextAlign.center,
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