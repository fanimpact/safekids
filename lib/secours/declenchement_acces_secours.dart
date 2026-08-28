// Le geste « L'enfant part avec les secours », DANS L'APPLICATION.
//
// Il existait deja sur la page publique d'un lien de partage. Mais
// dans une ecole, l'enfant est la par rattachement : le professionnel
// passe par l'application, et ne voyait donc jamais le bouton — c'est
// pourtant lui qui monte dans le camion.
//
// Trois decisions de Fanny gouvernent ces ecrans (28/08/2026) :
//
//   - la preautorisation du parent vaut pour tous les canaux. Il a
//     repondu une fois par enfant ; on ne lui redemande rien, et son
//     refus est refuse ici comme ailleurs ;
//   - tout membre actif peut declencher. On ne sait pas d'avance qui
//     accompagnera l'enfant ; reserver le bouton a un role recreerait
//     le probleme qu'on cherche a resoudre ;
//   - le bouton est en bas de la fiche secours, pas dans un menu.
//     C'est l'ecran qu'on a sous les yeux au moment ou ca arrive.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/service_exception.dart';
import '../theme/kidsrelay_theme.dart';
import 'code_qr.dart';
import 'service_acces_secours.dart';

/// Le bloc posé en pied de la fiche secours.
///
/// S'il existe déjà un accès ouvert, il propose de le **remontrer** au
/// lieu d'en ouvrir un autre : un soignant arrive après les autres, un
/// téléphone s'éteint.
class BoutonAccesSecours extends StatefulWidget {
  final String enfantId;
  final String etablissementId;

  const BoutonAccesSecours({
    super.key,
    required this.enfantId,
    required this.etablissementId,
  });

  @override
  State<BoutonAccesSecours> createState() => _BoutonAccesSecoursState();
}

class _BoutonAccesSecoursState extends State<BoutonAccesSecours> {
  AccesSecoursOuvert? _ouvert;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _chercherExistant();
  }

  /// Silencieux à dessein : si la lecture échoue, le bouton reste
  /// proposé. Un déclenchement retrouvera l'accès existant de toute
  /// façon — mieux vaut un bouton de trop qu'un geste indisponible.
  Future<void> _chercherExistant() async {
    try {
      final deja = await ServiceAccesSecours.instance.accesEnCours(
        enfantId: widget.enfantId,
        etablissementId: widget.etablissementId,
      );

      if (mounted && deja != null) {
        setState(() => _ouvert = deja);
      }
    } catch (_) {
      // Voir ci-dessus.
    }
  }

  Future<void> _confirmer() async {
    final accepte = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EcranConfirmationSecours(),
      ),
    );

    if (accepte != true || !mounted) {
      return;
    }

    setState(() => _enCours = true);

    try {
      final ouvert = await ServiceAccesSecours.instance.declencher(
        enfantId: widget.enfantId,
        etablissementId: widget.etablissementId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ouvert = ouvert;
        _enCours = false;
      });

      _montrer(ouvert);
    } on ServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _enCours = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _montrer(AccesSecoursOuvert ouvert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranAccesSecoursOuvert(
          acces: ouvert,
          etablissementId: widget.etablissementId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ouvert = _ouvert;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ouvert != null) ...[
            Card(
              color: KidsRelayColors.ambreFond,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  color: KidsRelayColors.ambreBordure,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Un accès secours est déjà ouvert pour cet enfant. '
                  'Montrez-le à chaque nouvelle personne qui le prend '
                  'en charge.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _montrer(ouvert),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Revoir l’accès secours'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _enCours ? null : _confirmer,
              style: FilledButton.styleFrom(
                backgroundColor: KidsRelayColors.urgence,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: _enCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_hospital_outlined),
              label: const Text('L’enfant part avec les secours'),
            ),
        ],
      ),
    );
  }
}

