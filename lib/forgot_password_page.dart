import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

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

            const TextField(
              decoration: InputDecoration(
                labelText: 'Adresse e-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: () {},
              child: const Text('Envoyer le lien'),
            ),
          ],
        ),
      ),
    );
  }
}