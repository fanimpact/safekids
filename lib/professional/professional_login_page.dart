import 'package:flutter/material.dart';

import '../auth/account_service.dart';
import '../auth/device_verification_page.dart';
import '../widgets/sk_password_field.dart';
import 'establishment_home_page.dart';
import 'professional_register_page.dart';

class ProfessionalLoginPage extends StatefulWidget {
  const ProfessionalLoginPage({super.key});

  @override
  State<ProfessionalLoginPage> createState() =>
      _ProfessionalLoginPageState();
}

class _ProfessionalLoginPageState
    extends State<ProfessionalLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  static Widget _buildEstablishmentHome(BuildContext context) =>
      const EstablishmentHomePage();

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Saisissez votre email et votre mot de passe.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AccountService.instance.signIn(
        email: email,
        password: password,
      );

      final isRecognized =
          await AccountService.instance.isCurrentDeviceRecognized();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isRecognized
              ? const EstablishmentHomePage()
              : const DeviceVerificationPage(
                  buildNextPage: _buildEstablishmentHome,
                ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError('Connexion refusée : $error');
      }
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
        title: const Text('Espace professionnel — Connexion'),
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
                  : const Text('Se connecter'),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfessionalRegisterPage(),
                  ),
                );
              },
              child: const Text('Créer un compte professionnel'),
            ),
          ],
        ),
      ),
    );
  }
}
