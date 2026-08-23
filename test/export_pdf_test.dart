import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/export/donnees_export.dart';
import 'package:kidsrelay/export/export_contenu.dart';
import 'package:kidsrelay/export/export_json.dart';
import 'package:kidsrelay/export/export_libelles.dart';
import 'package:kidsrelay/export/export_pdf.dart';

// Le PDF de l'export est le document qu'un parent donne à un médecin ou
// à un établissement. Ce qui est testé ici, ce sont ses règles de
// lisibilité — le rendu visuel, lui, reste à vérifier à l'œil.
//
// La règle la plus importante est celle du repli : le rendu est
// générique, donc un champ ajouté plus tard sort tout seul, au pire
// avec un intitulé maladroit. Sur un document qui prétend être
// complet, une omission silencieuse serait le pire des défauts.

void main() {
  // La generation du PDF lit les polices embarquees depuis les assets :
  // sans liaison initialisee, rootBundle n'existe pas.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intitulés', () {
    test('Un champ connu porte son intitulé français', () {
      expect(libelleChamp('date_naissance'), 'Date de naissance');
      expect(libelleChamp('traitements_urgence'), 'Traitements d’urgence');
      expect(libelleChamp('emergencyInstructionSteps'), 'Consignes d’urgence');
    });

    test('Un champ inconnu sort quand même, sous un nom présentable', () {
      // Le dictionnaire n'est pas une liste blanche : rien ne doit
      // disparaître faute d'y figurer.
      expect(libelleChamp('nombre_de_repas'), 'Nombre de repas');
      expect(libelleChamp('champ_ajoute_plus_tard'), 'Champ ajoute plus tard');
    });

    test('Un champ en camelCase inconnu est découpé', () {
      expect(libelleChamp('nouveauChampInconnu'), 'Nouveau champ inconnu');
    });

    test('Un nom vide ne fait pas échouer le rendu', () {
      expect(libelleChamp(''), '');
      expect(libelleChamp('_'), '_');
    });
  });

  group('Valeurs lisibles', () {
    test('Les booléens deviennent Oui et Non', () {
      expect(valeurLisible(true), 'Oui');
      expect(valeurLisible(false), 'Non');
    });

    test('Les codes internes deviennent leur libellé', () {
      // Un parent ne doit pas avoir à deviner ce que veut dire
      // « structure_accueil ».
      expect(valeurLisible('structure_accueil'), 'Structure d’accueil');
      expect(valeurLisible('lecture'), 'Consultation seule');
      expect(valeurLisible('ce_qu_il_faut_savoir'), 'Ce qu’il faut savoir');
    });

    test('Une date seule devient une date française', () {
      expect(valeurLisible('2019-04-12'), '12/04/2019');
    });

    test('Une date avec heure garde son heure', () {
      final rendu = valeurLisible('2026-08-23T12:30:00.000Z');

      expect(rendu, contains('23/08/2026'));
      expect(rendu, contains('h'));
    });

    test('Une date approximative écrite par le parent n’est pas précisée', () {
      // « diagnostiquée vers 2024 » ne doit pas devenir « 01/01/2024 » :
      // ce serait plus précis que ce que le parent a écrit.
      expect(valeurLisible('2024'), '2024');
      expect(valeurLisible('vers 2024'), 'vers 2024');
      expect(valeurLisible('printemps 2023'), 'printemps 2023');
    });

    test('Un texte libre passe tel quel', () {
      expect(
        valeurLisible('A refusé le goûter, sans autre signe.'),
        'A refusé le goûter, sans autre signe.',
      );
    });

    test('Un nombre se lit', () {
      expect(valeurLisible(18), '18');
      expect(valeurLisible(1.5), '1.5');
    });
  });

  group('Ce qui compte comme vide', () {
    test('Null, chaîne vide et espaces sont vides', () {
      expect(estVide(null), isTrue);
      expect(estVide(''), isTrue);
      expect(estVide('   '), isTrue);
    });

    test('Une liste ou un objet sans contenu utile est vide', () {
      expect(estVide(<dynamic>[]), isTrue);
      expect(estVide([null, '', '  ']), isTrue);
      expect(estVide(<String, dynamic>{}), isTrue);
      expect(estVide({'a': null, 'b': ''}), isTrue);
    });

    test('« Non » n’est pas une absence d’information', () {
      // « Ne sait pas nager : non » doit s'imprimer. C'est justement ce
      // qu'un accompagnant a besoin de savoir.
      expect(estVide(false), isFalse);
      expect(estVide({'sait_nager': false}), isFalse);
    });

    test('Zéro n’est pas une absence d’information', () {
      expect(estVide(0), isFalse);
    });
  });

  group('Contenu du document', () {
    DonneesExport donnees({
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

    List<String> textes(DonneesExport export) {
      return pagesExport(export)
          .expand((page) => page)
          .map((bloc) => bloc.texte)
          .toList();
    }

    test('La première page explique ce qu’est le document', () {
      final premiere =
          pagesExport(donnees()).first.map((bloc) => bloc.texte).join(' ');

      expect(premiere, contains('droit d’accès'));
      expect(premiere, contains('RGPD'));
      expect(premiere, contains('23/08/2026'));
      expect(premiere, contains('parent@exemple.fr'));
    });

    test('Chaque enfant occupe sa propre page', () {
      // Sur un export de plusieurs enfants, deux fiches qui se suivent
      // sur la même page se confondent.
      final pages = pagesExport(
        donnees(
          enfants: [
            _enfantTresRempli('noe', 'Noé'),
            _enfantTresRempli('theo', 'Théo'),
          ],
        ),
      );

      expect(pages, hasLength(3));
      expect(pages[1].first.texte, 'Noé Dupont');
      expect(pages[2].first.texte, 'Théo Dupont');
    });

    test('Les huit rubriques d’un enfant sont titrées', () {
      final titres = pagesExport(
        donnees(enfants: [_enfantTresRempli('noe', 'Noé')]),
      )[1]
          .where((bloc) => bloc.style == StyleBloc.titreSection)
          .map((bloc) => bloc.texte)
          .toList();

      expect(titres, [
        'Identité',
        'Profil de santé',
        'Profil activités',
        'Liens de partage',
        'Rattachements à un établissement',
        'Notes ajoutées par un professionnel',
        'Consultations de la fiche',
        'Personnes de confiance',
      ]);
    });

    test('Une rubrique vide est dite vide, pas omise', () {
      // « Aucun partage » est une information. Son absence pourrait
      // passer pour un oubli.
      final page = pagesExport(
        donnees(
          enfants: [
            const EnfantExporte(
              enfantId: 'noe',
              enfant: {'id': 'noe', 'prenom': 'Noé'},
              profilSante: null,
              profilActivites: null,
            ),
          ],
        ),
      )[1];

      final apresPartages = page
          .skipWhile((bloc) => bloc.texte != 'Liens de partage')
          .skip(1)
          .first;

      expect(apresPartages.texte, 'Aucune donnée enregistrée.');
    });

    test('Aucun jeton de partage ne figure dans le document', () {
      // Le document est fait pour être transmis à un médecin ou à un
      // établissement : un jeton actif leur donnerait accès à la fiche
      // de l’enfant.
      final tout =
          textes(donnees(enfants: [_enfantTresRempli('noe', 'Noé')])).join('\n');

      expect(tout, isNot(contains('jeton-secret')));
      expect(tout, contains('Jeton : $jetonRetire'));
    });

    test('Aucun identifiant technique ne figure dans le document', () {
      final tout =
          textes(donnees(enfants: [_enfantTresRempli('noe', 'Noé')])).join('\n');

      expect(tout, isNot(contains('parent-1')));
      expect(tout, isNot(contains('Enfant id')));
    });

    test('Le contenu réellement saisi est présent', () {
      final tout =
          textes(donnees(enfants: [_enfantTresRempli('noe', 'Noé')])).join('\n');

      expect(tout, contains('Prénom : Noé'));
      expect(tout, contains('Date de naissance : 12/04/2019'));
      expect(tout, contains('Allergène : Allergène 0'));
      expect(tout, contains('Mettre en position latérale de sécurité'));
      expect(tout, contains('Dr Martin'));
      expect(tout, contains('Note numéro 0'));
      expect(tout, contains('Destinataire : Structure d’accueil'));
      expect(tout, contains('Niveau d’accès : Consultation seule'));
    });

    test('Un champ vide n’encombre pas le document', () {
      final tout = textes(
        donnees(
          enfants: [
            const EnfantExporte(
              enfantId: 'noe',
              enfant: {
                'id': 'noe',
                'prenom': 'Noé',
                'nom': null,
                'date_naissance': '',
              },
              profilSante: null,
              profilActivites: null,
            ),
          ],
        ),
      ).join('\n');

      expect(tout, contains('Prénom : Noé'));
      expect(tout, isNot(contains('Date de naissance')));
      expect(tout, isNot(contains('Nom :')));
    });

    test('Une réponse « non » est imprimée, ce n’est pas un vide', () {
      final tout =
          textes(donnees(enfants: [_enfantTresRempli('noe', 'Noé')])).join('\n');

      expect(tout, contains('Non'));
    });

    test('Un export sans enfant le dit', () {
      final tout = textes(donnees()).join('\n');

      expect(tout, contains('Aucun enfant n’est rattaché à ce compte'));
    });

    test('Les activités préparées font leur propre page', () {
      final pages = pagesExport(
        donnees(
          activites: [
            {'id': 'a1', 'nom_activite': 'Sortie piscine'},
          ],
        ),
      );

      expect(pages, hasLength(2));
      expect(pages.last.first.texte, 'Activités que vous avez préparées');
      expect(
        pages.last.map((bloc) => bloc.texte).join('\n'),
        contains('Nom de l’activité : Sortie piscine'),
      );
    });
  });

  group('Document produit', () {
    test('Un export sans enfant produit quand même un PDF', () async {
      final octets = await construireExportPdf(
        DonneesExport(
          compte: const CompteExporte(
            id: 'parent-1',
            email: 'parent@exemple.fr',
          ),
          enfants: const [],
          activitesPreparees: const [],
          exporteLe: DateTime.utc(2026, 8, 23, 12),
        ),
      );

      expect(octets.length, greaterThan(0));
    });

    test('Plusieurs enfants et un profil très rempli passent', () async {
      // Vérifie que la génération ne casse pas sur des données
      // profondément imbriquées et volumineuses. La mise en page, elle,
      // reste à regarder à l’œil.
      final octets = await construireExportPdf(
        DonneesExport(
          compte: const CompteExporte(id: 'parent-1', email: 'p@e.fr'),
          enfants: [
            _enfantTresRempli('noe', 'Noé'),
            _enfantTresRempli('theo', 'Théo'),
          ],
          activitesPreparees: [
            for (var i = 0; i < 30; i++)
              {'id': 'a$i', 'nom_activite': 'Sortie $i'},
          ],
          exporteLe: DateTime.utc(2026, 8, 23, 12),
        ),
      );

      expect(octets.length, greaterThan(0));
    });
  });
}

EnfantExporte _enfantTresRempli(String id, String prenom) {
  return EnfantExporte(
    enfantId: id,
    enfant: {
      'id': id,
      'parent_id': 'parent-1',
      'prenom': prenom,
      'nom': 'Dupont',
      'date_naissance': '2019-04-12',
      'poids': 18,
      'taille': 108,
    },
    profilSante: {
      'enfant_id': id,
      'pathologies': [
        for (var i = 0; i < 12; i++)
          {
            'name': 'Pathologie $i',
            'approximateDiagnosisDate': '2024',
            'emergencyInstructionSteps': [
              'Mettre en position latérale de sécurité',
              'Déclencher un chronomètre',
              'Donner le traitement après le délai indiqué',
            ],
          },
      ],
      'allergies': [
        for (var i = 0; i < 10; i++)
          {
            'allergen': 'Allergène $i',
            'observedReaction': 'Urticaire et gonflement des lèvres',
          },
      ],
      'medecin_traitant': {
        'name': 'Dr Martin',
        'workplace': 'Cabinet des Tilleuls',
        'phoneNumber': '01 23 45 67 89',
      },
      'contacts_urgence': [
        for (var i = 0; i < 6; i++)
          {
            'fullName': 'Contact $i',
            'relationship': 'Grand-parent',
            'phoneNumber': '06 00 00 00 0$i',
          },
      ],
    },
    profilActivites: {
      'enfant_id': id,
      'repas': {
        'hasChokingRisk': true,
        'preparations': ['smallPieces', 'minced'],
        'warningSignsDetails': 'Toux répétée pendant le repas',
      },
      'transport': {'hasMotionSickness': false},
    },
    partages: [
      for (var i = 0; i < 8; i++)
        {
          'id': 'p$i',
          'token': 'jeton-secret-$i',
          'type_fiche': 'secours',
          'destinataire': 'structure_accueil',
          'date_creation': '2026-08-0${i % 9}T10:00:00.000Z',
          'date_expiration': '2026-09-0${i % 9}T10:00:00.000Z',
        },
    ],
    notesProfessionnelles: [
      for (var i = 0; i < 20; i++)
        {
          'id': 'n$i',
          'note': 'Note numéro $i, avec un texte assez long pour '
              'occuper plusieurs lignes dans le document imprimé.',
          'cree_le': '2026-08-1${i % 9}T15:00:00.000Z',
        },
    ],
    journalConsultations: [
      for (var i = 0; i < 25; i++)
        {
          'id': 'j$i',
          'type_fiche': 'secours',
          'consulte_le': '2026-08-1${i % 9}T09:00:00.000Z',
          'etablissements': {'nom': 'École des Lilas'},
        },
    ],
    personnesDeConfiance: [
      {
        'id': 'c1',
        'email': 'mamie@exemple.fr',
        'niveau_acces': 'lecture',
        'statut': 'actif',
        'invite_le': '2026-07-01T10:00:00.000Z',
      },
    ],
  );
}
