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

  /// Ce que le trousseau doit proposer. `password` pour une connexion,
  /// `newPassword` pour une creation ou un changement — l'OS ne
  /// propose pas la meme chose dans les deux cas.
  final List<String> autofillHints;

  /// Ce que le clavier affiche comme touche d'action.
  final TextInputAction textInputAction;

  /// Appele quand la personne valide au clavier.
  final VoidCallback? onSubmitted;

  const SkPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
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
      // Le trousseau du telephone est reactive (28/08/2026). Il etait
      // desactive de peur qu'il propose le compte professionnel a la
      // place du compte parent — mais il PROPOSE, il n'impose pas, et
      // la personne choisit dans une liste. Priver tout le monde du
      // remplissage automatique pour epargner une hesitation aux rares
      // porteurs de deux comptes etait un mauvais echange.
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
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
