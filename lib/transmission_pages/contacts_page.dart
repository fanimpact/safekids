import 'package:flutter/material.dart';

import '../controllers/transmission_controller.dart';
import '../models/contact_data.dart';
import '../widgets/questionnaire_page.dart';
import '../widgets/sk_text_field.dart';
import 'transition_to_activities_page.dart';

class ContactsPage extends StatefulWidget {
  final TransmissionController transmissionController;

  const ContactsPage({
    super.key,
    required this.transmissionController,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();

    final contacts =
        widget.transmissionController.formData.contacts;

    while (contacts.length < 2) {
      contacts.add(ContactData());
    }
  }

  void _addContact() {
    setState(() {
      widget.transmissionController.formData.contacts.add(
        ContactData(),
      );
    });
  }

  void _removeContact(int index) {
    setState(() {
      final contacts =
          widget.transmissionController.formData.contacts;

      if (index < 2 ||
          index < 0 ||
          index >= contacts.length) {
        return;
      }

      contacts.removeAt(index);
    });
  }

  void _updateContactName(
    int index,
    String value,
  ) {
    widget.transmissionController.formData.contacts[index]
        .fullName = value.trim();
  }

  void _updateContactRelationship(
    int index,
    String value,
  ) {
    widget.transmissionController.formData.contacts[index]
        .relationship = value.trim();
  }

  void _updateContactPhone(
    int index,
    String value,
  ) {
    widget.transmissionController.formData.contacts[index]
        .phoneNumber = value.trim();
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

  void _validateInformation() {
    widget.transmissionController.validateDraft();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransitionToActivitiesPage(
          transmissionController:
              widget.transmissionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts =
        widget.transmissionController.formData.contacts;

    return QuestionnairePage(
      title: "",
      subtitle:
          "Qui les services de secours doivent-ils pouvoir contacter ?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            int index = 0;
            index < contacts.length;
            index++
          ) ...[
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
              controller: TextEditingController(
                text: contacts[index].fullName ?? '',
              ),
              onChanged: (value) {
                _updateContactName(index, value);
              },
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Lien avec l’enfant",
              controller: TextEditingController(
                text: contacts[index].relationship ?? '',
              ),
              onChanged: (value) {
                _updateContactRelationship(index, value);
              },
            ),

            const SizedBox(height: 20),

            SkTextField(
              label: "Numéro de téléphone",
              controller: TextEditingController(
                text: contacts[index].phoneNumber ?? '',
              ),
              onChanged: (value) {
                _updateContactPhone(index, value);
              },
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
    );
  }
}