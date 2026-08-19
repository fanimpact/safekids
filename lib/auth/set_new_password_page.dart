import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_page.dart';
import '../utils/auth_error_message.dart';
import '../widgets/sk_password_field.dart';

/// Affiché quand l'app est ouverte via le lien "mot de passe oublié"
/// reçu par email (`safekids://auth-callback`) : Supabase a déjà
/// établi une session temporaire à ce stade, il ne reste qu'à définir
/// le nouveau mot de passe.
class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  State<SetNewPasswordPage> createState() =>
      _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      _showError(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showError('Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        friendlyAuthErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Choisissez votre nouveau mot de passe.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            SkPasswordField(
              controller: _passwordController,
              label: 'Nouveau mot de passe',
              helperText: '8 caractères minimum.',
            ),

            const SizedBox(height: 20),

            SkPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
