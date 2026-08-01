import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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

            const TextField(
              decoration: InputDecoration(
                labelText: 'Adresse e-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: () {},
              child: const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}