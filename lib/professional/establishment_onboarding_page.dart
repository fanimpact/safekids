import 'package:flutter/material.dart';

import 'establishment_service.dart';
import 'fonction_professionnelle.dart';

enum _EstablishmentType {
  ecole('École', 'ecole'),
  periscolaire('Périscolaire', 'periscolaire'),
  autre('Autre', 'autre');

  const _EstablishmentType(this.label, this.value);

  final String label;
  final String value;
}

/// Première création d'un établissement, par la personne qui deviendra
/// automatiquement son directeur. L'invitation d'autres membres du
/// personnel (adjoint, enseignant...) arrive dans une étape suivante.
class EstablishmentOnboardingPage extends StatefulWidget {
  const EstablishmentOnboardingPage({super.key});

  @override
  State<EstablishmentOnboardingPage> createState() =>
      _EstablishmentOnboardingPageState();
}

class _EstablishmentOnboardingPageState
    extends State<EstablishmentOnboardingPage> {
  final _nomController = TextEditingController();
  _EstablishmentType _type = _EstablishmentType.ecole;

  /// Nulle tant que le choix n'est pas exploitable — « Autre » sans
  /// texte saisi compte pour rien choisi.
  String? _fonction;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nom = _nomController.text.trim();

    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez le nom de l’établissement.'),
        ),
      );

      return;
    }

    // Exigée dès la création : c'est ce que les parents liront sous
    // les notes, et personne d'autre que l'intéressé ne peut la
    // renseigner sans deviner.
    if (_fonction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indiquez votre fonction. Si vous choisissez « Autre », '
            'précisez-la.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await EstablishmentService.instance.createEstablishment(
        nom: nom,
        type: _type.value,
        fonction: _fonction,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de créer l’établissement pour le moment.',
          ),
        ),
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
        title: const Text('Créer mon établissement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Vous devenez automatiquement directeur ou directrice '
              'de cet établissement — vous pourrez ensuite inviter '
              'votre équipe.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l’établissement',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<_EstablishmentType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type d’établissement',
                border: OutlineInputBorder(),
              ),
              items: _EstablishmentType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _type = type;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            SelecteurFonction(
              onChanged: (fonction) => _fonction = fonction,
            ),

            const SizedBox(height: 4),

            const Text(
              'Votre fonction apparaît sous chaque note que vous '
              'écrivez sur un enfant, pour que son parent sache d’où '
              'vient l’observation.',
              style: TextStyle(fontSize: 13),
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
                  : const Text('Créer l’établissement'),
            ),
          ],
        ),
      ),
    );
  }
}
