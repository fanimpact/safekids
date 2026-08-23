import 'package:flutter/material.dart';

import 'auth/device_verification_page.dart';
import 'auth/account_service.dart';
import 'forgot_password_page.dart';
import 'home/home_page.dart';
import 'suppression/garde_suppression.dart';
import 'register_page.dart';
import 'repositories/child_repository.dart';
import 'utils/auth_error_message.dart';
import 'widgets/sk_password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

      final isRecognized = await AccountService.instance
          .isCurrentDeviceRecognized();

      // Sans ça, l'écran d'accueil affiche encore les enfants (ou
      // l'absence d'enfants) de la session précédente si l'app était
      // déjà ouverte sous une autre identité (ex. après avoir créé un
      // compte professionnel) : il faut recharger pour le compte qui
      // vient de se connecter, pas garder l'ancien état en mémoire.
      try {
        await ChildRepository.instance.loadFromSupabase();
      } catch (_) {
        // Le repli hors-ligne existant (cache local) prend le relais ;
        // ne bloque pas la connexion pour autant.
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isRecognized
              ? const GardeSuppression(enfant: HomePage())
              : const DeviceVerificationPage(),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(friendlyAuthErrorMessage(error));
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
        title: const Text('Se connecter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              // Vide, volontairement : empêche le remplissage
              // automatique du téléphone de substituer l'email d'un
              // autre compte (parent/professionnel) enregistré dans
              // l'app — désactivé sur tous les champs de connexion.
              autofillHints: const [],
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
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
                  : const Text(
                      'Se connecter',
                    ),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ForgotPasswordPage(),
                  ),
                );
              },
              child: const Text(
                'Mot de passe oublié ?',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const RegisterPage(),
                  ),
                );
              },
              child: const Text(
                'Créer un compte',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
