import 'package:pdf/widgets.dart' as pw;

import 'pdf_theme.dart';

pw.Widget pdfSectionTitle(
  String title,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(
      top: 14,
      bottom: 8,
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
        color: KidsRelayPdfColors.vertPin,
      ),
    ),
  );
}

pw.Widget pdfBullet(
  String text,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(
      bottom: 4,
      left: 8,
    ),
    child: pw.Bullet(
      text: text,
      style: pw.TextStyle(
        fontSize: 11,
        color: KidsRelayPdfColors.ardoise,
      ),
    ),
  );
}

/// Titre de section pour ce qui relève de l'urgence vitale — consignes
/// d'urgence, médicaments d'urgence. C'est le pendant imprimé des
/// encarts rouges de l'application.
///
/// Volontairement un bandeau court et non un cadre autour de toute la
/// section : sur une fiche longue, un cadre qui ne tient pas sur une
/// page casse la pagination de `pw.MultiPage`. Le bandeau, lui, tient
/// toujours.
pw.Widget pdfEmergencySectionTitle(String titre) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
    padding: const pw.EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    decoration: pw.BoxDecoration(
      color: KidsRelayPdfColors.urgenceFond,
      border: pw.Border.all(
        color: KidsRelayPdfColors.urgenceBordure,
      ),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      titre,
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
        color: KidsRelayPdfColors.urgence,
      ),
    ),
  );
}
