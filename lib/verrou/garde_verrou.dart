import 'package:flutter/material.dart';

import '../auth/account_service.dart';
import '../theme/kidsrelay_theme.dart';
import 'verrou_appareil.dart';

/// Pose le verrou de l'appareil devant l'espace connecté, au démarrage
/// **et** au retour au premier plan.
///
/// **Ce qu'il protège, et ce qu'il ne protège pas.** Le verrou est
/// celui du téléphone : celui qui tient un téléphone déverrouillé le
/// franchira avec le même doigt. Il protège donc contre un téléphone
/// déverrouillé laissé sur une table ou confié à un enfant, et rien de
/// plus. C'est modeste, et c'est assumé — un mot de passe de compte
/// protégerait davantage et enfermerait dehors le parent au moment où
/// il en a le plus besoin.
///
/// **Le Mode Urgence ne passe pas avant.** Décision du 28/08/2026 : le
/// gain serait nul, puisque le même doigt ouvre les deux.
class GardeVerrou extends StatefulWidget {
  final Widget enfant;

  /// Injecté pour les tests.
  final VerrouAppareil? verrou;

  const GardeVerrou({
    super.key,
    required this.enfant,
    this.verrou,
  });

  @override
  State<GardeVerrou> createState() => _GardeVerrouState();
}

class _GardeVerrouState extends State<GardeVerrou>
    with WidgetsBindingObserver {
  /// Nul tant qu'on n'a pas encore décidé.
  bool? _ouvert;

  bool _demandeEnCours = false;

  VerrouAppareil get _verrou =>
      widget.verrou ?? VerrouAppareil.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifier();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Le verrou se pose aussi au retour d'arriere-plan : sans cela, un
    // telephone repris trois heures plus tard s'ouvrirait sur la fiche
    // de l'enfant sans rien demander.
    if (etat == AppLifecycleState.resumed && _ouvert == true) {
      _verifier();
    }

    // Le passage en arriere-plan ne marque PAS d'ouverture : c'est le
    // retour qui compte, et marquer ici repousserait l'echeance a
    // chaque coup d'oeil.
  }

  Future<void> _verifier() async {
    if (_demandeEnCours) {
      return;
    }

    _demandeEnCours = true;

    try {
      if (!await _verrou.estRequis()) {
        await _verrou.marquerOuverture();

        if (mounted) {
          setState(() {
            _ouvert = true;
          });
        }

        return;
      }

      final resultat = await _verrou.demander();

      if (mounted) {
        setState(() {
          _ouvert = resultat != ResultatVerrou.refuse;
        });
      }
    } finally {
      _demandeEnCours = false;
    }
  }

  Future<void> _seDeconnecter() async {
    try {
      await AccountService.instance.signOut();
    } catch (_) {
      // Meme hors connexion, on quitte l'ecran : rester bloque ici
      // serait pire.
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ouvert == true) {
      return widget.enfant;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: KidsRelayColors.ardoiseDouce,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Déverrouillez pour continuer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Ces informations sont protégées par le '
                  'déverrouillage de votre téléphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: KidsRelayColors.ardoiseDouce,
                  ),
                ),

                const SizedBox(height: 32),

                if (_ouvert == false)
                  FilledButton(
                    onPressed: _verifier,
                    child: const Text('Réessayer'),
                  ),

                const SizedBox(height: 8),

                // Le seul autre chemin, et il n'est pas le mot de passe
                // du compte : se deconnecter et repartir de l'ecran
                // d'entree. Personne ne doit rester enferme ici.
                if (_ouvert == false)
                  TextButton(
                    onPressed: _seDeconnecter,
                    child: const Text('Se déconnecter'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
