import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../suppression/garde_suppression.dart';
import '../repositories/child_repository.dart';
import 'account_service.dart';

/// Affiché après une connexion réussie par mot de passe, uniquement si
/// l'appareil utilisé n'est pas reconnu pour ce compte. Remplace la
/// double authentification classique (application tierce à installer)
/// par un code à usage unique envoyé par email — une personne qui
/// utilise son téléphone habituel ne voit jamais cet écran une fois
/// l'appareil mémorisé. Commun aux parents et à l'espace professionnel :
/// [buildNextPage] choisit où atterrir une fois vérifié (par défaut,
/// l'accueil particulier).
class DeviceVerificationPage extends StatefulWidget {
  final WidgetBuilder buildNextPage;

  const DeviceVerificationPage({
    super.key,
    this.buildNextPage = _buildHomePage,
  });

  static Widget _buildHomePage(BuildContext context) =>
      const GardeSuppression(enfant: HomePage());

  @override
  State<DeviceVerificationPage> createState() =>
      _DeviceVerificationPageState();
}

class _DeviceVerificationPageState
    extends State<DeviceVerificationPage> {
  final _codeController = TextEditingController();

  bool _isSendingCode = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSendingCode = true;
    });

    try {
      await AccountService.instance
          .requestDeviceVerificationCode();
    } catch (error) {
      if (mounted) {
        _showError(
          'Impossible d’envoyer le code. Vérifiez votre '
          'connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showError('Saisissez le code à 6 chiffres reçu par email.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await AccountService.instance.verifyDeviceCode(
        code,
      );

      // Même précaution qu'à la connexion normale : ne pas laisser
      // l'écran d'accueil afficher les enfants d'une session
      // précédente encore en mémoire.
      try {
        await ChildRepository.instance.loadFromSupabase();
      } catch (_) {
        // Le repli hors-ligne existant (cache local) prend le relais.
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: widget.buildNextPage,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError('Code invalide ou expiré.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel appareil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Vous vous connectez depuis un appareil que nous ne '
              'reconnaissons pas. Un code à usage unique vient de vous '
              'être envoyé par email, valable 10 minutes.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code reçu par email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _isVerifying ? null : _verify,
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Valider'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _isSendingCode ? null : _sendCode,
              child: Text(
                _isSendingCode
                    ? 'Envoi du code…'
                    : 'Renvoyer le code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
