import 'package:pdf/widgets.dart' as pw;

/// The base PDF font only supports plain ASCII punctuation, unlike the
/// on-screen text which renders fine with typographic characters.
/// Curly quotes/dashes show up as tofu boxes in the exported PDF unless
/// swapped for their plain equivalents right before rendering.
String pdfSafeText(
  String text,
) {
  return text
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('…', '...')
      .replaceAll('«', '"')
      .replaceAll('»', '"')
      .replaceAll('•', '-')
      .replaceAll('œ', 'oe')
      .replaceAll('Œ', 'OE')
      .replaceAll('æ', 'ae')
      .replaceAll('Æ', 'AE');
}

pw.Widget pdfSectionTitle(
  String title,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(
      top: 14,
      bottom: 8,
    ),
    child: pw.Text(
      pdfSafeText(title),
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
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
      text: pdfSafeText(text),
      style: const pw.TextStyle(
        fontSize: 11,
      ),
    ),
  );
}
