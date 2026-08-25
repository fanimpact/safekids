import 'package:flutter/material.dart';

import 'establishment_activity_service.dart';
import 'establishment_service.dart';
import 'fonction_professionnelle.dart';
import 'professional_child_repository.dart';

/// Ajoute une note à une activité déjà générée, à tout moment — pas
/// seulement pendant le parcours de préparation (Fanny, 19/08/2026).
/// Même principe que l'étape "note" du parcours de création
/// (`ActivityNotePage`) mais sans la première question "voulez-vous
/// rédiger une note ?", puisque l'arrivée ici vaut déjà "oui".
class AddActivityNotePage extends StatefulWidget {
  final String activiteId;
  final List<String> childIds;
  final String etablissementId;

  const AddActivityNotePage({
    super.key,
    required this.activiteId,
    required this.childIds,
    required this.etablissementId,
  });

  @override
  State<AddActivityNotePage> createState() =>
      _AddActivityNotePageState();
}

class _AddActivityNotePageState
    extends State<AddActivityNotePage> {
  final _noteController = TextEditingController();

  bool? _linkToChild;
  String? _selectedChildId;
  bool _isSaving = false;

  /// Nulle tant que le champ n'a pas rendu son verdict.
  SignatureNote? _signature;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _displayName(String childId) {
    final child = ProfessionalChildRepository.instance
        .findByChildId(childId);

    if (child == null) {
      return 'Enfant';
    }

    final firstName =
        child.essentialInformation.identity.firstName
            ?.trim();

    return (firstName == null || firstName.isEmpty)
        ? 'Enfant'
        : firstName;
  }

  Future<void> _save() async {
    final texte = _noteController.text.trim();

    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez le texte de la note.'),
        ),
      );
      return;
    }

    if (_linkToChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Précisez si cette note concerne un enfant en particulier.',
          ),
        ),
      );
      return;
    }

    if (_linkToChild == true && _selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un enfant.'),
        ),
      );
      return;
    }

    // Pas de note ecrite sans fonction : le parent doit savoir si
    // l'observation vient de la maitresse, de la cantine ou de la
    // direction.
    final signature = _signature;

    if (signature == null || !signature.utilisable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indiquez votre fonction avant d’enregistrer. Le parent '
            'la lira sous votre note.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!signature.dejaEnregistree) {
        await EstablishmentService.instance.setMyFonction(
          etablissementId: widget.etablissementId,
          fonction: signature.fonction!,
        );
      }

      await EstablishmentActivityService.instance.saveNote(
        activiteId: widget.activiteId,
        texte: texte,
        enfantId:
            _linkToChild == true ? _selectedChildId : null,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d’enregistrer la note : $error',
            ),
            duration: const Duration(seconds: 10),
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }

      return;
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une note'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _noteController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Votre note',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Souhaitez-vous rattacher cette note à un '
              'enfant en particulier ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<bool>(
              groupValue: _linkToChild,
              onChanged: (value) {
                setState(() {
                  _linkToChild = value;

                  if (value != true) {
                    _selectedChildId = null;
                  }
                });
              },
              child: const Column(
                children: [
                  RadioListTile<bool>(
                    title: Text('Oui'),
                    value: true,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      'Non — note générale au groupe',
                    ),
                    value: false,
                  ),
                ],
              ),
            ),

            if (_linkToChild == true) ...[
              const SizedBox(height: 12),

              RadioGroup<String>(
                groupValue: _selectedChildId,
                onChanged: (value) {
                  setState(() {
                    _selectedChildId = value;
                  });
                },
                child: Column(
                  children: [
                    for (final childId in widget.childIds)
                      RadioListTile<String>(
                        title: Text(_displayName(childId)),
                        value: childId,
                      ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: 4,
                ),
                child: Text(
                  'Le parent de cet enfant sera notifié par email '
                  'qu’une note a été ajoutée.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            ChampSignatureNote(
              etablissementId: widget.etablissementId,
              onChanged: (signature) => _signature = signature,
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Enregistrer la note'),
            ),
          ],
        ),
      ),
    );
  }
}
