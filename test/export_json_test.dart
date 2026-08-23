import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/export/donnees_export.dart';
import 'package:kidsrelay/export/export_json.dart';

// Fichier de données de l'export RGPD. Deux choses s'y jouent : qu'il
// contienne bien tout ce que l'application détient, et qu'il ne
// distribue pas de clé d'accès en même temps — il est fait pour être
// transmis à un médecin ou à un établissement.

DonneesExport _donnees({
  List<EnfantExporte> enfants = const [],
  List<Map<String, dynamic>> activites = const [],
}) {
  return DonneesExport(
    compte: const CompteExporte(
      id: 'parent-1',
      email: 'parent@exemple.fr',
    ),
    enfants: enfants,
    activitesPreparees: activites,
    exporteLe: DateTime.utc(2026, 8, 23, 12),
  );
}

EnfantExporte _enfant({
  String id = 'enfant-1',
  Map<String, dynamic>? enfant,
  Map<String, dynamic>? sante,
  Map<String, dynamic>? activites,
  List<Map<String, dynamic>> partages = const [],
  List<Map<String, dynamic>> rattachements = const [],
  List<Map<String, dynamic>> notes = const [],
  List<Map<String, dynamic>> journal = const [],
  List<Map<String, dynamic>> confiance = const [],
}) {
  return EnfantExporte(
    enfantId: id,
    enfant: enfant ??
        {
          'id': id,
          'parent_id': 'parent-1',
          'prenom': 'Noé',
          'nom': 'Dupont',
        },
    profilSante: sante,
    profilActivites: activites,
    partages: partages,
    rattachementsEtablissement: rattachements,
    notesProfessionnelles: notes,
    journalConsultations: journal,
    personnesDeConfiance: confiance,
  );
}

