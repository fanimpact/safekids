import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/transmission_pages/contacts_page.dart';
import 'package:kidsrelay/widgets/sk_text_field.dart';

/// Corrigé (19/08/2026, corrections de l'inventaire du 19/08/2026) :
/// `ContactData.isPrimaryContact` n'était réglable depuis aucun écran
/// — seules les données de démonstration le définissaient. La fiche
/// secours et "Ce qu'il faut savoir" trient pourtant les contacts par
/// ce champ.
void main() {
  testWidgets(
    'Choisir un contact comme principal décoche automatiquement les '
    'autres',
    (tester) async {
      final controller = TransmissionController();

      await tester.pumpWidget(
        MaterialApp(
          home: ContactsPage(
            transmissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is SkTextField &&
              widget.label.contains('Nom et prénom'),
        ).first,
        'Parent Un',
      );
      await tester.pumpAndSettle();

      expect(
        controller.formData.contacts
            .every((contact) => !contact.isPrimaryContact),
        isTrue,
        reason:
            'Aucun contact principal choisi par défaut : rien ne '
            'doit être présélectionné.',
      );

      await tester.ensureVisible(find.text('Contact principal').first);
      await tester.tap(find.text('Contact principal').first);
      await tester.pumpAndSettle();

      expect(
        controller.formData.contacts[0].isPrimaryContact,
        isTrue,
      );
      expect(
        controller.formData.contacts[1].isPrimaryContact,
        isFalse,
      );

      await tester.ensureVisible(find.text('Contact principal').last);
      await tester.tap(find.text('Contact principal').last);
      await tester.pumpAndSettle();

      expect(
        controller.formData.contacts[0].isPrimaryContact,
        isFalse,
        reason:
            'Choisir le second contact comme principal doit '
            'décocher le premier : un seul contact principal à la fois.',
      );
      expect(
        controller.formData.contacts[1].isPrimaryContact,
        isTrue,
      );
    },
  );
}
