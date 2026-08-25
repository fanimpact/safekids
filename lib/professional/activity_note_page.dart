import 'package:flutter/material.dart';

import '../activity_pages/activity_recommendations_page.dart';
import '../models/activity_session/complete_activity_session_data.dart';
import '../recommendation_engine/models/activity_recommendation_result.dart';
import 'establishment_activity_service.dart';
import 'establishment_service.dart';
import 'fonction_professionnelle.dart';
import 'establishment_home_page.dart';
import 'professional_child_repository.dart';

/// Étape intermédiaire du parcours de préparation d'activité côté
/// professionnel uniquement, entre la sélection des enfants et
/// l'affichage des recommandations : proposer d'ajouter une note sur
/// l'activité, avec un enfant concerné optionnel. Une note générale
/// (aucun enfant choisi) reste dans l'activité et n'est envoyée à
/// personne ; une note liée à un enfant notifie son parent par email.
class ActivityNotePage extends StatefulWidget {
  final CompleteActivitySessionData activity;
  final ActivityRecommendationResult recommendationResult;
  final String etablissementId;

  const ActivityNotePage({
    super.key,
    required this.activity,
    required this.recommendationResult,
    required this.etablissementId,
  });

  @override
  State<ActivityNotePage> createState() =>
      _ActivityNotePageState();
}

class _ActivityNotePageState extends State<ActivityNotePage> {
  final _noteController = TextEditingController();

  bool? _wantsNote;
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

  void _openRecommendations() {
    if (!mounted) {
      return;
    }

    final activiteId = widget.activity.id;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityRecommendationsPage(
          activitySession: widget.activity,
          recommendationResult: widget.recommendationResult,
          findChild: ProfessionalChildRepository.instance
              .findByChildId,
          etablissementId: widget.etablissementId,
          initialMaskedKeys: const {},
          onToggleMask: activiteId == null
              ? null
              : (cle, masquer) =>
                  EstablishmentActivityService.instance
                      .toggleMask(
                    activiteId: activiteId,
                    cle: cle,
                    masquer: masquer,
                  ),
          onFinish: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const EstablishmentHomePage(),
            ),
            (route) => route.isFirst,
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_wantsNote != true) {
      _openRecommendations();
      return;
    }

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

    final activiteId = widget.activity.id;

    if (activiteId == null) {
      _openRecommendations();
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
        activiteId: activiteId,
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

    _openRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note sur l’activité'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Souhaitez-vous rédiger une note supplémentaire '
              'concernant cette activité ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            RadioGroup<bool>(
              groupValue: _wantsNote,
              onChanged: (value) {
                setState(() {
                  _wantsNote = value;

                  if (value != true) {
                    _linkToChild = null;
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
                    title: Text('Non'),
                    value: false,
                  ),
                ],
              ),
            ),

            if (_wantsNote == true) ...[
              const SizedBox(height: 20),

              TextField(
                controller: _noteController,
                maxLines: 4,
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
                      for (final childId
                          in widget.activity.childIds)
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
            ],

            const SizedBox(height: 24),

            if (_wantsNote == true)
              ChampSignatureNote(
                etablissementId: widget.etablissementId,
                onChanged: (signature) => _signature = signature,
              ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _continue,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}
