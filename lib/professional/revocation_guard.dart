import 'dart:async';

import 'package:flutter/material.dart';

import 'professional_child_repository.dart';

/// Enveloppe une fiche professionnelle (ou un enfant en Mode Urgence)
/// et surveille, tant qu'elle reste ouverte, que l'accès à cet enfant
/// n'a pas été révoqué ou n'a pas expiré entre-temps — corrections de
/// l'audit passe 3, item 13 : l'accès serveur est déjà coupé
/// immédiatement à la révocation (vérifié par impersonation RLS), mais
/// un onglet déjà ouvert continuait d'afficher les données déjà
/// chargées jusqu'au rechargement. Ici, la fiche se ferme d'elle-même.
///
/// Le contrôle réutilise la même règle RLS que le reste de l'app
/// (`enfant_visible_par_etablissement`) : une lecture périodique et
/// légère de la ligne `enfants` correspondante. Si elle ne revient
/// plus rien, l'accès a été perdu.
class RevocationGuard extends StatefulWidget {
  final String childId;
  final Widget child;

  const RevocationGuard({
    super.key,
    required this.childId,
    required this.child,
  });

  @override
  State<RevocationGuard> createState() =>
      _RevocationGuardState();
}

class _RevocationGuardState extends State<RevocationGuard> {
  static const _checkInterval = Duration(seconds: 20);

  Timer? _timer;
  Route<dynamic>? _myRoute;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capturé une seule fois : la route associée à CETTE fiche, pour
    // pouvoir refermer exactement jusque-là (y compris si l'utilisateur
    // a navigué plus loin depuis, ex. Mode Urgence -> consigne).
    _myRoute ??= ModalRoute.of(context);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      _checkInterval,
      (_) => _checkStillAccessible(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStillAccessible() async {
    if (_closing || !mounted) {
      return;
    }

    // Ne ferme jamais sur un simple problème réseau passager —
    // uniquement sur une absence confirmée (RLS a refusé la ligne).
    // C'est le dépôt qui porte cette garantie : il renvoie `true` en
    // cas d'erreur.
    final stillVisible = await ProfessionalChildRepository.instance
        .childStillVisible(widget.childId);

    if (!stillVisible) {
      await _closeForRevocation();
    }
  }

  Future<void> _closeForRevocation() async {
    if (_closing || !mounted) {
      return;
    }

    _closing = true;
    _timer?.cancel();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Accès révoqué'),
        content: const Text(
          'L’accès à la fiche de cet enfant a été révoqué ou a '
          'expiré. Vous allez revenir à l’accueil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context);
    final myRoute = _myRoute;

    if (myRoute != null) {
      navigator.popUntil((route) => route == myRoute);
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
