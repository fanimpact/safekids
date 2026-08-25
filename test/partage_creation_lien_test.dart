import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/journal_consultation_data.dart';

// Corrections du 25/08/2026 sur le partage d'un lien.
//
// Ce fichier couvre ce qui se teste sans Supabase : la lecture d'une
// ligne de journal et la distinction des deux origines. L'écran de
// création, lui, lit directement `ChildRepository.instance` et le SDK,
// donc ne se monte pas dans un test — les vérifications qui le
// concernent sont dans `docs/audits/a_verifier_sur_mobile.md`.

void main() {
  group('Origine d’une consultation', () {
    JournalConsultationData ligne(Map<String, dynamic> surcharges) {
      return JournalConsultationData.fromRow({
        'id': 'journal-1',
        'enfant_id': 'enfant-1',
        'etablissement_id': null,
        'type_fiche': 'secours',
        'consulte_le': '2026-08-25T09:30:00.000Z',
        ...surcharges,
      });
    }

    test('Une ouverture de lien est reconnue comme telle', () {
      expect(
        ligne({'origine': 'lien_partage'}).origine,
        OrigineConsultation.lienPartage,
      );
    });

    test('Une consultation par un établissement est reconnue', () {
      expect(
        ligne({
          'origine': 'etablissement',
          'etablissement_id': 'etab-1',
          'etablissements': {'nom': 'École des Lilas'},
        }).origine,
        OrigineConsultation.etablissement,
      );
    });

    test(
      'Une ligne écrite avant le 25/08/2026 vient d’un établissement',
      () {
        // La colonne `origine` n'existait pas : toutes les lignes
        // antérieures viennent d'un membre du personnel rattaché.
        expect(
          ligne({}).origine,
          OrigineConsultation.etablissement,
        );
      },
    );

    test('Une valeur inconnue ne se fait pas passer pour un lien', () {
      // En cas de doute, la ligne est présentée comme une consultation
      // d'établissement : c'est l'origine la plus ancienne, et la plus
      // vraisemblable.
      expect(
        ligne({'origine': 'quelque_chose'}).origine,
        OrigineConsultation.etablissement,
      );
    });

    test('Une ouverture de lien n’a pas d’établissement', () {
      final consultation = ligne({'origine': 'lien_partage'});

      expect(consultation.etablissementId, isNull);
      expect(consultation.etablissementNom, isNull);
    });
  });

  group('Type de fiche', () {
    JournalConsultationData avecType(String type) {
      return JournalConsultationData.fromRow({
        'id': 'journal-1',
        'enfant_id': 'enfant-1',
        'etablissement_id': null,
        'type_fiche': type,
        'consulte_le': '2026-08-25T09:30:00.000Z',
        'origine': 'lien_partage',
      });
    }

    test('Les recommandations d’activité sont reconnues', () {
      // Ce type manquait : un lien de partage peut porter une fiche de
      // recommandations, et le journal ne savait pas la nommer.
      expect(
        avecType('recommandations_activite').typeFiche,
        TypeFicheConsultee.recommandationsActivite,
      );
      expect(
        typeFicheConsulteeLabel(
          TypeFicheConsultee.recommandationsActivite,
        ),
        'Recommandations d’activité',
      );
    });

    test('Les trois types partageables ont tous un libellé', () {
      for (final type in [
        'secours',
        'ce_qu_il_faut_savoir',
        'recommandations_activite',
      ]) {
        final libelle = typeFicheConsulteeLabel(
          avecType(type).typeFiche,
        );

        expect(libelle, isNotEmpty);
        expect(libelle, isNot(contains('_')));
      }
    });

    test('Chaque valeur de l’énumération a un libellé', () {
      for (final type in TypeFicheConsultee.values) {
        expect(typeFicheConsulteeLabel(type), isNotEmpty);
      }
    });
  });

  group('Horodatage', () {
    test('La date et l’heure sont conservées', () {
      final consultation = JournalConsultationData.fromRow({
        'id': 'journal-1',
        'enfant_id': 'enfant-1',
        'etablissement_id': null,
        'type_fiche': 'secours',
        'consulte_le': '2026-08-25T09:30:00.000Z',
        'origine': 'lien_partage',
      });

      expect(
        consultation.consulteLe.toUtc(),
        DateTime.utc(2026, 8, 25, 9, 30),
      );
    });
  });

  group('Les explications de l’écran sont en place', () {
    // Garde de câblage. L'écran lit `ChildRepository.instance` et le
    // SDK : il ne se monte pas dans un test. Or ces textes peuvent
    // disparaître sans rien casser — aucun écran ne tomberait, aucun
    // test existant ne broncherait, et un parent partagerait des
    // données de santé sans savoir ce qu'il transmet. Le test lit donc
    // la source.
    final source = File(
      'lib/sharing/create_share_link_page.dart',
    ).readAsStringSync();

    test('Chaque fiche dit ce qu’elle contient', () {
      // Les trois intitulés sonnent proches ; sans repère, on coche le
      // premier — et le premier est le plus complet.
      expect(source, contains('C’est la fiche la plus complète.'));
      expect(
        source,
        contains('sans les gestes d’urgence ni le médecin '),
      );
      expect(source, contains('Figée au moment '));
    });

    test('La fiche de recommandations prévient qu’elle est figée', () {
      // Un parent qui corrige une allergie demain doit savoir que le
      // lien déjà envoyé continuera d'afficher l'ancienne version.
      expect(
        source,
        contains('vos modifications ultérieures n’y apparaîtront '),
      );
    });

    test('L’écran dit que le lien s’ouvre sans compte', () {
      expect(
        source,
        contains('s’ouvre sans compte et sans mot de passe'),
      );
      expect(source, contains('le transmettre à quelqu’un d’autre'));
    });

    test('Cet avertissement est en ambre, pas en gris', () {
      // C'est ce qui rend le lien transférable à n'importe qui : ça
      // doit se voir. Le rouge, lui, reste réservé à l'urgence vitale
      // et n'a rien à faire sur cet écran.
      final ambre = source.indexOf('ambreFond');
      final texte = source.indexOf('s’ouvre sans compte');

      expect(ambre, greaterThan(-1));
      expect(texte, greaterThan(ambre));
      expect(source, isNot(contains('KidsRelayColors.urgence')));
    });

    test('L’écran dit quand le lien expire, et qu’on ne prolonge pas',
        () {
      expect(source, contains('Le lien cessera de fonctionner le '));
      expect(source, contains('Il ne peut pas être prolongé'));
      expect(source, contains('n’affiche plus rien'));
    });

    test('L’écran dit où couper le lien, et ce que couper ne fait pas',
        () {
      // Un parent qui coupe en urgence doit savoir que couper n'efface
      // pas : sinon il croit le problème réglé.
      expect(source, contains('section « Partages »'));
      expect(source, contains('La coupure est '));
      expect(
        source,
        contains('ce qui a déjà été lu ou copié reste chez '),
      );
    });
  });
}
