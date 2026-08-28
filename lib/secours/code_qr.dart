import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Le code que chaque soignant scanne pour garder la fiche sur son
/// propre téléphone.
///
/// **Pourquoi un peintre à nous plutôt que `qr_flutter`.** Le paquet
/// tout fait n'a pas été publié depuis trois ans et épingle une
/// version ancienne de `qr`. On ne prend que l'encodeur — Dart pur,
/// maintenu, et **déjà présent dans l'arbre** via `pdf` puis
/// `barcode` : cet écran n'ajoute aucune dépendance.
///
/// **Pourquoi le calcul est local.** Le code se dessine à partir du
/// jeton, sans réseau. Dans un couloir d'école mal couvert, un QR qui
/// dépendrait d'un appel serveur serait inutilisable au moment précis
/// où il sert.
///
/// **Le niveau de correction est M, et ce n'est pas un réglage par
/// défaut.** Pour l'adresse d'un accès secours — 82 caractères — M
/// donne exactement la même grille que L, 37 × 37, tout en tolérant
/// deux fois plus de reflets et de traces de doigts. Q et H la
/// densifieraient (45 × 45 et 49 × 49), ce qui nuit plus qu'il n'aide
/// sur un écran tenu à bout de bras.
const int niveauCorrectionQr = QrErrorCorrectLevel.M;

/// Combien de modules de marge autour du code.
///
/// La norme appelle ça la zone calme et en demande quatre. En dessous,
/// certains lecteurs refusent de voir le code — surtout posé sur un
/// fond coloré.
const int margeQr = 4;

class CodeQr extends StatelessWidget {
  final String donnees;

  /// Côté du carré, en pixels logiques.
  final double taille;

  const CodeQr({
    super.key,
    required this.donnees,
    this.taille = 240,
  });

  @override
  Widget build(BuildContext context) {
    QrImage? image;

    try {
      image = QrImage(
        QrCode.fromData(
          data: donnees,
          errorCorrectLevel: niveauCorrectionQr,
        ),
      );
    } catch (_) {
      // Une adresse trop longue pour tenir dans un QR, ou un encodeur
      // qui refuse : on n'affiche rien plutôt qu'un carré faux. Sous
      // ce widget, l'adresse en clair reste lisible — c'est elle le
      // repli, pas un pis-aller.
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Code à scanner pour ouvrir la fiche secours',
      image: true,
      child: Container(
        width: taille,
        height: taille,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Toujours blanc, quel que soit le thème : un lecteur cherche
          // des modules sombres sur fond clair, et l'inverse ne se
          // scanne pas.
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _PeintreQr(image),
          size: Size.square(taille),
        ),
      ),
    );
  }
}

class _PeintreQr extends CustomPainter {
  final QrImage image;

  _PeintreQr(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final cotes = image.moduleCount + margeQr * 2;
    final module = size.shortestSide / cotes;

    final encre = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      // Sans anticrénelage : des bords nets valent mieux qu'un dégradé
      // sur un module d'un ou deux pixels.
      ..isAntiAlias = false;

    for (var ligne = 0; ligne < image.moduleCount; ligne++) {
      for (var colonne = 0; colonne < image.moduleCount; colonne++) {
        if (!image.isDark(ligne, colonne)) {
          continue;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            (colonne + margeQr) * module,
            (ligne + margeQr) * module,
            // Un demi-pixel de recouvrement : sans lui, une ligne
            // claire apparaît entre les modules à certaines échelles
            // et casse la lecture.
            module + 0.5,
            module + 0.5,
          ),
          encre,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreQr ancien) => ancien.image != image;
}
