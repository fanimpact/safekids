import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/brouillons/brouillon_profil.dart';
import 'package:kidsrelay/brouillons/brouillon_repository.dart';
import 'package:kidsrelay/models/activity_profile_draft.dart';
import 'package:kidsrelay/models/child_profile_draft.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Le rangement des questionnaires commencés (25/08/2026).
//
// Le dépôt écrit sur l'appareil et nulle part ailleurs. Ce qui se
// vérifie ici : ce qui est écrit se relit, la date de début survit aux
// enregistrements successifs, la purge des 30 jours a bien lieu à la
// lecture, et un stockage abîmé n'empêche pas l'application de
// s'ouvrir.

const _cle = 'kidsrelay_brouillons_profil';

DateTime _le(int jour) => DateTime(2026, 8, jour, 10);

ChildProfileDraft _draft({
  required String childId,
  String prenom = 'Théo',
}) {
  return ChildProfileDraft(
    childId: childId,
    identity: IdentityData(firstName: prenom),
  );
}

String _stockeeAvec(BrouillonProfil brouillon) {
  return jsonEncode([brouillon.toJson()]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final depot = BrouillonRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    depot.horloge = () => _le(10);
    await depot.viderPourTests();
  });

  tearDown(() {
    depot.horloge = DateTime.now;
  });

  group('Ce qui est écrit se relit', () {
    test('Un questionnaire santé commencé survit au rechargement',
        () async {
      await depot.enregistrerSante(_draft(childId: 'enfant-1'));

      final relus = await depot.charger();

      expect(relus, hasLength(1));
      expect(relus.single.type, TypeBrouillon.sante);
      expect(relus.single.childId, 'enfant-1');
      expect(relus.single.prenom, 'Théo');
      expect(relus.single.commenceLe, _le(10));
    });

    test('Deux enfants ont chacun leur brouillon', () async {
      await depot.enregistrerSante(_draft(childId: 'enfant-1'));
      await depot.enregistrerSante(
        _draft(childId: 'enfant-2', prenom: 'Léa'),
      );

      final relus = await depot.charger();

      expect(
        relus.map((brouillon) => brouillon.prenom),
        containsAll(['Théo', 'Léa']),
      );
    });

    test('Le dépôt prévient ses lecteurs à chaque écriture', () async {
      // « Mes enfants » écoute le dépôt : sans notification, la carte
      // de reprise n'apparaîtrait qu'au prochain passage sur l'écran.
      var avertissements = 0;

      void compter() => avertissements++;

      depot.addListener(compter);
      addTearDown(() => depot.removeListener(compter));

      await depot.enregistrerSante(_draft(childId: 'enfant-1'));

      expect(avertissements, greaterThan(0));
    });
  });

  group('La date de début ne bouge pas', () {
    test(
      'Six écrans enregistrés gardent le jour du premier',
      () async {
        // C'est cette date que le parent lit — « commencé le 10/08 »
        // doit désigner le jour où il a commencé, pas le dernier écran
        // rempli.
        await depot.enregistrerSante(_draft(childId: 'enfant-1'));

        depot.horloge = () => _le(12);
        await depot.enregistrerSante(_draft(childId: 'enfant-1'));

        depot.horloge = () => _le(15);
        await depot.enregistrerSante(_draft(childId: 'enfant-1'));

        final relu = (await depot.charger()).single;

        expect(relu.commenceLe, _le(10));
        expect(relu.modifieLe, _le(15));
      },
    );

    test('Un seul brouillon par enfant, pas six', () async {
      for (var jour = 10; jour < 16; jour++) {
        depot.horloge = () => _le(jour);
        await depot.enregistrerSante(_draft(childId: 'enfant-1'));
      }

      expect(await depot.charger(), hasLength(1));
    });
  });

  group('Un brouillon qui dort trop est jeté à la lecture', () {
    test('Périmé, il ne remonte pas', () async {
      SharedPreferences.setMockInitialValues({
        _cle: _stockeeAvec(
          BrouillonProfil(
            type: TypeBrouillon.sante,
            childId: 'enfant-1',
            prenom: 'Théo',
            commenceLe: DateTime(2026, 6, 1),
            modifieLe: DateTime(2026, 6, 1),
            contenu: const {},
          ),
        ),
      });

      expect(await depot.charger(), isEmpty);
    });

    test('Et il est effacé du disque, pas seulement masqué', () async {
      // Ce sont des données de santé : les laisser en place en se
      // contentant de ne pas les afficher ne vaudrait rien.
      SharedPreferences.setMockInitialValues({
        _cle: _stockeeAvec(
          BrouillonProfil(
            type: TypeBrouillon.sante,
            childId: 'enfant-1',
            prenom: 'Théo',
            commenceLe: DateTime(2026, 6, 1),
            modifieLe: DateTime(2026, 6, 1),
            contenu: const {
              'sante': {'pathologies': 'Asthme'},
            },
          ),
        ),
      });

      await depot.charger();

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString(_cle), '[]');
      expect(prefs.getString(_cle), isNot(contains('Asthme')));
    });

    test('Le voisin encore frais, lui, est conservé', () async {
      SharedPreferences.setMockInitialValues({
        _cle: jsonEncode([
          BrouillonProfil(
            type: TypeBrouillon.sante,
            childId: 'vieux',
            prenom: 'Théo',
            commenceLe: DateTime(2026, 6, 1),
            modifieLe: DateTime(2026, 6, 1),
            contenu: const {},
          ).toJson(),
          BrouillonProfil(
            type: TypeBrouillon.sante,
            childId: 'recent',
            prenom: 'Léa',
            commenceLe: _le(8),
            modifieLe: _le(8),
            contenu: const {},
          ).toJson(),
        ]),
      });

      final relus = await depot.charger();

      expect(
        relus.map((brouillon) => brouillon.childId),
        ['recent'],
      );
    });
  });

  group('Un stockage abîmé ne bloque pas l’application', () {
    test('Du texte qui n’est pas du JSON repart de zéro', () async {
      SharedPreferences.setMockInitialValues({
        _cle: 'ceci n’est pas du JSON',
      });

      expect(await depot.charger(), isEmpty);
    });

    test('Une ligne abîmée n’emporte pas les autres', () async {
      SharedPreferences.setMockInitialValues({
        _cle: jsonEncode([
          {'type': 'sante', 'childId': null},
          BrouillonProfil(
            type: TypeBrouillon.sante,
            childId: 'enfant-1',
            prenom: 'Théo',
            commenceLe: _le(8),
            modifieLe: _le(8),
            contenu: const {},
          ).toJson(),
        ]),
      });

      final relus = await depot.charger();

      expect(relus, hasLength(1));
      expect(relus.single.childId, 'enfant-1');
    });
  });

  group('À la validation finale, le brouillon disparaît', () {
    test('Supprimer efface la ligne du disque', () async {
      await depot.enregistrerSante(_draft(childId: 'enfant-1'));
      await depot.supprimer(TypeBrouillon.sante, 'enfant-1');

      expect(await depot.charger(), isEmpty);

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString(_cle), isNot(contains('Théo')));
    });

    test('Seul l’enfant visé est concerné', () async {
      await depot.enregistrerSante(_draft(childId: 'enfant-1'));
      await depot.enregistrerSante(
        _draft(childId: 'enfant-2', prenom: 'Léa'),
      );

      await depot.supprimer(TypeBrouillon.sante, 'enfant-1');

      final relus = await depot.charger();

      expect(relus, hasLength(1));
      expect(relus.single.prenom, 'Léa');
    });

    test('Supprimer ce qui n’existe pas ne fait rien de mal', () async {
      await depot.supprimer(TypeBrouillon.sante, 'jamais-vu');

      expect(await depot.charger(), isEmpty);
    });

    test(
      'Le brouillon santé et le brouillon Activités sont distincts',
      () async {
        // Même enfant, deux questionnaires : terminer le premier ne
        // doit pas emporter le second.
        await depot.enregistrerSante(_draft(childId: 'enfant-1'));
        await depot.enregistrerActivites(
          ActivityProfileDraft(childId: 'enfant-1'),
          childId: 'enfant-1',
          prenom: 'Théo',
        );

        await depot.supprimer(TypeBrouillon.sante, 'enfant-1');

        final relus = await depot.charger();

        expect(relus, hasLength(1));
        expect(relus.single.type, TypeBrouillon.activites);
      },
    );
  });
}
