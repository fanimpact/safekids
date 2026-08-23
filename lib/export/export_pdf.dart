import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/pdf_theme.dart';
import 'donnees_export.dart';
import 'export_contenu.dart';

/// Mise en page du document lisible de l'export RGPD — celui qu'un
/// parent donne à un médecin ou à un établissement.
///
/// Ce fichier ne décide de rien : il ne fait que dessiner les blocs
/// produits par `export_contenu.dart`. Ce que le document **dit** est
/// décidé et vérifié là-bas, en texte ; ce qu'il **montre** est décidé
/// ici. Le partage se fait entre ces deux-là parce qu'un PDF ne se
/// relit pas : son texte y est écrit en identifiants de glyphes de la
/// police embarquée, jamais en clair.
Future<Uint8List> construireExportPdf(DonneesExport donnees) async {
  final theme = await pdfKidsRelayTheme();
  final policeTitres = await pdfTitleFont();

  final document = pw.Document();

  for (final page in pagesExport(donnees)) {
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) =>
            page.map((bloc) => _dessiner(bloc, policeTitres)).toList(),
      ),
    );
  }

  return document.save();
}

pw.Widget _dessiner(BlocExport bloc, pw.Font policeTitres) {
  switch (bloc.style) {
    case StyleBloc.titreDocument:
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(
          bloc.texte,
          style: pdfDocumentTitleStyle(policeTitres),
        ),
      );

    case StyleBloc.titreSection:
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(
          bloc.texte,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: KidsRelayPdfColors.vertPin,
          ),
        ),
      );

    case StyleBloc.sousTitre:
      return pw.Padding(
        padding: pw.EdgeInsets.only(
          top: 8,
          bottom: 2,
          left: 8.0 * bloc.profondeur,
        ),
        child: pw.Text(
          bloc.texte,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: KidsRelayPdfColors.ardoise,
          ),
        ),
      );

    case StyleBloc.puce:
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
        child: pw.Bullet(
          text: bloc.texte,
          style: pw.TextStyle(
            fontSize: 11,
            color: KidsRelayPdfColors.ardoise,
          ),
        ),
      );

    case StyleBloc.ligne:
      return pw.Padding(
        padding: pw.EdgeInsets.only(
          bottom: 3,
          left: 8.0 + 8.0 * bloc.profondeur,
        ),
        child: pw.Text(
          bloc.texte,
          style: pw.TextStyle(
            fontSize: 11,
            color: KidsRelayPdfColors.ardoise,
          ),
        ),
      );
  }
}
