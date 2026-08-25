import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';

/// Le cadre commun aux 17 écrans de questionnaire.
///
/// Il portait jusqu'au 25/08/2026 une barre de titre unique — « Profil
/// de l'enfant » — sur les deux questionnaires, alors qu'ils sont
/// distincts et se remplissent séparément. Un parent au milieu du
/// profil Activités n'avait aucun moyen de savoir lequel des deux il
/// remplissait, ni où il en était.
///
/// D'où [barreTitre], [etape] et [total], tous les trois obligatoires :
/// un écran de questionnaire qui ne sait pas dire à quel parcours il
/// appartient ni à quel rang ne devrait pas exister.
class QuestionnairePage extends StatelessWidget {
  /// Le questionnaire auquel cet écran appartient : « Questionnaire
  /// santé » ou « Profil Activités ».
  final String barreTitre;

  /// Rang de cet écran dans son parcours, à partir de 1.
  final int etape;

  /// Nombre d'écrans du parcours.
  final int total;

  final String title;
  final String subtitle;

  /// Ce qui est exigé pour continuer, dit **avant** l'appui.
  ///
  /// Jusqu'ici le parent l'apprenait en étant refusé : le bouton
  /// « Continuer » n'est jamais grisé, et le message n'apparaît
  /// qu'après. Volontairement propre à chaque écran plutôt que commun :
  /// le régime n'est pas le même partout, et une phrase générale serait
  /// fausse quelque part.
  final String? consigne;

  final Widget child;

  const QuestionnairePage({
    super.key,
    required this.barreTitre,
    required this.etape,
    required this.total,
    required this.title,
    required this.subtitle,
    this.consigne,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(barreTitre),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texte seul, pas de barre de progression : « Étape 9 sur
              // 11 » se lit d'un coup, et l'application est sobre
              // partout ailleurs.
              Text(
                'Étape $etape sur $total',
                style: const TextStyle(
                  fontSize: 14,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              if (consigne != null) ...[
                const SizedBox(height: 10),
                Text(
                  consigne!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: KidsRelayColors.ardoiseDouce,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
