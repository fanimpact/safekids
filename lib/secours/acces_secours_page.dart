import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';

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
/// **Pourquoi un écran à lui.** Une autorisation qui laisse quelqu'un
/// d'autre ouvrir un accès sans réponse du parent ne se coche pas en
/// passant, au milieu d'un formulaire.
class AccesSecoursPage extends StatefulWidget {
  final String prenom;

  /// Valeur de départ. Nulle à la création — la case n'est jamais
  /// cochée d'avance —, renseignée quand on revient dessus depuis le
  /// profil de l'enfant.
  final bool valeurInitiale;

  /// Rend la décision. L'appelant décide quoi en faire : l'écrire dans
  /// le brouillon à la création, ou en base depuis le profil.
  final Future<void> Function(bool autorise) onValider;

  /// Ce que porte le bouton. « Continuer » dans le parcours de
  /// création, « Enregistrer » quand on revient dessus.
  final String libelleBouton;

  const AccesSecoursPage({
    super.key,
    required this.prenom,
    required this.onValider,
    this.valeurInitiale = false,
    this.libelleBouton = 'Continuer',
  });

  @override
  State<AccesSecoursPage> createState() => _AccesSecoursPageState();
}

class _AccesSecoursPageState extends State<AccesSecoursPage> {
  late bool _autorise = widget.valeurInitiale;
  bool _enCours = false;

  Future<void> _valider() async {
    setState(() {
      _enCours = true;
    });

    try {
      await widget.onValider(_autorise);
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
      Navigator.pop(context, _autorise);
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

              // Material et non Container : une CheckboxListTile peint
              // son fond et ses effets tactiles sur le Material le plus
              // proche. Posee sur une simple boite coloree, la case ne
              // montrerait rien quand on la touche.
              Material(
                color: KidsRelayColors.lin,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: KidsRelayColors.bordure,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _autorise,
                        onChanged: (valeur) {
                          setState(() {
                            _autorise = valeur ?? false;
                          });
                        },
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Autoriser l’accès secours pour $prenom.',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

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

              const SizedBox(height: 32),

              FilledButton(
                // Actif dans les deux cas, contrairement au
                // consentement de santé : refuser ici n'empêche rien.
                // Ne rien cocher est déjà une réponse, et elle se
                // change.
                onPressed: _enCours ? null : _valider,
                child: _enCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.libelleBouton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
