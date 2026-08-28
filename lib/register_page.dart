import 'package:flutter/material.dart';

import 'auth/account_service.dart';
import 'home/home_page.dart';
import 'suppression/garde_suppression.dart';
import 'utils/auth_error_message.dart';
import 'widgets/sk_password_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
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
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Saisissez une adresse email valide.');
      return;
    }

    if (password.length < 8) {
      _showError(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showError(
        'Les deux mots de passe ne correspondent pas.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AccountService.instance.createAccount(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GardeSuppression(enfant: HomePage()),
        ),
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
        title: const Text('Créer un compte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              // Le trousseau propose, il n'impose pas : la personne
              // choisit dans une liste. Reactive le 28/08/2026.
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SkPasswordField(
              controller: _passwordController,
              label: 'Mot de passe',
              helperText: '8 caractères minimum.',
              // `newPassword` et non `password` : sur une
              // creation, l'OS doit proposer d'en generer un, pas
              // de remplir l'ancien.
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20),

            SkPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: () {
                if (!_isSubmitting) {
                  _submit();
                }
              },
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
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
