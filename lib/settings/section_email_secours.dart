import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';
import 'compte_service.dart';
import 'email_secours.dart';

/// La section « Adresse de secours » de l'écran Paramètres.
///
/// Widget à part et service injecté, pour la même raison que
/// `SectionExportDonnees` : `settings_page.dart` lit directement le
/// SDK, donc ne se monte pas dans un test.
class SectionEmailSecours extends StatefulWidget {
  final CompteService service;

  /// Adresse principale du compte, pour signaler au parent qu'il vient
  /// de saisir la même.
  final String? emailPrincipal;

  const SectionEmailSecours({
    super.key,
    this.service = const CompteServiceSupabase(),
    this.emailPrincipal,
  });

  @override
  State<SectionEmailSecours> createState() =>
      _SectionEmailSecoursState();
}

class _SectionEmailSecoursState
    extends State<SectionEmailSecours> {
  final _controleur = TextEditingController();

  bool _chargement = true;
  bool _enregistrement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final adresse = await widget.service.lireEmailSecours();

      if (!mounted) {
        return;
      }

      _controleur.text = adresse ?? '';
    } catch (_) {
      // Hors ligne : le champ reste vide et modifiable. L'échec se
      // reverra à l'enregistrement, avec un message.
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  void _afficher(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _enregistrer() async {
    final saisie = _controleur.text;
    final erreur = erreurEmailSecours(saisie);

    setState(() {
      _erreur = erreur;
    });

    if (erreur != null) {
      return;
    }

    setState(() {
      _enregistrement = true;
    });

    try {
      await widget.service.enregistrerEmailSecours(
        valeurAEnregistrer(saisie),
      );

      if (!mounted) {
        return;
      }

      if (valeurAEnregistrer(saisie) == null) {
        _afficher('Adresse de secours effacée.');
      } else if (memeAdresseQuePrincipale(
        saisie,
        widget.emailPrincipal,
      )) {
        _afficher(
          'Adresse enregistrée. Notez qu’elle est identique à '
          'l’adresse de votre compte : si vous perdez l’accès à '
          'celle-ci, elle ne pourra pas vous secourir.',
        );
      } else {
        _afficher('Adresse de secours enregistrée.');
      }
    } catch (_) {
      if (mounted) {
        _afficher(
          'Impossible d’enregistrer l’adresse. Vérifiez votre '
          'connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _enregistrement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
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
          'Adresse de secours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Facultatif. Une seconde adresse à laquelle vous joindre si '
          'vous perdez l’accès à votre compte. Elle ne reçoit aucun '
          'email de l’application.',
          style: TextStyle(
            fontSize: 14,
            color: KidsRelayColors.ardoiseDouce,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controleur,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Adresse de secours',
            errorText: _erreur,
            helperText: 'Laissez vide pour ne pas en enregistrer.',
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _enregistrement ? null : _enregistrer,
          child: _enregistrement
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer l’adresse de secours'),
        ),
      ],
    );
  }
}
