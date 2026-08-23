import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/export/export_json.dart';
import 'package:kidsrelay/export/source_export.dart';

import 'support/fake_source_export.dart';

// Le cloisonnement de l'export RGPD.
//
// `enfants` renvoie, par le RLS, les enfants du parent **et** ceux sur
// lesquels il est personne de confiance (voir
// `ChildRepository.loadFromSupabase`, qui fait un select sans filtre).
// Exporter cette liste telle quelle mettrait l'enfant d'une autre
// famille dans un document que le parent transmettra à son médecin.
//
// C'est la faille que ces tests ferment.

final _maintenant = DateTime.utc(2026, 8, 23, 12);

Map<String, dynamic> _enfantDe(
  String parentId, {
  required String id,
  String prenom = 'Enfant',
}) {
  return {'id': id, 'parent_id': parentId, 'prenom': prenom};
}

void main() {
  group('Un enfant n’est exporté que par son parent', () {
    test('Les enfants du compte connecté sortent', () async {
      final source = FakeSourceExport(
        lignesEnfants: [
          _enfantDe('parent-1', id: 'noe', prenom: 'Noé'),
          _enfantDe('parent-1', id: 'theo', prenom: 'Théo'),
        ],
      );

      final donnees = await collecterExport(source, _maintenant);

      expect(
        donnees.enfants.map((e) => e.enfantId),
        ['noe', 'theo'],
      );
    });

    test(
      'Un enfant sur lequel le compte est seulement personne de '
      'confiance ne sort pas',
      () async {
        final source = FakeSourceExport(
          identifiantCompte: 'parent-1',
          lignesEnfants: [
            _enfantDe('parent-1', id: 'noe', prenom: 'Noé'),
            // Visible par le RLS, mais appartenant à quelqu'un d'autre.
            _enfantDe('parent-2', id: 'lila', prenom: 'Lila'),
          ],
        );

        final donnees = await collecterExport(source, _maintenant);

        expect(donnees.enfants.map((e) => e.enfantId), ['noe']);
      },
    );

    test(
      'Aucune donnée de l’enfant d’autrui n’est même lue',
      () async {
        // Ne pas l'écrire dans le document ne suffit pas : il ne doit
        // pas non plus transiter par l'appareil.
        final source = FakeSourceExport(
          lignesEnfants: [
            _enfantDe('parent-1', id: 'noe'),
            _enfantDe('parent-2', id: 'lila'),
          ],
          sante: {
            'lila': {'allergies': ['arachide']},
          },
        );

        await collecterExport(source, _maintenant);

        expect(
          source.lectures.where((l) => l.endsWith(':lila')),
          isEmpty,
        );
        expect(source.lectures, contains('sante:noe'));
      },
    );

    test(
      'Le nom de l’enfant d’autrui n’apparaît nulle part dans le '
      'fichier produit',
      () async {
        final source = FakeSourceExport(
          lignesEnfants: [
            _enfantDe('parent-1', id: 'noe', prenom: 'Noé'),
            _enfantDe('parent-2', id: 'lila', prenom: 'Lila'),
          ],
        );

        final texte = encoderExportJson(
          await collecterExport(source, _maintenant),
        );

        expect(texte, contains('Noé'));
        expect(texte, isNot(contains('Lila')));
        expect(texte, isNot(contains('parent-2')));
      },
    );

    test(
      'Une personne de confiance sans enfant à elle produit un export '
      'sans aucun enfant',
      () async {
        final source = FakeSourceExport(
          identifiantCompte: 'confiance-1',
          emailCompte: 'mamie@exemple.fr',
          lignesEnfants: [
            _enfantDe('parent-1', id: 'noe', prenom: 'Noé'),
          ],
        );

        final donnees = await collecterExport(source, _maintenant);

        expect(donnees.enfants, isEmpty);
        expect(donnees.compte.email, 'mamie@exemple.fr');
      },
    );

    test('Un enfant sans identifiant est ignoré, pas exporté à moitié',
        () async {
      final source = FakeSourceExport(
        lignesEnfants: [
          {'parent_id': 'parent-1', 'prenom': 'Sans identifiant'},
          _enfantDe('parent-1', id: 'noe'),
        ],
      );

      final donnees = await collecterExport(source, _maintenant);

      expect(donnees.enfants.map((e) => e.enfantId), ['noe']);
    });
  });

  group('Disponibilité de la fonction', () {
    test('Un parent qui possède un enfant y a droit', () {
      expect(
        possedeAuMoinsUnEnfant(
          [_enfantDe('parent-1', id: 'noe')],
          'parent-1',
        ),
        isTrue,
      );
    });

    test('Une personne de confiance en consultation seule n’y a pas droit',
        () {
      // Elle voit l'enfant, mais ne le possède pas : la fonction ne lui
      // est pas proposée.
      expect(
        possedeAuMoinsUnEnfant(
          [_enfantDe('parent-1', id: 'noe')],
          'confiance-1',
        ),
        isFalse,
      );
    });

    test(
      'Un compte à la fois parent et personne de confiance y a droit',
      () {
        expect(
          possedeAuMoinsUnEnfant(
            [
              _enfantDe('parent-2', id: 'lila'),
              _enfantDe('parent-1', id: 'noe'),
            ],
            'parent-1',
          ),
          isTrue,
        );
      },
    );

    test('Un compte sans aucun enfant visible n’y a pas droit', () {
      expect(possedeAuMoinsUnEnfant([], 'parent-1'), isFalse);
    });

    test('Sans session, la fonction n’est pas proposée', () {
      expect(
        possedeAuMoinsUnEnfant(
          [_enfantDe('parent-1', id: 'noe')],
          null,
        ),
        isFalse,
      );
    });
  });

  group('Refus plutôt qu’export partiel', () {
    test('Sans compte connecté, la collecte échoue clairement', () async {
      final source = FakeSourceExport(identifiantCompte: null);

      expect(
        () => collecterExport(source, _maintenant),
        throwsA(isA<ExportImpossible>()),
      );
    });

    test('Une lecture qui échoue fait échouer l’export entier', () async {
      // Un document intitulé « copie complète de vos données » qui n'est
      // pas complet vaut moins que pas de document du tout.
      final source = _SourceQuiEchoue();

      expect(
        () => collecterExport(source, _maintenant),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Contenu rassemblé', () {
    test('Les huit rubriques sont demandées pour chaque enfant', () async {
      final source = FakeSourceExport(
        lignesEnfants: [
          _enfantDe('parent-1', id: 'noe'),
          _enfantDe('parent-1', id: 'theo'),
        ],
      );

      await collecterExport(source, _maintenant);

      for (final enfant in ['noe', 'theo']) {
        for (final rubrique in [
          'sante',
          'activites',
          'partages',
          'rattachements',
          'notes',
          'journal',
          'confiance',
        ]) {
          expect(source.lectures, contains('$rubrique:$enfant'));
        }
      }

      expect(source.lectures, contains('activitesPreparees:parent-1'));
    });

    test('Les activités préparées sont celles du compte connecté', () async {
      final source = FakeSourceExport(
        identifiantCompte: 'parent-1',
        lignesActivitesPreparees: [
          {'id': 'a1', 'nom_activite': 'Sortie piscine'},
        ],
      );

      final donnees = await collecterExport(source, _maintenant);

      expect(donnees.activitesPreparees, hasLength(1));
      expect(source.lectures, contains('activitesPreparees:parent-1'));
    });

    test('La date d’export est celle qu’on lui donne', () async {
      final donnees = await collecterExport(
        FakeSourceExport(),
        DateTime.utc(2026, 12, 25, 9, 30),
      );

      expect(donnees.exporteLe, DateTime.utc(2026, 12, 25, 9, 30));
    });
  });
}

class _SourceQuiEchoue extends FakeSourceExport {
  _SourceQuiEchoue()
      : super(
          lignesEnfants: const [
            {'id': 'noe', 'parent_id': 'parent-1'},
          ],
        );

  @override
  Future<Map<String, dynamic>?> profilSante(String enfantId) async {
    throw Exception('base injoignable');
  }
}
