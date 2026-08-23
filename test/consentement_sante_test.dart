import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/consentement/consentement_sante_page.dart';
import 'package:kidsrelay/controllers/transmission_controller.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/child_profile_draft.dart';
import 'package:kidsrelay/repositories/child_profile_codec.dart';
import 'package:kidsrelay/transmission_pages/identity_page.dart';

// Consentement explicite à l'enregistrement des données de santé
// (RGPD, article 9). Ce qui est vérifié ici : qu'on ne puisse pas
// commencer un profil sans avoir coché, et que la date du geste soit
// bien celle qui est enregistrée.

final _maintenant = DateTime.utc(2026, 8, 23, 12);

Future<TransmissionController> _monter(WidgetTester tester) async {
  final controleur = TransmissionController();

  await tester.pumpWidget(
    MaterialApp(
      home: ConsentementSantePage(
        transmissionController: controleur,
        horloge: () => _maintenant,
      ),
    ),
  );

  return controleur;
}

void main() {
  group('La case est obligatoire', () {
    testWidgets('Sans la cocher, on ne peut pas continuer',
        (tester) async {
      await _monter(tester);

      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuer'),
      );

      expect(bouton.onPressed, isNull);
    });

    testWidgets('Une fois cochée, on peut continuer', (tester) async {
      await _monter(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuer'),
      );

      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('Décocher referme la porte', (tester) async {
      await _monter(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continuer'),
      );

      expect(bouton.onPressed, isNull);
    });

    testWidgets('Tant qu’on n’a pas coché, aucune date n’est posée',
        (tester) async {
      final controleur = await _monter(tester);

      expect(
        controleur.formData.consentementSanteLe,
        isNull,
      );
    });
  });

  group('Le texte demandé', () {
    testWidgets('La formulation exacte est affichée', (tester) async {
      await _monter(tester);

      expect(
        find.textContaining(
          'J’autorise KidsRelay à enregistrer les informations de '
          'santé de mon enfant',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'partager avec les personnes que je désigne',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Le moyen de revenir en arrière est indiqué',
        (tester) async {
      // Un consentement dont on ne peut pas sortir n'en est pas un.
      await _monter(tester);

      expect(
        find.textContaining('Le retirer revient à supprimer la fiche'),
        findsOneWidget,
      );
    });
  });

  group('La date du consentement', () {
    testWidgets('Est celle du geste, et ouvre le questionnaire',
        (tester) async {
      final controleur = await _monter(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(controleur.formData.consentementSanteLe, _maintenant);
      expect(find.byType(IdentityPage), findsOneWidget);
    });
  });

  group('La date survit jusqu’à la base', () {
    test('Du brouillon au profil validé', () {
      final brouillon = ChildProfileDraft()
        ..consentementSanteLe = _maintenant;

      final profil = ChildProfileData.fromDraft(brouillon);

      expect(profil.consentementSanteLe, _maintenant);
    });

    test('Du profil à la ligne écrite en base', () {
      final brouillon = ChildProfileDraft()
        ..consentementSanteLe = _maintenant;

      final ligne = ChildProfileCodec.enfantRow(
        ChildProfileData.fromDraft(brouillon),
        'parent-1',
      );

      expect(
        ligne['consentement_sante_le'],
        '2026-08-23T12:00:00.000Z',
      );
    });

    test('De la ligne relue au profil', () {
      final profil = ChildProfileCodec.childProfileFromRows(
        childId: 'enfant-1',
        enfant: {
          'parent_id': 'parent-1',
          'prenom': 'Noé',
          'consentement_sante_le': '2026-08-23T12:00:00.000Z',
        },
      );

      expect(profil.consentementSanteLe, _maintenant);
    });

    test(
      'Une fiche créée avant le consentement reste valable',
      () {
        // Les fiches d'avant le 23/08/2026 n'ont pas de date. Elles ne
        // sont pas invalides pour autant : le consentement n'était
        // alors pas demandé, et rien ne justifie de les bloquer.
        final profil = ChildProfileCodec.childProfileFromRows(
          childId: 'enfant-1',
          enfant: {
            'parent_id': 'parent-1',
            'prenom': 'Théo',
          },
        );

        expect(profil.consentementSanteLe, isNull);
      },
    );

    test('Une date illisible ne fait pas échouer la lecture', () {
      final profil = ChildProfileCodec.childProfileFromRows(
        childId: 'enfant-1',
        enfant: {
          'parent_id': 'parent-1',
          'consentement_sante_le': 'pas une date',
        },
      );

      expect(profil.consentementSanteLe, isNull);
    });
  });
}
