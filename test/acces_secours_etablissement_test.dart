import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/share_link_data.dart';
import 'package:kidsrelay/secours/ouvreur_acces_secours.dart';
import 'package:kidsrelay/secours/service_acces_secours.dart';

// L'accès secours déclenché depuis un rattachement (28/08/2026).
//
// Le mécanisme ne se déclenchait que depuis la page publique d'un lien
// de partage. Or dans une école le cas normal est le rattachement : le
// professionnel passe par l'application et ne voyait jamais le bouton
// — exactement le scénario qui a motivé le mécanisme.
//
// Ce que ces tests protègent est ce que Fanny a tranché, pas ce que le
// code fait aujourd'hui.

String _source(String chemin) => File(chemin).readAsStringSync();

/// Le code sans ses commentaires : trois fois dans ce projet, une
/// assertion de lecture de sources a été satisfaite par le commentaire
/// qui l'expliquait, et non par le code.
String _codeSansCommentaires(String chemin) {
  return _source(chemin)
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('//'))
      .join('\n');
}

void main() {
  group('Ce que le parent lit sur un accès ouvert sans lui', () {
    test('La fonction et l’établissement, dans cet ordre', () {
      expect(
        texteOuvreurAccesSecours(
          fonction: 'ATSEM',
          etablissement: 'École les Tilleuls',
        ),
        'Ouvert depuis École les Tilleuls, par « ATSEM ».',
      );
    });

    test('Jamais le nom de la personne', () {
      // Décision du 28/08/2026 : le parent doit comprendre ce qui
      // s'est passé, pas surveiller nominativement le personnel. Le
      // texte n'a donc aucune place où glisser un nom.
      final texte = texteOuvreurAccesSecours(
        fonction: 'Direction',
        etablissement: 'École les Tilleuls',
      );

      expect(texte.split('«').length, 2);
      expect(texte, isNot(contains('par Marie')));
    });

    test('La fonction est citée, jamais accordée', () {
      // Règle du 25/08/2026, dans `fonction_professionnelle.dart` :
      // l'application n'ajoute ni « une », ni « (e) », ni féminin de
      // circonstance. « ouvert par une Enseignant·e » serait faux.
      for (final fonction in [
        'Enseignant·e',
        'ATSEM',
        'AESH / AVS',
        'Santé scolaire (infirmerie)',
      ]) {
        final texte = texteOuvreurAccesSecours(
          fonction: fonction,
          etablissement: 'La Ruche',
        );

        expect(texte, contains('« $fonction »'));
        expect(texte, isNot(contains('par une ')));
        expect(texte, isNot(contains('par un ')));
      }
    });

    test('Une fonction absente est dite, pas inventée', () {
      expect(
        texteOuvreurAccesSecours(etablissement: 'La Ruche'),
        contains('n’était pas renseignée'),
      );
    });

    test('Depuis un lien, l’ouvreur est anonyme et on le dit', () {
      // « On n'invente rien » : personne ne s'est identifié.
      final texte = texteOuvreurAccesSecours();

      expect(texte, contains('lien de partage'));
      expect(texte, contains('ne s’était pas identifiée'));
    });

    test('Une chaîne vide vaut une absence', () {
      expect(
        texteOuvreurAccesSecours(fonction: '  ', etablissement: ''),
        texteOuvreurAccesSecours(),
      );
    });
  });

  group('L’adresse montrée aux soignants', () {
    test('Le jeton part dans le fragment, jamais dans la requête', () {
      // Un fragment n'est pas envoyé au serveur, n'apparaît dans aucun
      // journal d'accès et ne suit pas la personne dans un `Referer`.
      final adresse = adresseAccesSecours('abc123');

      expect(adresse, 'https://fiche.kidsrelay.fr/#jeton=abc123');
      expect(adresse, isNot(contains('?')));
    });

    test('Le nom de domaine est celui que Fanny a arrêté', () {
      expect(adressePageFiche, 'https://fiche.kidsrelay.fr');
    });
  });

  group('L’origine d’un accès secours, côté parent', () {
    ShareLinkData lireLigne(Map<String, dynamic> extra) {
      return ShareLinkData.fromRow({
        'id': 'p1',
        'token': 't1',
        'enfant_id': 'e1',
        'type_fiche': 'secours',
        'destinataire': 'structure_accueil',
        'date_creation': '2026-08-28T10:00:00.000Z',
        'date_expiration': '2026-08-29T10:00:00.000Z',
        'date_derniere_consultation': null,
        'declenche_en_secours': true,
        ...extra,
      });
    }

    test('Un accès né d’un rattachement porte son rattachement', () {
      final acces = lireLigne({
        'rattachement_origine_id': 'r1',
        'declenche_par_fonction': 'ATSEM',
      });

      expect(acces.rattachementOrigineId, 'r1');
      expect(acces.partageOrigineId, isNull);
      expect(acces.declencheParFonction, 'ATSEM');
    });

    test('Un accès né d’un lien n’a pas de fonction', () {
      final acces = lireLigne({'partage_origine_id': 'p0'});

      expect(acces.partageOrigineId, 'p0');
      expect(acces.rattachementOrigineId, isNull);
      expect(acces.declencheParFonction, isNull);
    });
  });

  group('La liste du parent range les accès sous leur origine', () {
    final code = _codeSansCommentaires('lib/children/child_profile_page.dart');

    test('Un accès dérivé ne remonte pas comme une carte détachée', () {
      // Sans les deux conditions, un accès né d'un rattachement
      // s'afficherait au premier niveau et le parent ne verrait plus
      // d'où il vient.
      expect(code, contains('link.partageOrigineId == null &&'));
      expect(code, contains('link.rattachementOrigineId == null'));
    });

    test('Il s’indente sous la carte de son établissement', () {
      expect(
        code,
        contains('autre.rattachementOrigineId == attachment.id'),
      );
      expect(
        code,
        contains('etablissement: attachment.etablissementNom'),
      );
    });

    test('Le sous-titre dit d’où vient l’accès', () {
      expect(code, contains('texteOuvreurAccesSecours('));
      expect(code, contains('fonction: derive.declencheParFonction'));
    });
  });

  group('Le geste, dans l’application', () {
    final ecran =
        _codeSansCommentaires('lib/secours/declenchement_acces_secours.dart');

    test('Le bouton est en bas de la fiche secours', () {
      // Fanny : « L'emplacement du bouton, c'est le point qui compte le
      // plus. Je le veux directement sur la fiche secours, en bas. »
      final fiche = _codeSansCommentaires(
        'lib/emergency_info/emergency_info_sheet_page.dart',
      );

      expect(fiche, contains('?piedDePage,'));

      final pro = _codeSansCommentaires(
        'lib/professional/professional_child_detail_page.dart',
      );

      expect(pro, contains('piedDePage: _boutonSecours()'));
      expect(pro, contains('BoutonAccesSecours('));
    });

    test('Le libellé est celui de la page publique', () {
      expect(ecran, contains('L’enfant part avec les secours'));
      expect(ecran, contains('Oui, l’enfant part avec les secours'));
    });

    test('La confirmation annonce la notification du parent', () {
      expect(ecran, contains('Le parent en sera informé immédiatement.'));
    });

    test('Le QR peut être réaffiché tant que l’accès est valide', () {
      // Un soignant arrive après les autres, un téléphone s'éteint.
      expect(ecran, contains('Revoir l’accès secours'));
      expect(ecran, contains('accesEnCours('));
    });

    test('Le bouton d’extension existe aussi dans l’application', () {
      expect(ecran, contains('Ajouter des appareils'));
      expect(ecran, contains('etendreAppareils('));
    });

    test('L’extension s’arrête à la borne de la contrainte', () {
      expect(ecran, contains('_appareilsMax >= 50'));
    });
  });

  group('Ce que le serveur garantit', () {
    final sql =
        _source('supabase/schema_acces_secours_etablissement.sql')
            .split('\n')
            .where((ligne) => !ligne.trimLeft().startsWith('--'))
            .join('\n');

    test('Tout membre actif peut déclencher, pas seulement un rôle', () {
      // « On ne sait pas d'avance qui montera dans le camion. Réserver
      // le bouton à un rôle recréerait le problème. »
      expect(sql, contains('est_membre_actif(p_etablissement_id)'));
      expect(sql, isNot(contains("role = 'directeur'")));
      expect(sql, isNot(contains("role in ('directeur'")));
    });

    test('La préautorisation du parent est lue sur l’enfant', () {
      // Une seule réponse par enfant, valable pour tous les canaux.
      expect(sql, contains('e.acces_secours_autorise'));
      expect(sql, contains('coalesce(v_autorise, false)'));
    });

    test('Un déclenchement retrouve l’accès déjà ouvert', () {
      expect(sql, contains('acces_secours_en_cours('));
      expect(sql, contains('secours_cree'));
    });

    test('Une origine et une seule', () {
      expect(sql, contains('secours_porte_sa_filiation'));
      expect(sql, contains('rattachement_origine_id is null'));
      expect(sql, contains('partage_origine_id is null'));
    });

    test('L’accès dérivé ne donne que la fiche secours', () {
      expect(sql, contains("'secours',"));
    });

    test('Le déclenchement écrit la notification du parent', () {
      expect(sql, contains('evenements_notification_parent'));
      expect(sql, contains("'acces_secours_declenche'"));
    });

    test('La lecture seule ne crée rien et ne notifie personne', () {
      final lecture = sql.split('create or replace function '
          'public.acces_secours_etablissement(')[1];

      expect(lecture, isNot(contains('insert into')));
    });
  });
}
