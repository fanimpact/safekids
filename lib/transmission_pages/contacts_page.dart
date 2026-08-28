import 'dart:async';

import 'package:flutter/material.dart';

import '../brouillons/enregistrement_brouillon.dart';

import '../children/child_profile_page.dart';
import '../controllers/transmission_controller.dart';
import '../secours/acces_secours_page.dart';
import '../models/contact_data.dart';
import '../repositories/child_repository.dart';
import '../utils/text_controller_cache.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import 'transition_to_activities_page.dart';

class ContactsPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const ContactsPage({super.key, required this.transmissionController});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _controllers = TextControllerCache();

  @override
  void initState() {
    super.initState();

    final contacts = widget.transmissionController.formData.contacts;

    while (contacts.length < 2) {
      contacts.add(ContactData());
    }
  }

  @override
  void dispose() {
    _controllers.disposeAll();
    super.dispose();
  }

  void _addContact() {
    setState(() {
      widget.transmissionController.formData.contacts.add(ContactData());
    });
  }

  void _removeContact(int index) {
    setState(() {
      final contacts = widget.transmissionController.formData.contacts;

      if (index < 2 || index < 0 || index >= contacts.length) {
        return;
      }

      contacts.removeAt(index);
    });
  }

  void _updateContactName(int index, String value) {
    widget.transmissionController.formData.contacts[index].fullName = value
        .trim();
  }

  void _updateContactRelationship(int index, String value) {
    widget.transmissionController.formData.contacts[index].relationship = value
        .trim();
  }

  void _updateContactPhone(int index, String value) {
    widget.transmissionController.formData.contacts[index].phoneNumber = value
        .trim();
  }

  void _setPrimaryContact(int index) {
    setState(() {
      final contacts = widget.transmissionController.formData.contacts;

      for (var i = 0; i < contacts.length; i++) {
        contacts[i].isPrimaryContact = i == index;
      }
    });
  }

  String _contactTitle(int index) {
    if (index == 0) {
      return "Parent ou responsable légal n°1";
    }

    if (index == 1) {
      return "Parent ou responsable légal n°2 (facultatif)";
    }

    return "Autre contact n°${index - 1}";
  }

  Future<void> _validateInformation() async {
    if (widget.transmissionController.isEditing) {
      final profile = widget.transmissionController.validateAndGetProfile();

      try {
        await ChildRepository.instance.replaceChild(profile);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Impossible d'enregistrer le profil pour "
                'le moment. Vérifiez la connexion. '
                '($error)',
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      final updatedChild = ChildRepository.instance.findByChildId(
        profile.childId ?? '',
      )!;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ChildProfilePage(child: updatedChild),
        ),
        (route) => false,
      );

      return;
    }

    widget.transmissionController.validateDraft();

    // Dernier ecran du questionnaire : le brouillon est ecrit ici
    // aussi, parce que l'enregistrement en base a lieu a l'ecran
    // suivant et peut echouer.
    unawaited(
      enregistrerBrouillonSante(
        widget.transmissionController.formData,
      ),
    );

    // L'acces secours se demande ICI, apres le questionnaire et avant
    // l'enregistrement : le parent vient de voir ce que la fiche
    // contient, et le choix part en base avec le reste, sans seconde
    // ecriture.
    final reponse = await Navigator.push<ReponseAccesSecours>(
      context,
      MaterialPageRoute(
        builder: (context) => AccesSecoursPage(
          prenom: widget.transmissionController.formData.identity
                  .firstName
                  ?.trim() ??
              'votre enfant',
          onRepondre: (autorise) async {
            widget.transmissionController.formData
                .accesSecoursAutorise = autorise;
          },
        ),
      ),
    );

    // Revenu en arriere par la fleche : on ne va pas plus loin, le
    // profil n'est pas encore enregistre. « Repondre plus tard », en
    // revanche, poursuit — l'absence de reponse ne bloque pas la
    // creation du profil.
    if (reponse == null || !mounted) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransitionToActivitiesPage(
          transmissionController: widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.transmissionController.formData.contacts;

    final primaryIndex = contacts.indexWhere(
      (contact) => contact.isPrimaryContact,
    );

    return QuestionnairePage(
      barreTitre: 'Questionnaire santé',
      etape: 6,
      total: 6,
      title: 'Contacts d’urgence',
      subtitle:
          'Qui les services de secours doivent-ils pouvoir contacter ?',
      consigne:
          'Aucun contact n’est obligatoire — mais c’est la '
          'première chose que les secours chercheront.',
      child: RadioGroup<int>(
        groupValue: primaryIndex < 0 ? null : primaryIndex,
        onChanged: (value) {
          if (value == null) {
            return;
          }

          _setPrimaryContact(value);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int index = 0; index < contacts.length; index++) ...[
              Text(
                _contactTitle(index),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              SkTextField(
                label: "Nom et prénom",
                controller: _controllers.of(
                  'contact_${index}_fullName',
                  contacts[index].fullName ?? '',
                ),
                onChanged: (value) {
                  _updateContactName(index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label: "Lien avec l’enfant",
                controller: _controllers.of(
                  'contact_${index}_relationship',
                  contacts[index].relationship ?? '',
                ),
                onChanged: (value) {
                  _updateContactRelationship(index, value);
                },
              ),

              const SizedBox(height: 20),

              SkTextField(
                label: "Numéro de téléphone",
                controller: _controllers.of(
                  'contact_${index}_phoneNumber',
                  contacts[index].phoneNumber ?? '',
                ),
                onChanged: (value) {
                  _updateContactPhone(index, value);
                },
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: () => _setPrimaryContact(index),
                child: Row(
                  children: [
                    Radio<int>(value: index),
                    const Text("Contact principal"),
                  ],
                ),
              ),

              if (index >= 2) ...[
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _removeContact(index),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Supprimer"),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],

            OutlinedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add),
              label: const Text("Ajouter un contact"),
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: _validateInformation,
              child: const Text("Valider les informations"),
            ),
          ],
        ),
      ),
    );
  }
}
