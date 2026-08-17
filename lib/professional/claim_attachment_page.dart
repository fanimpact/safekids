import 'package:flutter/material.dart';

import '../models/etablissement_data.dart';
import 'establishment_service.dart';

/// Saisie du code transmis par un parent pour rattacher un enfant à
/// l'établissement [establishment]. En cas de succès, l'enfant rejoint
/// le trombinoscope pour tout le personnel actif — pas seulement la
/// personne qui a saisi le code.
class ClaimAttachmentPage extends StatefulWidget {
  final EtablissementData establishment;

  const ClaimAttachmentPage({
    super.key,
    required this.establishment,
  });

  @override
  State<ClaimAttachmentPage> createState() =>
      _ClaimAttachmentPageState();
}

class _ClaimAttachmentPageState extends State<ClaimAttachmentPage> {
  final _tokenController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez le code transmis par le parent.'),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prenom = await EstablishmentService.instance
          .claimAttachment(
        token: token,
        etablissementId: widget.establishment.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            prenom == null || prenom.isEmpty
                ? 'Enfant ajouté au trombinoscope.'
                : '$prenom a été ajouté(e) au trombinoscope de '
                    '${widget.establishment.nom}.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code invalide ou expiré.'),
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
        title: const Text('Rattacher un enfant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            Text(
              'Le code vous a été transmis par le parent, pour '
              'rattacher son enfant à ${widget.establishment.nom}.',
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Code reçu du parent',
                border: OutlineInputBorder(),
              ),
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
                  : const Text('Rattacher'),
            ),
          ],
        ),
      ),
    );
  }
}
