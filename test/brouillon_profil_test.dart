import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/brouillons/brouillon_profil.dart';
import 'package:kidsrelay/models/activity_profile_draft.dart';
import 'package:kidsrelay/models/child_profile_draft.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';

// L'enregistrement du brouillon de questionnaire (25/08/2026).
//
// Avant : rien n'était écrit avant la dernière page. Un parent
// interrompu au cinquième des six écrans de santé, ou au dixième des
// onze écrans d'activités, perdait tout.
//
// Ce fichier teste ce qui se teste sans disque : les conversions
// aller-retour, la règle des 30 jours, la tolérance à une ligne
// abîmée, et la phrase que le parent lit dans « Mes enfants ».

DateTime _le(int jour) => DateTime(2026, 8, jour, 10);

BrouillonProfil _brouillon({
  required DateTime modifieLe,
  TypeBrouillon type = TypeBrouillon.sante,
  String childId = 'enfant-1',
  String? prenom = 'Théo',
}) {
  return BrouillonProfil(
    type: type,
    childId: childId,
    prenom: prenom,
    commenceLe: _le(1),
    modifieLe: modifieLe,
    contenu: const {'enfant': <String, dynamic>{}},
  );
}

void main() {
  group('Le questionnaire santé fait l’aller-retour', () {
    test('Ce qui a été saisi se retrouve après relecture', () {
      final draft = ChildProfileDraft(
        childId: 'enfant-1',
        identity: IdentityData(
          firstName: 'Théo',
          lastName: 'Martin',
          dateOfBirth: DateTime(2016, 6, 1),
          weightKg: 24.5,
        ),
        hasPathologies: true,
        pathologies: [PathologyData(name: 'Asthme')],
      );

      final brouillon = brouillonDepuisSante(
        draft,
        commenceLe: _le(1),
        modifieLe: _le(2),
      );

      final relu = santeDepuisBrouillon(brouillon);

      expect(relu, isNotNull);
      expect(relu!.childId, 'enfant-1');
      expect(relu.identity.firstName, 'Théo');
      expect(relu.identity.lastName, 'Martin');
      expect(relu.identity.dateOfBirth, DateTime(2016, 6, 1));
      expect(relu.identity.weightKg, 24.5);
      expect(relu.hasPathologies, isTrue);
      expect(relu.pathologies.single.name, 'Asthme');
    });

    test('Le prénom est retenu pour pouvoir annoncer la reprise', () {
      final brouillon = brouillonDepuisSante(
        ChildProfileDraft(
          identity: IdentityData(firstName: '  Théo  '),
        ),
        commenceLe: _le(1),
        modifieLe: _le(1),
      );

      expect(brouillon.prenom, 'Théo');
    });

    test(
      'Sans prénom saisi, le brouillon n’en invente pas',
      () {
        // Le tout premier écran peut être quitté avant le premier
        // champ : « Reprendre le profil de  » serait pire que rien.
        final brouillon = brouillonDepuisSante(
          ChildProfileDraft(identity: IdentityData(firstName: '   ')),
          commenceLe: _le(1),
          modifieLe: _le(1),
        );

        expect(brouillon.prenom, isNull);
        expect(
          libelleReprise(brouillon),
          'Reprendre le profil, commencé le 01/08',
        );
      },
    );

    test('Aucun parent_id ne part dans le brouillon', () {
      // Le brouillon ne quitte pas l'appareil : y écrire l'identifiant
      // du compte serait une donnée de plus, sans emploi.
      final brouillon = brouillonDepuisSante(
        ChildProfileDraft(identity: IdentityData(firstName: 'Théo')),
        commenceLe: _le(1),
        modifieLe: _le(1),
      );

      final enfant =
          brouillon.contenu['enfant'] as Map<String, dynamic>;

      expect(enfant['parent_id'], '');
    });
  });

  group('Le profil Activités fait l’aller-retour', () {
    test('Ce qui a été coché se retrouve après relecture', () {
      final draft = ActivityProfileDraft(childId: 'enfant-1');

      draft.aquaticActivity.requiresFlotationVestNearWater = true;
      draft.aquaticActivity.requiresDedicatedAdult = true;
      draft.aquaticActivity.otherAdaptationDetails =
          'Ne va jamais seul au bord';

      final brouillon = brouillonDepuisActivites(
        draft,
        childId: 'enfant-1',
        prenom: 'Théo',
        commenceLe: _le(1),
        modifieLe: _le(2),
      );

      final relu = activitesDepuisBrouillon(brouillon);

      expect(relu, isNotNull);
      expect(relu!.childId, 'enfant-1');
      expect(
        relu.aquaticActivity.requiresFlotationVestNearWater,
        isTrue,
      );
      expect(relu.aquaticActivity.requiresDedicatedAdult, isTrue);
      expect(
        relu.aquaticActivity.otherAdaptationDetails,
        'Ne va jamais seul au bord',
      );
    });
  });

  group('Un brouillon abîmé se jette, il ne casse rien', () {
    test('Une ligne sans identifiant est refusée', () {
      expect(
        BrouillonProfil.fromJson({
          'type': 'sante',
          'commenceLe': _le(1).toIso8601String(),
          'modifieLe': _le(1).toIso8601String(),
          'contenu': <String, dynamic>{},
        }),
        isNull,
      );
    });

    test('Une ligne sans date lisible est refusée', () {
      expect(
        BrouillonProfil.fromJson({
          'type': 'sante',
          'childId': 'enfant-1',
          'commenceLe': 'pas une date',
          'modifieLe': _le(1).toIso8601String(),
          'contenu': <String, dynamic>{},
        }),
        isNull,
      );
    });

    test('Un contenu vide ne fait pas relire un questionnaire', () {
      final relu = santeDepuisBrouillon(
        BrouillonProfil(
          type: TypeBrouillon.sante,
          childId: 'enfant-1',
          prenom: 'Théo',
          commenceLe: _le(1),
          modifieLe: _le(1),
          contenu: const {},
        ),
      );

      expect(relu, isNull);
    });

    test('Une ligne complète, elle, se relit', () {
      final brouillon = BrouillonProfil.fromJson({
        'type': 'activites',
        'childId': 'enfant-1',
        'prenom': 'Théo',
        'commenceLe': _le(1).toIso8601String(),
        'modifieLe': _le(2).toIso8601String(),
        'contenu': <String, dynamic>{'activites': <String, dynamic>{}},
      });

      expect(brouillon, isNotNull);
      expect(brouillon!.type, TypeBrouillon.activites);
      expect(brouillon.childId, 'enfant-1');
      expect(brouillon.prenom, 'Théo');
    });

    test('L’écriture puis la relecture rendent la même chose', () {
      final avant = _brouillon(modifieLe: _le(2));
      final apres = BrouillonProfil.fromJson(avant.toJson());

      expect(apres, isNotNull);
      expect(apres!.type, avant.type);
      expect(apres.childId, avant.childId);
      expect(apres.prenom, avant.prenom);
      expect(apres.commenceLe, avant.commenceLe);
      expect(apres.modifieLe, avant.modifieLe);
    });
  });

  group('Un brouillon ne dort pas plus de 30 jours', () {
    // Il contient des pathologies, des allergies et des traitements :
    // ces données n'ont aucune raison de rester indéfiniment sur un
    // téléphone parce que quelqu'un a été interrompu.

    test('À 29 jours, il est encore là', () {
      final brouillon = _brouillon(modifieLe: _le(1));

      expect(
        brouillonPerime(brouillon, _le(1).add(const Duration(days: 29))),
        isFalse,
      );
    });

    test('À 30 jours pile, il est encore là', () {
      final brouillon = _brouillon(modifieLe: _le(1));

      expect(
        brouillonPerime(brouillon, _le(1).add(dureeVieBrouillon)),
        isFalse,
      );
    });

    test('Une minute après, il est périmé', () {
      final brouillon = _brouillon(modifieLe: _le(1));

      expect(
        brouillonPerime(
          brouillon,
          _le(1).add(dureeVieBrouillon).add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
    });

    test('Le tri ne garde que les vivants', () {
      final vieux = _brouillon(modifieLe: _le(1), childId: 'vieux');
      final recent = _brouillon(modifieLe: _le(20), childId: 'recent');

      final restants = sansPerimes(
        [vieux, recent],
        DateTime(2026, 9, 15, 10),
      );

      expect(
        restants.map((brouillon) => brouillon.childId),
        ['recent'],
      );
    });

    test('C’est la dernière modification qui compte, pas le début', () {
      // Un parent qui reprend son questionnaire chaque semaine ne doit
      // pas le voir disparaître au trentième jour du premier écran.
      final brouillon = BrouillonProfil(
        type: TypeBrouillon.sante,
        childId: 'enfant-1',
        prenom: 'Théo',
        commenceLe: DateTime(2026, 1, 1),
        modifieLe: _le(20),
        contenu: const {},
      );

      expect(brouillonPerime(brouillon, _le(25)), isFalse);
    });
  });

  group('Le parent est prévenu qu’il reprend quelque chose', () {
    test('La phrase nomme l’enfant et le jour du début', () {
      expect(
        libelleReprise(_brouillon(modifieLe: _le(5))),
        'Reprendre le profil de Théo, commencé le 01/08',
      );
    });

    test('Le profil Activités se distingue du questionnaire santé', () {
      expect(
        libelleReprise(
          _brouillon(
            modifieLe: _le(5),
            type: TypeBrouillon.activites,
          ),
        ),
        'Reprendre le profil Activités de Théo, commencé le 01/08',
      );
    });

    test('La date est celle du début, pas celle du dernier écran', () {
      // « commencé le 01/08 » doit désigner le jour où le parent a
      // commencé : c'est ce repère-là qui lui dit de quoi il s'agit.
      final brouillon = _brouillon(modifieLe: _le(28));

      expect(libelleReprise(brouillon), contains('01/08'));
      expect(libelleReprise(brouillon), isNot(contains('28/08')));
    });
  });
}
