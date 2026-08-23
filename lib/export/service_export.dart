import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'donnees_export.dart';
import 'export_json.dart';
import 'export_pdf.dart';
import 'source_export.dart';

/// Enchaîne la collecte, la production des deux fichiers et leur
/// partage.
///
/// Tout ce qui touche au disque, au partage et à Supabase est ici. La
/// logique, elle, est ailleurs et testée sans réseau : le tri des
/// enfants dans `source_export.dart`, le contenu des deux fichiers dans
/// `export_contenu.dart` et `export_json.dart`.
abstract class ServiceExport {
  /// La fonction est-elle proposée à ce compte ?
  Future<bool> estDisponible();

  /// Produit les deux fichiers et ouvre la feuille de partage.
  /// Lève [ExportImpossible] si l'export ne peut pas être **complet**.
  Future<void> exporterEtPartager();
}

class ServiceExportFichiers implements ServiceExport {
  final SourceExport source;

  /// Injectée pour les tests ; en production, l'heure de l'appareil.
  final DateTime Function() horloge;

  const ServiceExportFichiers({
    this.source = const SourceExportSupabase(),
    this.horloge = DateTime.now,
  });

  @override
  Future<bool> estDisponible() async {
    try {
      final visibles = await source.enfantsVisibles();

      return possedeAuMoinsUnEnfant(
        visibles,
        source.identifiantCompte,
      );
    } catch (_) {
      // Hors ligne ou session expirée : ne pas proposer une fonction
      // qui échouerait de toute façon.
      return false;
    }
  }

  @override
  Future<void> exporterEtPartager() async {
    final donnees = await _collecter();

    final nom = nomFichierExport(donnees.exporteLe);
    final dossier = await getTemporaryDirectory();

    final cheminPdf = '${dossier.path}/$nom.pdf';
    final cheminJson = '${dossier.path}/$nom.json';

    await File(cheminPdf).writeAsBytes(
      await construireExportPdf(donnees),
    );

    // Encodage explicite : sans lui, les prénoms accentués seraient
    // illisibles dans un éditeur de texte sur un autre poste.
    await File(cheminJson).writeAsString(
      encoderExportJson(donnees),
      encoding: utf8,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(cheminPdf), XFile(cheminJson)],
        subject: 'Mes données KidsRelay',
        text:
            'Copie de vos données KidsRelay, établie le '
            '${_dateCourte(donnees.exporteLe)}. Le PDF se lit tel '
            'quel ; le fichier .json contient les mêmes informations '
            'sous une forme réutilisable.',
      ),
    );
  }

  /// Un export doit être complet ou ne pas être. Le cache local peut
  /// avoir plusieurs jours : remettre à un parent un document intitulé
  /// « copie complète de vos données » à partir de données périmées
  /// serait pire que de ne rien lui remettre.
  Future<DonneesExport> _collecter() async {
    try {
      return await collecterExport(source, horloge());
    } on ExportImpossible {
      rethrow;
    } catch (_) {
      throw const ExportImpossible(
        'Impossible de constituer l’export. Vérifiez votre connexion '
        'et réessayez : un export incomplet ne vous serait d’aucune '
        'aide.',
      );
    }
  }

  String _dateCourte(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year}';
  }
}
