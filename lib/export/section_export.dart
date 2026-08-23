import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';
import 'service_export.dart';
import 'source_export.dart';

/// La section « Exporter mes données » de l'écran Paramètres.
///
/// Widget à part plutôt que du code dans `settings_page.dart` : cette
/// page lit directement `SupabaseAuthProvider.instance`, donc ne se
/// monte pas dans un test sans Supabase. Ici, tout entre par le
/// constructeur, et le comportement se vérifie avec un double.
class SectionExportDonnees extends StatefulWidget {
  final ServiceExport service;

  const SectionExportDonnees({
    super.key,
    this.service = const ServiceExportFichiers(),
  });

  @override
  State<SectionExportDonnees> createState() =>
      _SectionExportDonneesState();
}

class _SectionExportDonneesState
    extends State<SectionExportDonnees> {
  bool _verificationEnCours = true;
  bool _disponible = false;
  bool _exportEnCours = false;

  @override
  void initState() {
    super.initState();
    _verifierDisponibilite();
  }

  Future<void> _verifierDisponibilite() async {
    final disponible = await widget.service.estDisponible();

    if (!mounted) {
      return;
    }

    setState(() {
      _disponible = disponible;
      _verificationEnCours = false;
    });
  }

  void _afficher(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _exporter() async {
    setState(() {
      _exportEnCours = true;
    });

    try {
      await widget.service.exporterEtPartager();
    } on ExportImpossible catch (erreur) {
      if (mounted) {
        _afficher(erreur.message);
      }
    } catch (_) {
      if (mounted) {
        _afficher(
          'Impossible de constituer l’export. Vérifiez votre '
          'connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificationEnCours) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mes données',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (!_disponible) ..._indisponible() else ..._disponibleWidgets(),
      ],
    );
  }

  /// Une absence muette laisserait croire à un défaut de
  /// l'application. Le compte concerné est celui d'une personne de
  /// confiance : elle voit des enfants, mais n'en possède aucun.
  List<Widget> _indisponible() {
    return [
      const Text(
        'L’export est réservé au parent qui a créé les fiches. Aucun '
        'enfant n’est rattaché à ce compte : il n’y a donc rien à '
        'exporter ici.',
        style: TextStyle(color: KidsRelayColors.ardoiseDouce),
      ),
    ];
  }

  List<Widget> _disponibleWidgets() {
    return [
      const Text(
        'Récupérez une copie de tout ce que KidsRelay détient sur '
        'vous et sur vos enfants : profils, partages, rattachements, '
        'notes et consultations.',
      ),
      const SizedBox(height: 8),
      const Text(
        'Deux fichiers sont produits : un PDF, lisible tel quel et '
        'que vous pouvez remettre à un médecin ou à un '
        'établissement, et un fichier de données réutilisable. Les '
        'jetons de partage en sont retirés.',
        style: TextStyle(
          fontSize: 13,
          color: KidsRelayColors.ardoiseDouce,
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _exportEnCours ? null : _exporter,
        icon: _exportEnCours
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        label: Text(
          _exportEnCours
              ? 'Préparation en cours…'
              : 'Exporter mes données',
        ),
      ),
    ];
  }
}