/// L'écran de confirmation, mot pour mot celui de la page publique.
///
/// Le même geste doit se dire de la même façon selon qu'on tient un
/// lien ou qu'on passe par l'application : la conséquence est la même.
class EcranConfirmationSecours extends StatelessWidget {
  const EcranConfirmationSecours({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès secours')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'L’enfant part avec les secours ?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous allez pouvoir montrer ces informations aux '
              'soignants qui le prennent en charge, et les transmettre '
              'à la personne qui l’accompagne.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le parent en sera informé immédiatement.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: KidsRelayColors.urgence,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Oui, l’enfant part avec les secours',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qu'on montre une fois l'accès ouvert.
///
/// L'adresse est affichée en toutes lettres et copiable : le QR
/// viendra, mais un encodeur écrit à la main ne se vérifie pas sans un
/// vrai téléphone, et cet écran doit fonctionner dès aujourd'hui.
class EcranAccesSecoursOuvert extends StatefulWidget {
  final AccesSecoursOuvert acces;
  final String etablissementId;

  const EcranAccesSecoursOuvert({
    super.key,
    required this.acces,
    required this.etablissementId,
  });

  @override
  State<EcranAccesSecoursOuvert> createState() =>
      _EcranAccesSecoursOuvertState();
}

class _EcranAccesSecoursOuvertState
    extends State<EcranAccesSecoursOuvert> {
  late int _appareilsMax = widget.acces.appareilsMax;
  bool _enCours = false;

  String get _fin {
    final fin = widget.acces.expireLe.toLocal();

    final jour = fin.day.toString().padLeft(2, '0');
    final mois = fin.month.toString().padLeft(2, '0');
    final heure = fin.hour.toString().padLeft(2, '0');
    final minute = fin.minute.toString().padLeft(2, '0');

    return 'le $jour/$mois à ${heure}h$minute';
  }

  Future<void> _etendre() async {
    setState(() => _enCours = true);

    try {
      final nouveau =
          await ServiceAccesSecours.instance.etendreAppareils(
        partageId: widget.acces.id,
        etablissementId: widget.etablissementId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appareilsMax = nouveau;
        _enCours = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$nouveau appareils peuvent maintenant ouvrir la fiche.',
          ),
        ),
      );
    } on ServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _enCours = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adresse = widget.acces.adresse;

    return Scaffold(
      appBar: AppBar(title: const Text('Accès secours ouvert')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Accès secours ouvert',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Cet accès donne '),
                  const TextSpan(
                    text: 'les informations pour les secours, et rien '
                        'd’autre',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '. Il prend fin '),
                  TextSpan(
                    text: _fin,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Il est destiné aux soignants qui prennent l’enfant en '
              'charge, et à la personne qui l’accompagne.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Faites-le ouvrir à chaque nouvelle personne qui '
              's’occupe de l’enfant : chacune gardera la fiche sur son '
              'propre téléphone et pourra la rouvrir sans vous.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Le code, puis l'adresse en clair sous lui : tout le
            // monde ne sait pas scanner, et c'est le repli quand le
            // QR ne prend pas.
            Center(child: CodeQr(donnees: adresse)),

            const SizedBox(height: 16),

            Card(
              color: KidsRelayColors.lin,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  adresse,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copier(adresse),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: adresse),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Transmettre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '$_appareilsMax appareils au maximum peuvent ouvrir '
              'cette fiche.',
              style: const TextStyle(
                color: KidsRelayColors.ardoiseDouce,
              ),
            ),
            const SizedBox(height: 8),
            // Une intervention mobilise des gens successifs. Un
            // soignant refusé parce qu'un compteur est plein serait le
            // pire mode d'échec possible : le geste reste ouvert, et
            // le parent le voit dans sa liste.
            OutlinedButton(
              onPressed:
                  _enCours || _appareilsMax >= 50 ? null : _etendre,
              child: const Text('Ajouter des appareils'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copier(String adresse) async {
    await Clipboard.setData(ClipboardData(text: adresse));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse copiée.')),
    );
  }
}
