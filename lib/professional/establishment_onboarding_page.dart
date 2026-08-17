import 'package:flutter/material.dart';

import 'establishment_service.dart';

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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await EstablishmentService.instance.createEstablishment(
        nom: nom,
        type: _type.value,
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
      body: Padding(
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
