import 'package:flutter/material.dart';

import 'suppression_compte_service.dart';
import 'suppression_en_cours_page.dart';

/// Barrière posée devant l'accueil : tant qu'une suppression de compte
/// est en cours, rien d'autre que l'écran d'annulation ne s'affiche.
///
/// Placée ici plutôt que dans `HomePage` pour deux raisons. La première
/// est qu'elle couvre d'un coup toutes les façons d'arriver à
/// l'accueil — connexion, vérification d'appareil, nouveau mot de
/// passe. La seconde est que `HomePage` lit directement le SDK et ne se
/// monte pas dans un test ; cette barrière, si.
///
/// Elle double le blocage posé en base par le RLS. Ce n'est pas de la
/// redondance inutile : sans le RLS le blocage ne serait que du
/// décor, et sans cet écran le parent tomberait sur une application
/// vide sans comprendre pourquoi.
class GardeSuppression extends StatefulWidget {
  final Widget enfant;
  final SuppressionCompteService service;

  const GardeSuppression({
    super.key,
    required this.enfant,
    this.service = const SuppressionCompteServiceSupabase(),
  });

  @override
  State<GardeSuppression> createState() =>
      _GardeSuppressionState();
}

class _GardeSuppressionState extends State<GardeSuppression> {
  bool _verification = true;
  DateTime? _effacementLe;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    DateTime? effacement;

    try {
      effacement = await widget.service.suppressionEnCours();
    } catch (_) {
      // Hors ligne, ou fonction absente parce que le fichier SQL n'a
      // pas encore été appliqué : on laisse passer.
      //
      // Choix assumé. Bloquer sur une incertitude enfermerait dehors
      // un parent qui n'a rien demandé, alors que la vraie barrière
      // est en base : sans réseau, il n'y a de toute façon aucune
      // donnée à protéger ici.
      effacement = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _effacementLe = effacement;
      _verification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verification) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final effacement = _effacementLe;

    if (effacement == null) {
      return widget.enfant;
    }

    return SuppressionEnCoursPage(
      effacementLe: effacement,
      service: widget.service,
      onAnnule: () {
        setState(() {
          _effacementLe = null;
        });
      },
    );
  }
}
