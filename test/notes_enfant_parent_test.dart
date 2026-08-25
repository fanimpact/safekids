import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/note_enfant_data.dart';

// Les notes d'établissement vues par le parent (25/08/2026).
//
// Le défaut corrigé : les notes existaient en base, le parent avait le
// droit de les lire, l'email lui disait de se connecter pour les
// consulter — et aucun écran ne les affichait. Elles n'étaient
// chargées que dans l'espace professionnel.
//
// Deux choses se testent ici. Ce que l'écran affiche, qui est du
// calcul pur. Et le contenu du script SQL, par lecture de source :
// cette fonction contourne le RLS, un seul garde-fou la protège, et sa
// disparition ne casserait rien de visible.

const _sql = 'supabase/schema_notes_visibles_parent.sql';

String _sourceSql() => File(_sql).readAsStringSync();

/// Le script sans son en-tête de commentaires : ce que Postgres
/// exécute vraiment.
String _corpsSql() {
  final sql = _sourceSql();

  return sql.substring(sql.indexOf('create or replace'));
}

NoteEnfantData _note({
  String? nomActivite = 'Sortie au musée',
  DateTime? dateActivite,
  String? nomEtablissement = 'École les Tilleuls',
  String? roleAuteur = 'membre',
}) {
  return NoteEnfantData(
    id: 'note-1',
    note: 'Théo s’est plaint de la chaleur en fin d’après-midi.',
    creeLe: DateTime(2026, 8, 14, 18, 30),
    nomActivite: nomActivite,
    dateActivite: dateActivite ?? DateTime(2026, 8, 14, 9),
    nomEtablissement: nomEtablissement,
    roleAuteur: roleAuteur,
  );
}

