import 'package:flutter/material.dart';

/// Champ mot de passe avec icône œil pour afficher/masquer la saisie —
/// utilisé partout où un mot de passe est demandé (création de compte,
/// connexion, nouveau mot de passe), pour que la personne puisse
/// vérifier ce qu'elle a tapé, en particulier avec des caractères
/// spéciaux.
class SkPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;

  const SkPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
  });

  @override
  State<SkPasswordField> createState() => _SkPasswordFieldState();
}

class _SkPasswordFieldState extends State<SkPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          tooltip: _obscure
              ? 'Afficher le mot de passe'
              : 'Masquer le mot de passe',
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
      ),
    );
  }
}
