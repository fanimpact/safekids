import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';
import 'jours_restants.dart';
import 'suppression_compte_service.dart';

/// La section « Supprimer mon compte » de l'écran Paramètres.
///
/// Placée là et nulle part ailleurs : c'est une action administrative,
/// elle n'a rien à faire sur un chemin d'usage.
///
/// Deux confirmations avant d'agir, et jamais de rouge. Supprimer son
/// compte est une action lourde mais délibérée, pas une urgence
/// vitale — le poids vient du libellé, de ce qui est énuméré, et du
/// mot à saisir.
class SectionSuppressionCompte extends StatefulWidget {
  final SuppressionCompteService service;

  /// Appelée après une demande enregistrée : l'appelant décide comment
  /// renvoyer le parent vers l'écran de blocage.
  final void Function(DateTime effacementLe)? onDemandeEnregistree;

  const SectionSuppressionCompte({
    super.key,
    this.service = const SuppressionCompteServiceSupabase(),
    this.onDemandeEnregistree,
  });

  @override
  State<SectionSuppressionCompte> createState() =>
      _SectionSuppressionCompteState();
}

class _SectionSuppressionCompteState
    extends State<SectionSuppressionCompte> {
  bool _demandeEnCours = false;

  // Champ de l'etat et non variable locale : liberer le controleur
  // des la fermeture de la fenetre le detruirait pendant que
  // l'animation de sortie s'en sert encore.
  final _motDeConfirmation = TextEditingController();

  @override
  void dispose() {
    _motDeConfirmation.dispose();
    super.dispose();
  }

  void _afficher(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  /// Saisir un mot plutôt qu'appuyer sur « Oui ». Un second bouton se
  /// tape sans réfléchir ; recopier « SUPPRIMER » demande de lire.
  Future<bool> _confirmer() async {
    _motDeConfirmation.clear();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, majEtat) => AlertDialog(
          title: const Text('Supprimer votre compte ?'),
          // Defilable : sur un petit ecran, ou avec une grande taille de
          // police, cette liste depasse la hauteur disponible.
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Seront effacés définitivement : les profils de tous '
                'vos enfants, leurs informations de santé, vos '
                'activités préparées, vos liens de partage et vos '
                'rattachements aux établissements.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre compte deviendra inaccessible immédiatement. '
                'Vous aurez 7 jours pour changer d’avis avant '
                'l’effacement définitif.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Saisissez SUPPRIMER pour confirmer.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _motDeConfirmation,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'SUPPRIMER',
                ),
                onChanged: (_) => majEtat(() {}),
              ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: _motDeConfirmation.text.trim().toUpperCase() ==
                      'SUPPRIMER'
                  ? () => Navigator.pop(context, true)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: KidsRelayColors.ardoise,
              ),
              child: const Text('Supprimer mon compte'),
            ),
          ],
        ),
      ),
    );

    return confirme == true;
  }

  Future<void> _demander() async {
    if (!await _confirmer() || !mounted) {
      return;
    }

    setState(() {
      _demandeEnCours = true;
    });

    DateTime? effacement;

    try {
      effacement = await widget.service.demanderSuppression();
    } catch (_) {
      if (mounted) {
        _afficher(
          'Impossible d’enregistrer votre demande. Vérifiez votre '
          'connexion et réessayez. Rien n’a été supprimé.',
        );

        setState(() {
          _demandeEnCours = false;
        });
      }

      return;
    }

    // L'email est envoyé après coup, et son échec ne remet pas en
    // cause la demande : elle est déjà enregistrée. Mais le parent
    // doit l'apprendre, sinon il attendrait un email qui ne viendra
    // pas — et c'est là que se trouve le moyen d'annuler.
    var emailEnvoye = true;

    try {
      await widget.service.envoyerEmailConfirmation(effacement);
    } catch (_) {
      emailEnvoye = false;
    }

    if (!mounted) {
      return;
    }

    _afficher(
      emailEnvoye
          ? 'Demande enregistrée. Un email vous confirme la date '
              'd’effacement et la façon d’annuler.'
          : 'Demande enregistrée pour le '
              '${formaterDateFr(effacement)}. L’email de confirmation '
              'n’a pas pu être envoyé : notez cette date, vous '
              'pourrez annuler depuis l’application.',
    );

    widget.onDemandeEnregistree?.call(effacement);

    setState(() {
      _demandeEnCours = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Supprimer mon compte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Votre compte devient inaccessible immédiatement, et tout '
          'est effacé définitivement 7 jours plus tard. Pendant ce '
          'délai, vous pouvez revenir en arrière et tout retrouver.',
          style: TextStyle(
            fontSize: 14,
            color: KidsRelayColors.ardoiseDouce,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pensez à exporter vos données avant, si vous souhaitez en '
          'garder une copie.',
          style: TextStyle(
            fontSize: 14,
            color: KidsRelayColors.ardoiseDouce,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _demandeEnCours ? null : _demander,
          icon: _demandeEnCours
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_remove_outlined),
          label: const Text('Supprimer mon compte'),
        ),
      ],
    );
  }
}
