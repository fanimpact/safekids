import 'dart:async';

import 'package:flutter/material.dart';

import '../secours/code_qr.dart';
import '../services/service_exception.dart';
import '../theme/kidsrelay_theme.dart';
import 'share_link_service.dart';

/// Le code à faire scanner, en présentiel.
///
/// **Ce n'est pas un second mécanisme de partage.** La ligne affichée
/// ici est une ligne `partages` ordinaire : même jeton, même page
/// publique, même verrou, même révocation, même place dans la liste du
/// parent. Seule s'y ajoute une fenêtre de cinq minutes pendant
/// laquelle le jeton peut être réclamé pour la première fois.
///
/// **Les deux durées ne se mélangent pas.** Les cinq minutes ne
/// concernent que le code. Une fois scanné, l'accès dure ce que le
/// parent a choisi avant de venir ici — 24 h, 3 jours, 7 jours, 1 mois,
/// 1 an, une date au calendrier, ou sans date de fin.
///
/// **Le décompte repart à chaque retour sur l'écran** (décision de
/// Fanny, 28/08/2026) : le code n'est visible que sur le téléphone du
/// parent, rien n'a été transmis tant que personne n'a scanné, et il
/// n'y a donc rien à protéger contre lui-même. Le parent peut aller
/// consulter autre chose et revenir sans être pénalisé.
///
/// **Rien à imprimer, partager, copier ni enregistrer.** Le code
/// s'affiche, c'est tout. Aucune protection contre la capture d'écran
/// n'est tentée : elle n'existerait que sur Android, et Fanny a
/// tranché pour le même comportement sur les deux systèmes. Ce qui
/// protège, ce sont les cinq minutes et le verrou du nombre
/// d'appareils — une photo du code ne vaut rien passé le délai, et si
/// le destinataire a scanné entre-temps, la place est prise.
class EcranCodePartage extends StatefulWidget {
  final String partageId;
  final String nomDestinataire;

  /// Ce que dure l'accès une fois le code scanné, déjà formulé par
  /// l'écran de création — c'est lui qui connaît le choix du parent.
  final String texteDuree;

  const EcranCodePartage({
    super.key,
    required this.partageId,
    required this.nomDestinataire,
    required this.texteDuree,
  });

  @override
  State<EcranCodePartage> createState() => _EcranCodePartageState();
}

class _EcranCodePartageState extends State<EcranCodePartage>
    with WidgetsBindingObserver {
  CodePartage? _code;
  String? _erreur;
  bool _enCours = false;
  Timer? _horloge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rafraichir();
  }

  @override
  void dispose() {
    _horloge?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Revenir dans l'application relance les cinq minutes, au même
  /// titre que revenir sur l'écran.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !(_code?.dejaScanne ?? false)) {
      _rafraichir();
    }
  }

  Future<void> _rafraichir() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });

    try {
      final code =
          await ShareLinkService.instance.rafraichirCode(widget.partageId);

      if (!mounted) {
        return;
      }

      setState(() {
        _code = code;
        _enCours = false;
      });

      _lancerHorloge();
    } on ServiceException catch (error) {
      _echouer(error.message);
    } catch (error) {
      _echouer('Le code n’a pas pu être affiché. Réessayez.');
    }
  }

  void _echouer(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _enCours = false;
      _erreur = message;
    });
  }

  /// Une seconde : le parent tend son téléphone, il doit voir le temps
  /// descendre pour savoir s'il a le temps ou s'il doit rafficher.
  void _lancerHorloge() {
    _horloge?.cancel();

    if (_code?.dejaScanne ?? false) {
      return;
    }

    _horloge = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Duration get _restant {
    final code = _code;

    if (code == null) {
      return Duration.zero;
    }

    final reste = code.utilisableJusquA.difference(DateTime.now());

    return reste.isNegative ? Duration.zero : reste;
  }

  bool get _perime => _code != null && _restant == Duration.zero;

  String get _compteARebours {
    final reste = _restant;
    final minutes = reste.inMinutes;
    final secondes = reste.inSeconds % 60;

    return '$minutes min ${secondes.toString().padLeft(2, '0')} s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Code à scanner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pour ${widget.nomDestinataire}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.texteDuree,
              style: const TextStyle(
                fontSize: 15,
                color: KidsRelayColors.ardoiseDouce,
              ),
            ),
            const SizedBox(height: 24),
            ..._corps(),
          ],
        ),
      ),
    );
  }

  List<Widget> _corps() {
    final erreur = _erreur;

    if (erreur != null) {
      return [
        Text(erreur, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _enCours ? null : _rafraichir,
          child: const Text('Réessayer'),
        ),
      ];
    }

    final code = _code;

    if (code == null) {
      return const [
        Center(child: CircularProgressIndicator()),
      ];
    }

    if (code.dejaScanne) {
      return [
        Card(
          color: KidsRelayColors.ambreFond,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: KidsRelayColors.ambreBordure),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ce code a été scanné. L’accès est ouvert, et vous le '
              'retrouvez dans la fiche de l’enfant, section '
              '« Partages ». C’est là que vous pourrez le couper.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ];
    }

    if (_perime) {
      return [
        const Text(
          'Ce code n’est plus valable.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Un code vaut cinq minutes. En afficher un nouveau annule '
          'le précédent : si quelqu’un l’avait photographié, la photo '
          'ne servira plus à rien.',
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _enCours ? null : _rafraichir,
          child: const Text('Afficher un nouveau code'),
        ),
      ];
    }

    return [
      const Text(
        'Faites scanner ce code avec l’appareil photo du téléphone '
        'de la personne. Elle n’a besoin d’aucune application.',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 20),
      Center(child: CodeQr(donnees: code.url, taille: 280)),
      const SizedBox(height: 12),

      // L'adresse en clair sous le code, exactement comme sur l'écran
      // de l'accès secours : une seule logique dans toute
      // l'application. La recopier à la main ne donne rien de plus que
      // photographier le code, et les deux cessent de fonctionner au
      // bout de cinq minutes — mais si le scan ne prend pas, elle
      // dépanne immédiatement.
      Card(
        color: KidsRelayColors.lin,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            code.url,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'Valable encore $_compteARebours',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 4),
      const Center(
        child: Text(
          'Passé ce délai, affichez-en un nouveau.',
          style: TextStyle(
            fontSize: 14,
            color: KidsRelayColors.ardoiseDouce,
          ),
        ),
      ),
    ];
  }
}