void main() {
  group('La ligne rendue par la base se relit', () {
    test('Tous les champs arrivent', () {
      final note = NoteEnfantData.fromRow({
        'id': 'note-1',
        'note': 'Sieste écourtée.',
        'cree_le': '2026-08-14T18:30:00Z',
        'nom_activite': 'Sortie au musée',
        'date_activite': '2026-08-14T09:00:00Z',
        'nom_etablissement': 'École les Tilleuls',
        'role_auteur': 'adjoint',
      });

      expect(note.id, 'note-1');
      expect(note.note, 'Sieste écourtée.');
      expect(note.nomActivite, 'Sortie au musée');
      expect(note.nomEtablissement, 'École les Tilleuls');
      expect(note.roleAuteur, 'adjoint');
      expect(note.dateActivite, isNotNull);
    });

    test('Un contexte disparu ne fait pas disparaître la note', () {
      // Établissement supprimé, activité sans nom, auteur qui n'est
      // plus membre : la note a été écrite, le parent doit la lire.
      final note = NoteEnfantData.fromRow({
        'id': 'note-1',
        'note': 'Sieste écourtée.',
        'cree_le': '2026-08-14T18:30:00Z',
        'nom_activite': null,
        'date_activite': null,
        'nom_etablissement': null,
        'role_auteur': null,
      });

      expect(note.note, 'Sieste écourtée.');
      expect(note.nomActivite, isNull);
      expect(note.dateActivite, isNull);
      expect(note.roleAuteur, isNull);
    });
  });

  group('Le parent voit une qualité, jamais une identité', () {
    // Décision du 25/08/2026 : un professionnel n'a ni nom ni prénom en
    // base — seulement une adresse email, que le parent n'a jamais eu à
    // voir ailleurs dans l'application.

    test('Les trois rôles ont chacun leur formulation', () {
      expect(
        libelleAuteurNote('directeur'),
        'Écrit par la direction de l’établissement',
      );
      expect(
        libelleAuteurNote('adjoint'),
        'Écrit par la direction adjointe',
      );
      expect(
        libelleAuteurNote('membre'),
        'Écrit par un membre de l’équipe',
      );
    });

    test('Un auteur qui n’est plus membre ne s’invente pas', () {
      expect(
        libelleAuteurNote(null),
        'Écrit par l’établissement',
      );
      expect(
        libelleAuteurNote('role_inconnu'),
        'Écrit par l’établissement',
      );
    });

    test('Aucune formulation n’accorde en genre', () {
      // Rien en base ne dit celui de l'auteur ; deviner serait pire que
      // ne rien dire.
      // Les formes que « Gérer l'équipe » emploie entre collègues —
      // « Directeur/directrice », « Adjoint(e) » — ne conviennent pas
      // ici : elles désignent une personne précise. Les nôtres
      // désignent une fonction.
      for (final role in [
        'directeur',
        'adjoint',
        'membre',
        null,
      ]) {
        final libelle = libelleAuteurNote(role);

        // « La direction adjointe » n'est pas dans cette liste, et
        // c'est délibéré : l'accord y porte sur « direction », un nom
        // féminin, pas sur la personne. Ce qu'on interdit, ce sont les
        // formes qui désignent QUELQU'UN — celles de « Gérer l'équipe »,
        // employées entre collègues qui se connaissent.
        for (final forme in [
          'directrice',
          'Adjoint(e)',
          '(e)',
          'Directeur',
          'un adjoint ',
          'une adjointe',
          'un directeur',
        ]) {
          expect(
            libelle,
            isNot(contains(forme)),
            reason: '« $libelle » accorde en genre sur « $forme »',
          );
        }
      }
    });

    test('Aucune formulation ne peut contenir une adresse email', () {
      for (final role in ['directeur', 'adjoint', 'membre', null]) {
        expect(libelleAuteurNote(role), isNot(contains('@')));
      }
    });
  });

  group('L’en-tête dit où et quand', () {
    test('Établissement, date de l’activité, puis son nom', () {
      expect(
        libelleContexteNote(_note()),
        'École les Tilleuls — 14/08/2026 · Sortie au musée',
      );
    });

    test('Une activité sans nom n’ajoute pas de séparateur vide', () {
      expect(
        libelleContexteNote(_note(nomActivite: null)),
        'École les Tilleuls — 14/08/2026',
      );
      expect(
        libelleContexteNote(_note(nomActivite: '   ')),
        'École les Tilleuls — 14/08/2026',
      );
    });

    test('Sans date d’activité, on retombe sur celle de la note', () {
      expect(
        libelleContexteNote(
          _note(dateActivite: DateTime(2026, 8, 20, 9)),
        ),
        contains('20/08/2026'),
      );
    });

    test('La date affichée est celle de l’activité, pas de la note', () {
      // Le parent cherche le jour où son enfant était là-bas, pas le
      // moment où quelqu'un s'est assis pour écrire.
      final note = NoteEnfantData(
        id: 'note-1',
        note: 'Sieste écourtée.',
        creeLe: DateTime(2026, 8, 20, 22),
        dateActivite: DateTime(2026, 8, 14, 9),
        nomEtablissement: 'École les Tilleuls',
        roleAuteur: 'membre',
      );

      expect(libelleContexteNote(note), contains('14/08/2026'));
      expect(libelleContexteNote(note), isNot(contains('20/08/2026')));
    });

    test('Un établissement supprimé garde un en-tête lisible', () {
      expect(
        libelleContexteNote(_note(nomEtablissement: null)),
        startsWith('Établissement — '),
      );
    });
  });

  group('Le script SQL garde sa porte', () {
    // `security definer` contourne le RLS : ces quelques lignes sont le
    // seul contrôle de droit de la fonction. Leur disparition ne
    // casserait rien de visible — d'où ces tests.
    //
    // Tous lisent `_corpsSql()` et non le fichier entier : l'en-tête
    // explique longuement le garde-fou, et une assertion posée sur le
    // fichier complet se satisferait du commentaire alors que la
    // requête, elle, l'aurait perdu. Vérifié en le retirant.

    test('Le contrôle du parent est dans la requête', () {
      expect(
        _corpsSql(),
        contains('public.enfant_du_parent(p_enfant_id)'),
        reason:
            'Sans ce garde-fou, tout compte authentifié lirait les '
            'notes de n’importe quel enfant',
      );
    });

    test('Seules les notes de l’enfant demandé sortent', () {
      // Porte deux choses à la fois : les notes générales au groupe
      // (enfant_id null) et celles des autres enfants de la même
      // activité.
      expect(
        _corpsSql(),
        contains('where n.enfant_id = p_enfant_id'),
      );
    });

    test('L’adresse email de l’auteur ne figure nulle part', () {
      final requete = _corpsSql();

      expect(requete, isNot(contains('m.email')));
      expect(requete, isNot(contains('email,')));
      expect(requete, contains('m.role'));
    });

    test('La fonction est fermée aux visiteurs non connectés', () {
      final sql = _sourceSql();

      expect(sql, contains('revoke all on function'));
      expect(sql, contains('from anon'));
      expect(sql, contains('grant execute on function'));
      expect(sql, contains('to authenticated'));
    });

    test('Elle est bien en security definer, et figée', () {
      final sql = _sourceSql();

      expect(sql, contains('security definer'));
      expect(sql, contains('set search_path = public'));
      expect(sql, contains('stable'));
    });
  });
}
