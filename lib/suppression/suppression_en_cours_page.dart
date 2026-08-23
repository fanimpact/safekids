import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';
import 'jours_restants.dart';
import 'suppression_compte_service.dart';

/// Le seul écran accessible tant qu'une suppression de compte est en
/// cours.
///
/// Volontairement sans barre de navigation et sans aucune autre issue
/// que l'annulation : « le compte devient inaccessible tout de suite »
/// serait faux si l'on pouvait continuer à consulter les fiches.
///
/// Ce n'est pas un écran d'erreur pour autant. Le parent a demandé
/// cette suppression ; ce qu'il doit trouver ici, c'est la date, ce qui
/// va disparaître, et le moyen de revenir en arrière.
class SuppressionEnCoursPage extends StatefulWidget {
  final DateTime effacementLe;
  final SuppressionCompteService service;

  /// Appelée après une annulation réussie : c'est l'appelant qui
  /// décide comment revenir à l'application.
  final VoidCallback onAnnule;

  /// Injectée pour les tests.
  final DateTime Function() horloge;

  const SuppressionEnCoursPage({
    super.key,
    required this.effacementLe,
    required this.onAnnule,
    this.service = const SuppressionCompteServiceSupabase(),
    this.horloge = DateTime.now,
  });

  @override
  State<SuppressionEnCoursPage> createState() =>
      _SuppressionEnCoursPageState();
}

class _SuppressionEnCoursPageState
    extends State<SuppressionEnCoursPage> {
  bool _annulationEnCours = false;

  Future<void> _annuler() async {
    setState(() {
      _annulationEnCours = true;
    });

    try {
      await widget.service.annulerSuppression();

      if (mounted) {
        widget.onAnnule();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d’annuler pour l’instant. Vérifiez votre '
              'connexion et réessayez : vos données ne seront pas '
              'effacées avant la date indiquée.',
            ),
            duration: Duration(seconds: 8),
          ),
        );

      }
    } finally {
      // Remis a zero meme apres une annulation reussie : l'appelant
      // n'est pas oblige de remplacer cet ecran, et un indicateur qui
      // tourne indefiniment ferait croire a un blocage.
      if (mounted) {
        setState(() {
          _annulationEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restant = joursRestants(
      widget.effacementLe,
      widget.horloge(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppression en cours'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: KidsRelayColors.ambreFond,
                  border: Border.all(
                    color: KidsRelayColors.ambreBordure,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      texteJoursRestants(restant),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vos données seront effacées définitivement le '
                      '${formaterDateHeureFr(widget.effacementLe)}.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Votre compte n’est plus accessible depuis votre '
                'demande. Les profils de vos enfants, les liens de '
                'partage et les rattachements aux établissements sont '
                'déjà hors service.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),

              const SizedBox(height: 16),

              const Text(
                'Rien n’est encore effacé. Si vous annulez avant la '
                'date indiquée, vous retrouverez tout en l’état.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),

              const SizedBox(height: 16),

              const Text(
                'Passé cette date, l’effacement est définitif et nous '
                'ne pourrons rien restaurer.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: _annulationEnCours ? null : _annuler,
                child: _annulationEnCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Annuler la suppression et retrouver mon '
                        'compte',
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