void main() {
  group('Structure du fichier', () {
    test('Le fichier s’annonce, se date et se versionne', () {
      final json = construireExportJson(_donnees());

      expect(json['format'], 'kidsrelay-export-donnees');
      expect(json['version_format'], DonneesExport.versionFormat);
      expect(json['exporte_le'], '2026-08-23T12:00:00.000Z');
    });

    test('Un texte explique ce qu’est le fichier', () {
      // Un fichier de données réutilisable qui n'explique pas ce qu'il
      // contient rate la moitié de son but : le parent doit pouvoir le
      // comprendre sans nous.
      final lisezMoi = construireExportJson(_donnees())['_lisez_moi']
          as String;

      expect(lisezMoi, contains('droit d’accès'));
      expect(lisezMoi, contains('RGPD'));
      expect(lisezMoi, contains('jetons'));
    });

    test('Le compte du parent y figure', () {
      final compte =
          construireExportJson(_donnees())['compte']
              as Map<String, dynamic>;

      expect(compte['id'], 'parent-1');
      expect(compte['email'], 'parent@exemple.fr');
    });

    test('Les huit rubriques d’un enfant sont présentes, même vides', () {
      final enfants =
          construireExportJson(_donnees(enfants: [_enfant()]))['enfants']
              as List<dynamic>;

      final rubriques =
          (enfants.single as Map<String, dynamic>).keys.toList();

      expect(rubriques, [
        'enfant',
        'profil_sante',
        'profil_activites',
        'partages',
        'rattachements_etablissement',
        'notes_professionnelles',
        'journal_consultations',
        'personnes_de_confiance',
      ]);
    });

    test('Une rubrique sans donnée sort vide, jamais absente', () {
      final enfants =
          construireExportJson(_donnees(enfants: [_enfant()]))['enfants']
              as List<dynamic>;

      final rubriques = enfants.single as Map<String, dynamic>;

      // "Aucun partage" et "on ne sait pas" ne doivent pas se
      // ressembler dans un document qui prouve ce qui est détenu.
      expect(rubriques['partages'], isEmpty);
      expect(rubriques['journal_consultations'], isEmpty);
      expect(rubriques['profil_sante'], isNull);
    });
  });

  group('Jetons retirés', () {
    test('Le jeton d’un partage est remplacé, pas le partage', () {
      final json = construireExportJson(
        _donnees(
          enfants: [
            _enfant(
              partages: [
                {
                  'id': 'partage-1',
                  'token': 'jeton-secret-actif',
                  'type_fiche': 'secours',
                  'date_creation': '2026-08-01T10:00:00.000Z',
                  'date_expiration': '2026-09-01T10:00:00.000Z',
                  'date_derniere_consultation': null,
                },
              ],
            ),
          ],
        ),
      );

      final partage = ((json['enfants'] as List<dynamic>).single
              as Map<String, dynamic>)['partages'] as List<dynamic>;

      final ligne = partage.single as Map<String, dynamic>;

      expect(ligne['token'], jetonRetire);
      expect(ligne['id'], 'partage-1');
      expect(ligne['type_fiche'], 'secours');
      expect(ligne['date_expiration'], '2026-09-01T10:00:00.000Z');
    });

    test('Aucun jeton actif ne survit nulle part dans le fichier', () {
      final texte = encoderExportJson(
        _donnees(
          enfants: [
            _enfant(
              partages: [
                {'id': 'p1', 'token': 'jeton-partage'},
              ],
              rattachements: [
                {'id': 'r1', 'token': 'jeton-rattachement'},
              ],
            ),
          ],
          activites: [
            {'id': 'a1', 'jeton': 'jeton-activite'},
          ],
        ),
      );

      expect(texte, isNot(contains('jeton-partage')));
      expect(texte, isNot(contains('jeton-rattachement')));
      expect(texte, isNot(contains('jeton-activite')));
    });

    test('Un jeton absent reste absent, pas remplacé par une mention', () {
      final ligne = ligneSansJeton({'id': 'p1', 'token': null});

      expect(ligne['token'], isNull);
    });

    test('Les autres colonnes ne sont pas touchées', () {
      final ligne = ligneSansJeton({
        'id': 'p1',
        'token': 'secret',
        'destinataire': 'structure_accueil',
        'nombre': 3,
        'actif': true,
      });

      expect(ligne['destinataire'], 'structure_accueil');
      expect(ligne['nombre'], 3);
      expect(ligne['actif'], true);
    });
  });

  group('Contenu complet', () {
    test('Les sept rubriques demandées sortent avec leur contenu', () {
      final json = construireExportJson(
        _donnees(
          enfants: [
            _enfant(
              sante: {'enfant_id': 'enfant-1', 'allergies': []},
              activites: {'enfant_id': 'enfant-1', 'repas': {}},
              partages: [
                {'id': 'p1'}
              ],
              rattachements: [
                {'id': 'r1'}
              ],
              notes: [
                {'id': 'n1', 'note': 'A bien mangé.'}
              ],
              journal: [
                {'id': 'j1'}
              ],
              confiance: [
                {'id': 'c1', 'email': 'mamie@exemple.fr'}
              ],
            ),
          ],
          activites: [
            {'id': 'a1', 'nom_activite': 'Sortie piscine'},
          ],
        ),
      );

      final enfant = (json['enfants'] as List<dynamic>).single
          as Map<String, dynamic>;

      expect(enfant['profil_sante'], isNotNull);
      expect(enfant['profil_activites'], isNotNull);
      expect(enfant['partages'], hasLength(1));
      expect(enfant['rattachements_etablissement'], hasLength(1));
      expect(enfant['notes_professionnelles'], hasLength(1));
      expect(enfant['journal_consultations'], hasLength(1));
      expect(enfant['personnes_de_confiance'], hasLength(1));
      expect(json['activites_preparees'], hasLength(1));
    });

    test('Le texte d’une note professionnelle est conservé tel quel', () {
      // C'est une donnée personnelle concernant l'enfant : elle doit
      // sortir, pas être résumée.
      final texte = encoderExportJson(
        _donnees(
          enfants: [
            _enfant(
              notes: [
                {'note': 'A refusé le goûter, sans autre signe.'},
              ],
            ),
          ],
        ),
      );

      expect(
        texte,
        contains('A refusé le goûter, sans autre signe.'),
      );
    });

    test('Plusieurs enfants sortent chacun dans leur rubrique', () {
      final json = construireExportJson(
        _donnees(
          enfants: [
            _enfant(id: 'enfant-1'),
            _enfant(
              id: 'enfant-2',
              enfant: {
                'id': 'enfant-2',
                'parent_id': 'parent-1',
                'prenom': 'Théo',
              },
            ),
          ],
        ),
      );

      final enfants = json['enfants'] as List<dynamic>;

      expect(enfants, hasLength(2));
      expect(
        (enfants[1] as Map<String, dynamic>)['enfant'],
        containsPair('prenom', 'Théo'),
      );
    });
  });

  group('Fichier écrit', () {
    test('Le texte produit est du JSON relisible', () {
      final texte = encoderExportJson(
        _donnees(enfants: [_enfant()]),
      );

      final relu = jsonDecode(texte) as Map<String, dynamic>;

      expect(relu['format'], 'kidsrelay-export-donnees');
    });

    test('Il est indenté, pour rester lisible dans un éditeur', () {
      final texte = encoderExportJson(_donnees());

      expect(texte, contains('\n  "format"'));
    });

    test('Les accents survivent à l’encodage', () {
      final texte = encoderExportJson(
        _donnees(enfants: [_enfant()]),
      );

      expect(texte, contains('Noé'));

      // Et après un aller-retour par des octets, comme lors de
      // l'écriture du fichier.
      final relu = jsonDecode(utf8.decode(utf8.encode(texte)))
          as Map<String, dynamic>;

      final enfant = ((relu['enfants'] as List<dynamic>).single
          as Map<String, dynamic>)['enfant'] as Map<String, dynamic>;

      expect(enfant['prenom'], 'Noé');
    });

    test('Le nom de fichier porte la date de l’export', () {
      expect(
        nomFichierExport(DateTime.utc(2026, 8, 23)),
        'kidsrelay-mes-donnees-2026-08-23',
      );
      expect(
        nomFichierExport(DateTime.utc(2026, 1, 5)),
        'kidsrelay-mes-donnees-2026-01-05',
      );
    });
  });
}
