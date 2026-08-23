import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../theme/kidsrelay_theme.dart';
import '../transmission_pages/identity_page.dart';

/// Consentement explicite à l'enregistrement des données de santé
/// (RGPD, article 9 : les données de santé ne peuvent être traitées
/// qu'avec un consentement explicite).
///
/// Écran à part, avant le questionnaire, et non une case glissée au
/// milieu d'un formulaire : un consentement doit être un acte distinct,
/// que le parent puisse identifier comme tel. Il porte sur **un
/// enfant** — d'où sa présence sur les deux chemins de création, y
/// compris celui du deuxième enfant.
///
/// Jamais affiché en modification : le consentement a déjà été donné,
/// le redemander à chaque correction de poids n'aurait aucun sens et
/// finirait par être coché sans être lu.
class ConsentementSantePage extends StatefulWidget {
  final TransmissionController transmissionController;

  /// Injectée pour les tests. En production, l'heure de l'appareil.
  final DateTime Function() horloge;

  const ConsentementSantePage({
    super.key,
    required this.transmissionController,
    this.horloge = DateTime.now,
  });

  @override
  State<ConsentementSantePage> createState() =>
      _ConsentementSantePageState();
}

class _ConsentementSantePageState
    extends State<ConsentementSantePage> {
  bool _accepte = false;

  void _continuer() {
    // La date est celle du geste, pas celle de l'enregistrement en
    // base : c'est le moment où le parent a consenti qui fait foi.
    widget.transmissionController.formData.consentementSanteLe =
        widget.horloge();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdentityPage(
          transmissionController:
              widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre accord'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              const Text(
                'Avant de commencer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Le profil que vous allez remplir contient des '
                'informations de santé : pathologies, allergies, '
                'traitements, gestes d’urgence. La loi demande votre '
                'accord explicite avant de les enregistrer.',
                style: TextStyle(fontSize: 17, height: 1.5),
              ),

              const SizedBox(height: 24),

              // Material et non Container : une ListTile peint son fond et
              // ses effets tactiles sur le Material le plus proche. Posee
              // sur une simple boite coloree, la case ne montrerait rien
              // quand on la touche.
              Material(
                color: KidsRelayColors.lin,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: KidsRelayColors.bordure,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CheckboxListTile(
                    value: _accepte,
                    onChanged: (valeur) {
                      setState(() {
                        _accepte = valeur ?? false;
                      });
                    },
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'J’autorise KidsRelay à enregistrer les '
                      'informations de santé de mon enfant pour '
                      'générer les fiches et les partager avec les '
                      'personnes que je désigne.',
                      style: TextStyle(fontSize: 16, height: 1.45),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Vous pouvez revenir sur cet accord à tout moment. Le '
                'retirer revient à supprimer la fiche de votre enfant '
                'et tout ce qu’elle contient : c’est le bouton '
                '« Supprimer » de son profil.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),

              const SizedBox(height: 32),

              FilledButton(
                // Désactivé tant que la case n'est pas cochée : un
                // consentement obtenu en passant outre n'en est pas un.
                onPressed: _accepte ? _continuer : null,
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
