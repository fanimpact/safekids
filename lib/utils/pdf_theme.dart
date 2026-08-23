import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../theme/kidsrelay_theme.dart';

/// Identité visuelle côté PDF — le pendant de `kidsrelay_theme.dart`
/// pour les fiches imprimées ou partagées.
///
/// Les fiches exportées sortaient en Helvetica noir sur blanc, sans
/// aucun rapport visuel avec l'application. Un accompagnant qui reçoit
/// la fiche par message doit reconnaître qu'elle vient de KidsRelay.
///
/// Le fond des pages reste blanc : le lin est un fond d'écran, pas un
/// fond d'impression — l'imprimer reviendrait à couvrir chaque page
/// d'encre pour rien.
class KidsRelayPdfColors {
  KidsRelayPdfColors._();

  static PdfColor _de(Color couleur) => PdfColor.fromInt(
        couleur.toARGB32(),
      );

  static final PdfColor vertPin = _de(KidsRelayColors.vertPin);
  static final PdfColor ardoise = _de(KidsRelayColors.ardoise);
  static final PdfColor ardoiseDouce = _de(KidsRelayColors.ardoiseDouce);
  static final PdfColor lin = _de(KidsRelayColors.lin);
  static final PdfColor bordure = _de(KidsRelayColors.bordure);
  static final PdfColor ambre = _de(KidsRelayColors.ambre);

  /// Mêmes règles que [KidsRelayColors.urgence] : réservé aux consignes
  /// vitales. Sur une fiche papier, c'est encore plus vrai — c'est là
  /// que l'œil doit tomber en premier.
  static final PdfColor urgence = _de(KidsRelayColors.urgence);
  static final PdfColor urgenceFond = _de(KidsRelayColors.urgenceFond);
  static final PdfColor urgenceBordure =
      _de(KidsRelayColors.urgenceBordure);
}

/// Les mêmes fichiers `.ttf` que ceux embarqués pour l'affichage, lus
/// une seule fois puis gardés en mémoire : une fiche peut être imprimée
/// puis partagée dans la foulée, et relire quatre polices à chaque fois
/// serait du gaspillage.
///
/// Chargées depuis les assets de l'application, jamais depuis le
/// réseau : une fiche doit pouvoir être exportée sans connexion.
pw.ThemeData? _themeEnCache;
pw.Font? _policeTitresEnCache;

Future<pw.Font> _charger(String chemin) async {
  return pw.Font.ttf(await rootBundle.load(chemin));
}

/// Police des titres (Plus Jakarta Sans). À passer explicitement dans
/// le style d'un titre : le thème ne connaît que le texte courant.
Future<pw.Font> pdfTitleFont() async {
  return _policeTitresEnCache ??= await _charger(
    'assets/fonts/PlusJakartaSans-Bold.ttf',
  );
}

/// Thème à passer à chaque `pw.MultiPage`.
Future<pw.ThemeData> pdfKidsRelayTheme() async {
  final cache = _themeEnCache;

  if (cache != null) {
    return cache;
  }

  final texte = await _charger('assets/fonts/Mulish-Regular.ttf');
  final texteGras = await _charger('assets/fonts/Mulish-SemiBold.ttf');
  final titres = await pdfTitleFont();

  return _themeEnCache = pw.ThemeData.withFont(
    base: texte,
    bold: texteGras,
    italic: texte,
    boldItalic: texteGras,
  ).copyWith(
    defaultTextStyle: pw.TextStyle(
      font: texte,
      fontBold: texteGras,
      fontSize: 11,
      color: KidsRelayPdfColors.ardoise,
      lineSpacing: 1.5,
    ),
    header0: pw.TextStyle(
      font: titres,
      fontSize: 20,
      color: KidsRelayPdfColors.vertPin,
    ),
  );
}

/// Titre en tête de fiche, avec le nom de l'enfant.
pw.TextStyle pdfDocumentTitleStyle(pw.Font policeTitres) {
  return pw.TextStyle(
    font: policeTitres,
    fontSize: 20,
    color: KidsRelayPdfColors.vertPin,
  );
}

/// Ligne d'identité sous le titre : âge, poids, taille.
pw.TextStyle get pdfSubtitleStyle => pw.TextStyle(
      fontSize: 12,
      color: KidsRelayPdfColors.ardoiseDouce,
    );
