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
// Puis un second défaut, trouvé en vérifiant : la seule identité
// disponible était `role`, qui décrit qui administre l'équipe et non
// qui a écrit. Une maîtresse, la cantine et le périscolaire sont tous
// `membre`. La fonction déclarée l'a remplacée.
//
// Deux choses se testent ici. Ce que l'écran affiche, qui est du
// calcul pur. Et le contenu des scripts SQL, par lecture de source :
// ces fonctions contournent le RLS, un seul garde-fou les protège, et
// sa disparition ne casserait rien de visible.

const _sqlNotes = 'supabase/schema_notes_visibles_parent.sql';
const _sqlFonction = 'supabase/schema_fonction_professionnelle.sql';

String _lire(String chemin) => File(chemin).readAsStringSync();

/// Un script débarrassé de tous ses commentaires : ce que Postgres
/// exécute vraiment, et rien d'autre.
///
/// Toutes les assertions ci-dessous lisent ceci et non le fichier
/// entier. Ces scripts s'expliquent longuement, garde-fous compris :
/// une assertion posée sur le texte complet se satisferait du
/// commentaire alors que la requête, elle, l'aurait perdu. Vérifié
/// deux fois plutôt qu'une — la première version ne coupait que
/// l'en-tête, et un commentaire du milieu citant `role_auteur` a fait
/// tomber un test à raison.
String _corps(String chemin) {
  return _lire(chemin)
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('--'))
      .join('\n');
}

