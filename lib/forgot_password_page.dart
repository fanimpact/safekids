import 'package:flutter/material.dart';

import 'auth/account_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez une adresse email valide.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AccountService.instance.requestPasswordReset(
        email,
      );
    } catch (_) {
      // Le message de confirmation reste le même en cas d'échec, pour
      // ne pas laisser deviner si une adresse est associée à un compte.
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _linkSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Saisissez votre adresse e-mail pour recevoir un lien de réinitialisation.',
              style: TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_linkSent,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            if (_linkSent)
              const Text(
                'Si cette adresse est associée à un compte, un email '
                'contenant un lien de réinitialisation vient d’être '
                'envoyé.',
                style: TextStyle(fontSize: 15),
              )
            else
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
                    : const Text('Envoyer le lien'),
              ),
          ],
        ),
      ),
    );
  }
}
