import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';

/// Ce que le parent a répondu, ou n'a pas répondu.
///
/// **Trois valeurs et non un booléen**, parce qu'une case non cochée ne
/// prouve rien : on ne peut pas distinguer un parent qui a refusé d'un
/// parent qui a lu en travers. Or la base légale est l'intérêt vital
/// **renforcé par une préautorisation donnée à froid** — c'est elle qui
/// doit pouvoir être démontrée, et un silence ne se démontre pas.
enum ReponseAccesSecours {
  accepte,
  refuse,

  /// Le parent a poursuivi sans répondre. La question reste ouverte, et
  /// se repose depuis le profil de l'enfant.
  plusTard,
}

/// La préautorisation de l'accès secours, donnée une fois par enfant.
///
/// **Pourquoi ici et pas à la création de chaque partage.** Elle y
/// était d'abord. Le parent aurait dû y penser à chaque fois — et le
/// jour où il oublie serait le jour de l'accident. Décision de Fanny,
/// 28/08/2026.
///
/// **Pourquoi après le questionnaire et non avant.** Le consentement de
/// santé demande « puis-je enregistrer ces informations ? » avant
/// qu'elles existent. Celui-ci demande « puis-je les laisser sortir en
/// urgence ? » — il ne peut pas être posé avant que le parent ait vu ce
/// que la fiche contient.
///
/// **Pourquoi deux boutons et non une case.** Voir
/// [ReponseAccesSecours]. Les deux ont strictement le même poids
/// visuel : si « J'accepte » était plus visible que « Je refuse », le
/// refus ne serait plus libre, et l'intérêt juridique de la démarche
/// disparaîtrait avec lui.
class AccesSecoursPage extends StatefulWidget {
  final String prenom;

  /// Ce qui avait été répondu, s'il y a lieu. Nul quand la question
  /// n'a jamais été posée.
  final bool? valeurInitiale;

  /// Enregistre la décision. L'appelant décide quoi en faire : l'écrire
  /// dans le brouillon à la création, ou en base depuis le profil.
  /// N'est pas appelée quand le parent poursuit sans répondre.
  final Future<void> Function(bool autorise) onRepondre;

  const AccesSecoursPage({
    super.key,
    required this.prenom,
    required this.onRepondre,
    this.valeurInitiale,
  });

  @override
  State<AccesSecoursPage> createState() => _AccesSecoursPageState();
}

class _AccesSecoursPageState extends State<AccesSecoursPage> {
  bool _enCours = false;

  Future<void> _repondre(bool autorise) async {
    setState(() {
      _enCours = true;
    });

    try {
      await widget.onRepondre(autorise);
    } catch (erreur) {
      if (mounted) {
        setState(() {
          _enCours = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d’enregistrer ce choix pour le moment. '
              'Vérifiez la connexion.',
            ),
          ),
        );
      }

      return;
    }

    if (mounted) {
      Navigator.pop(
        context,
        autorise
            ? ReponseAccesSecours.accepte
            : ReponseAccesSecours.refuse,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom = widget.prenom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('En cas d’urgence'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              const Text(
                'En cas d’urgence',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Vous venez de renseigner les informations de santé de '
                '$prenom. Une dernière question, et elle ne se posera '
                'plus.',
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),

              const SizedBox(height: 16),

              Text(
                'Si $prenom part un jour avec les secours, la personne '
                'qui l’accompagne — une maîtresse, une animatrice, un '
                'proche — peut avoir besoin de montrer ces informations '
                'aux soignants qui le prennent en charge. Sans '
                'autorisation donnée à l’avance, elle devra attendre '
                'que vous répondiez.',
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: KidsRelayColors.lin,
                  border: Border.all(
                    color: KidsRelayColors.bordure,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autorisez-vous l’accès secours pour $prenom ?',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Toute personne à qui vous partagez sa fiche '
                      'pourra, si $prenom part avec les secours, '
                      'montrer les informations pour les secours aux '
                      'soignants et transmettre l’accès à celle qui '
                      'l’accompagne — sans attendre votre réponse.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Vous êtes prévenu immédiatement, et vous pouvez y '
                'mettre fin à tout moment. Cet accès ne donne que les '
                'informations pour les secours, et dure 24 heures.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Vous pourrez revenir sur ce choix à tout moment depuis '
                'le profil de $prenom.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),

              const SizedBox(height: 28),

              // Les deux réponses, à poids strictement égal : même
              // widget, même largeur, aucune couleur d'accent, aucune
              // pré-sélection. Un « J'accepte » plus visible que « Je
              // refuse » rendrait le refus moins libre, et la
              // préautorisation perdrait la valeur qu'on lui cherche.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _enCours ? null : () => _repondre(true),
                      child: const Text('J’accepte'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _enCours ? null : () => _repondre(false),
                      child: const Text('Je refuse'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Poursuivre sans répondre reste possible : l'absence de
              // réponse ne doit pas bloquer la création du profil. En
              // lien discret, parce que ce n'est pas l'une des deux
              // réponses — c'est l'absence de réponse.
              Center(
                child: TextButton(
                  onPressed: _enCours
                      ? null
                      : () => Navigator.pop(
                            context,
                            ReponseAccesSecours.plusTard,
                          ),
                  child: const Text('Répondre plus tard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