NoteEnfantData _note({
  String? nomActivite = 'Sortie au musée',
  DateTime? dateActivite,
  String? nomEtablissement = 'École les Tilleuls',
  String? fonctionAuteur = 'Enseignant·e',
}) {
  return NoteEnfantData(
    id: 'note-1',
    note: 'Théo s’est plaint de la chaleur en fin d’après-midi.',
    creeLe: DateTime(2026, 8, 14, 18, 30),
    nomActivite: nomActivite,
    dateActivite: dateActivite ?? DateTime(2026, 8, 14, 9),
    nomEtablissement: nomEtablissement,
    fonctionAuteur: fonctionAuteur,
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
        'fonction_auteur': 'ATSEM',
      });

      expect(note.id, 'note-1');
      expect(note.note, 'Sieste écourtée.');
      expect(note.nomActivite, 'Sortie au musée');
      expect(note.nomEtablissement, 'École les Tilleuls');
      expect(note.fonctionAuteur, 'ATSEM');
      expect(note.dateActivite, isNotNull);
    });

    test('Un contexte disparu ne fait pas disparaître la note', () {
      // Établissement supprimé, activité sans nom, auteur qui n'a
      // jamais déclaré sa fonction : la note a été écrite, le parent
      // doit la lire.
      final note = NoteEnfantData.fromRow({
        'id': 'note-1',
        'note': 'Sieste écourtée.',
        'cree_le': '2026-08-14T18:30:00Z',
        'nom_activite': null,
        'date_activite': null,
        'nom_etablissement': null,
        'fonction_auteur': null,
      });

      expect(note.note, 'Sieste écourtée.');
      expect(note.nomActivite, isNull);
      expect(note.dateActivite, isNull);
      expect(note.fonctionAuteur, isNull);
    });
  });

  group('Le parent lit une fonction, jamais une identité', () {
    test('La fonction est recopiée telle quelle', () {
      // Vérifié dans le code le 25/08/2026 : `role` ne décrit que qui
      // administre l'équipe. Une maîtresse, la cantine et le
      // périscolaire sont tous « membre ».
      expect(
        libelleAuteurNote('Enseignant·e'),
        'Écrit par : Enseignant·e',
      );
      expect(
        libelleAuteurNote('Restauration'),
        'Écrit par : Restauration',
      );
      expect(
        libelleAuteurNote('Santé scolaire (infirmerie)'),
        'Écrit par : Santé scolaire (infirmerie)',
      );
    });

    test('Une fonction écrite sous « Autre » passe intacte', () {
      expect(
        libelleAuteurNote('Chauffeur du car de ramassage'),
        'Écrit par : Chauffeur du car de ramassage',
      );
    });

    test('L’application n’ajoute aucun accord', () {
      // La personne a écrit ce qu'elle est. Ajouter « une », « (e) »
      // ou un féminin de circonstance rendrait la ligne fausse pour
      // quelqu'un.
      for (final fonction in [
        'Enseignant·e',
        'Direction',
        'Animation',
        'AESH / AVS',
      ]) {
        final libelle = libelleAuteurNote(fonction);

        expect(libelle, 'Écrit par : $fonction');
        expect(libelle, isNot(contains('(e)')));
        expect(libelle, isNot(contains('une ')));
      }
    });

    test('Rien de déclaré ne s’invente pas', () {
      // Ne concerne que les notes antérieures au 25/08/2026 : une note
      // nouvelle est impossible tant que la fonction manque.
      expect(libelleAuteurNote(null), 'Fonction non précisée');
      expect(libelleAuteurNote(''), 'Fonction non précisée');
      expect(libelleAuteurNote('   '), 'Fonction non précisée');
    });

    test('Aucun rôle administratif ne peut ressortir', () {
      // `directeur` / `adjoint` / `membre` ne veulent rien dire pour un
      // parent — c'est tout l'objet de la correction.
      for (final fonction in [null, '', 'Direction']) {
        final libelle = libelleAuteurNote(fonction);

        expect(libelle, isNot(contains('adjoint')));
        expect(libelle, isNot(contains('directeur')));
        expect(libelle, isNot(contains('membre de l’équipe')));
      }
    });

    test('Aucune formulation ne peut contenir une adresse email', () {
      for (final fonction in [null, 'Direction', 'ATSEM']) {
        expect(libelleAuteurNote(fonction), isNot(contains('@')));
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

    test('La date affichée est celle de l’activité, pas de la note', () {
      // Le parent cherche le jour où son enfant était là-bas, pas le
      // moment où quelqu'un s'est assis pour écrire.
      final note = NoteEnfantData(
        id: 'note-1',
        note: 'Sieste écourtée.',
        creeLe: DateTime(2026, 8, 20, 22),
        dateActivite: DateTime(2026, 8, 14, 9),
        nomEtablissement: 'École les Tilleuls',
        fonctionAuteur: 'ATSEM',
      );

      expect(libelleContexteNote(note), contains('14/08/2026'));
      expect(libelleContexteNote(note), isNot(contains('20/08/2026')));
    });

    test('Sans date d’activité, on retombe sur celle de la note', () {
      // Cas réel : la note du 18/08/2026 en production porte une
      // activité sans date.
      final note = NoteEnfantData(
        id: 'note-1',
        note: 'Sieste écourtée.',
        creeLe: DateTime(2026, 8, 18, 19),
        nomEtablissement: 'École les Tilleuls',
      );

      expect(libelleContexteNote(note), contains('18/08/2026'));
    });

    test('Un établissement supprimé garde un en-tête lisible', () {
      expect(
        libelleContexteNote(_note(nomEtablissement: null)),
        startsWith('Établissement — '),
      );
    });
  });

  group('Le script des notes garde sa porte', () {
    test('Le contrôle du parent est dans la requête', () {
      expect(
        _corps(_sqlNotes),
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
        _corps(_sqlNotes),
        contains('where n.enfant_id = p_enfant_id'),
      );
    });

    test('L’adresse email de l’auteur ne figure nulle part', () {
      expect(_corps(_sqlNotes), isNot(contains('m.email')));
    });

    test('La fonction est fermée aux visiteurs non connectés', () {
      final sql = _lire(_sqlNotes);

      expect(sql, contains('revoke all on function'));
      expect(sql, contains('from anon'));
      expect(sql, contains('to authenticated'));
    });
  });

  group('Le script de la fonction garde les siennes', () {
    test('Le même garde-fou survit à la reprise de la requête', () {
      // Ce script laisse tomber `notes_enfant_pour_parent` et la
      // recrée : le contrôle de droit doit être recopié, sinon il
      // disparaît sans bruit.
      expect(
        _corps(_sqlFonction),
        contains('public.enfant_du_parent(p_enfant_id)'),
      );
      expect(
        _corps(_sqlFonction),
        contains('where n.enfant_id = p_enfant_id'),
      );
    });

    test('Le rôle administratif ne sort plus, la fonction le remplace',
        () {
      final corps = _corps(_sqlFonction);

      expect(corps, contains('fonction_auteur text'));
      expect(corps, contains('select m.fonction'));
      expect(corps, isNot(contains('role_auteur')));
      expect(corps, isNot(contains('select m.role')));
    });

    test('L’adresse email n’est pas revenue au passage', () {
      expect(_corps(_sqlFonction), isNot(contains('m.email')));
    });

    test('Chacun ne peut déclarer que sa propre fonction', () {
      // `membres_etablissement` n'a aucune policy d'écriture directe :
      // ce `where` est le seul garde-fou de la mise à jour.
      final corps = _corps(_sqlFonction);

      expect(corps, contains('and user_id = auth.uid()'));
      expect(corps, contains("and statut = 'actif'"));
    });

    test('La longueur est bornée aux deux entrées', () {
      // Une fonction qui déborde sur un téléphone n'informe plus. Le
      // contrôle est en base et pas seulement à l'écran, parce que la
      // fonction rentre aussi par la création d'établissement.
      final corps = _corps(_sqlFonction);

      expect(
        'depasser 60 caracteres'.allMatches(corps).length,
        2,
        reason:
            'rpc_definir_ma_fonction et rpc_creer_etablissement doivent '
            'borner la longueur toutes les deux',
      );
    });

    test('Les deux rpc sont fermées aux non-connectés', () {
      final sql = _lire(_sqlFonction);

      expect(
        sql,
        contains('rpc_definir_ma_fonction(uuid, text) from anon'),
      );
      expect(sql, contains('rpc_creer_etablissement(text, text, text)'));
    });

    test('L’ancienne signature est retirée avant d’être recréée', () {
      // Ajouter un paramètre ne remplace pas la fonction : il en crée
      // une seconde, et un appel à deux arguments devient ambigu.
      final sql = _lire(_sqlFonction);

      expect(
        sql,
        contains(
          'drop function if exists public.rpc_creer_etablissement(text, text);',
        ),
      );
      expect(
        sql,
        contains(
          'drop function if exists public.notes_enfant_pour_parent(uuid);',
        ),
      );
    });
  });
}
