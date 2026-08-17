import 'package:flutter/material.dart';

import '../auth/account_service.dart';
import '../widgets/sk_password_field.dart';
import 'establishment_home_page.dart';

/// Création d'un compte professionnel — mêmes mécanismes que côté
/// parent (email + mot de passe, vérification par email uniquement sur
/// nouvel appareil), simplement sans conversion de session anonyme
/// préalable côté données enfant : un membre du personnel n'a rien à
/// préserver, contrairement à un parent qui peut déjà avoir des enfants
/// enregistrés.
class ProfessionalRegisterPage extends StatefulWidget {
  const ProfessionalRegisterPage({super.key});

  @override
  State<ProfessionalRegisterPage> createState() =>
      _ProfessionalRegisterPageState();
}

class _ProfessionalRegisterPageState
    extends State<ProfessionalRegisterPage> {
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
      _showError('Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AccountService.instance.createSeparateAccount(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EstablishmentHomePage(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Impossible de créer le compte : $error',
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
        title: const Text('Créer un compte professionnel'),
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
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail professionnelle',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SkPasswordField(
              controller: _passwordController,
              label: 'Mot de passe',
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
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
