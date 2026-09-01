import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/demande_acces_data.dart';

// Trois appareils, et le parent décide au-delà (01/09/2026).
//
// Le parent choisissait 1, 2 ou 5 « personnes ». Or le mécanisme ne
// compte pas des personnes : il compte des navigateurs. Un seul
// téléphone en fournit déjà deux — la fenêtre intégrée du lecteur de
// QR, puis Safari quand la personne rouvre plus tard.
//
// Ces valeurs et ce libellé venaient de moi, proposés le 27/08 et
// validés en une ligne. L'écart entre « personnes » et « navigateurs »
// avait été constaté le jour même et documenté au lieu d'être corrigé.

String _source(String chemin) => File(chemin).readAsStringSync();

String _codeSansCommentaires(String chemin) {
  return _source(chemin)
      .split('\n')
      .where((ligne) {
        final nu = ligne.trimLeft();
        return !nu.startsWith('//') && !nu.startsWith('///');
      })
      .join('\n');
}

DemandeAccesData _demande({
  String id = 'd1',
  String partageId = 'p1',
  String raison = 'Mamie Denise',
  DateTime? autoriseeLe,
}) {
  return DemandeAccesData(
    id: id,
    partageId: partageId,
    raison: raison,
    creeLe: DateTime(2026, 9, 1, 10),
    autoriseeLe: autoriseeLe,
  );
}

void main() {
  group('Le sélecteur d’appareils a disparu', () {
    final ecran =
        _codeSansCommentaires('lib/sharing/create_share_link_page.dart');

    test('Plus aucun choix de 1, 2 ou 5', () {
      expect(ecran, isNot(contains('_NombreAppareils')));
      expect(ecran, isNot(contains('Jusqu’à 2 personnes')));
      expect(ecran, isNot(contains('Jusqu’à 5 personnes')));
    });

    test('La question posée en personnes a disparu avec lui', () {
      // C'était la racine du défaut : la question parlait de
      // personnes, le mécanisme comptait des navigateurs.
      expect(
        ecran,
        isNot(contains('Combien de personnes doivent pouvoir')),
      );
      expect(ecran, isNot(contains('Chaque appareil compte')));
    });

    test('L’écran dit quand même ce qui va se passer', () {
      // Ce n'est plus un réglage, c'est une information : le parent
      // doit savoir combien d'appareils son partage accepte, et ce
      // qui arrive au-delà.
      expect(ecran, contains('Trois appareils pourront ouvrir'));
      expect(ecran, contains('devra vous demander l’autorisation'));
    });

    test('Le service ne fixe plus le plafond, la base s’en charge', () {
      final service =
          _codeSansCommentaires('lib/sharing/share_link_service.dart');

      expect(service, isNot(contains("'appareils_max'")));
    });
  });

  group('Ce que le parent lit sur une demande', () {
    test('Une seule demande se dit au singulier', () {
      expect(
        libelleDemandes([_demande()]),
        'Un appareil de plus demande à ouvrir cette fiche.',
      );
    });

    test('Plusieurs se comptent', () {
      expect(
        libelleDemandes([_demande(), _demande(id: 'd2')]),
        contains('2 appareils de plus'),
      );
    });

    test('Une demande déjà autorisée ne compte plus', () {
      final libelle = libelleDemandes([
        _demande(autoriseeLe: DateTime(2026, 9, 1, 11)),
      ]);

      expect(libelle, isNull);
    });

    test('Aucune demande ne produit aucune ligne', () {
      // Une carte sans demande ne doit pas porter de ligne vide.
      expect(libelleDemandes([]), isNull);
    });

    test('Une ligne sans réponse est en attente', () {
      expect(_demande().estEnAttente, isTrue);
      expect(
        _demande(autoriseeLe: DateTime(2026, 9, 1)).estEnAttente,
        isFalse,
      );
    });

    test('La ligne se relit depuis la base', () {
      final lue = DemandeAccesData.fromRow({
        'id': 'd1',
        'partage_id': 'p1',
        'raison': 'Mamie Denise',
        'cree_le': '2026-09-01T08:00:00.000Z',
        'autorisee_le': null,
      });

      expect(lue.raison, 'Mamie Denise');
      expect(lue.estEnAttente, isTrue);
    });
  });

  group('L’écran du parent', () {
    final ecran =
        _codeSansCommentaires('lib/children/child_profile_page.dart');

    test('La raison saisie s’affiche, et seulement ici', () {
      expect(ecran, contains('demande.raison'));
      expect(ecran, contains('_bandeauDemandes(context, link)'));
    });

    test('Un seul bouton, et pas de « ne plus me demander »', () {
      // L'application ne sait pas distinguer les appareils d'une
      // personne de ceux de plusieurs, et cette option ouvrirait
      // exactement la porte qu'on cherche à fermer.
      expect(ecran, contains('Autoriser cet appareil'));

      for (final interdit in [
        'ne plus me demander',
        'Ne plus me demander',
        'Autoriser tous les appareils',
        'Toujours autoriser',
      ]) {
        expect(ecran, isNot(contains(interdit)));
      }
    });

    test('Il dit que le silence ne vaut pas accord', () {
      expect(ecran, contains('l’accès reste fermé'));
      expect(ecran, contains('30'));
    });
  });

  group('Ce que le serveur garantit', () {
    final sql = _source('supabase/schema_trois_appareils.sql')
        .split('\n')
        .where((ligne) => !ligne.trimLeft().startsWith('--'))
        .join('\n');

    final verrou = _codeSansCommentaires(
      'supabase/functions/_logique/verrou_partage.mts',
    );

    test('Trois par défaut, en base', () {
      expect(sql, contains('alter column appareils_max set default 3'));
    });

    test('Les partages existants ont été migrés', () {
      expect(sql, contains('set appareils_max = 3'));
    });

    test('Une place ne compte qu’au retour', () {
      expect(sql, contains('add column if not exists confirme boolean'));
      expect(verrou, contains('places.filter((place) => place.confirme)'));
    });

    test('Le quatrième appareil demande, il n’est pas refusé', () {
      expect(verrou, contains("action: 'demander'"));
      expect(verrou, isNot(contains("action: 'refuser'")));
    });

    test('La fenêtre de tolérance a disparu', () {
      // Elle laissait un inconnu remplacer la place la plus récente,
      // donc voler celle de quelqu'un.
      expect(verrou, isNot(contains('TOLERANCE_MINUTES')));
      expect(verrou, isNot(contains('toleranceMinutes')));
      expect(verrou, isNot(contains("action: 'remplacer'")));
    });

    test('La reprise explicite a disparu aussi', () {
      expect(verrou, isNot(contains('repriseDemandee')));

      final page = _source('supabase/functions/_logique/page_partage.mts');

      expect(page, isNot(contains('reprendre-acces')));
    });

    test('Trois demandes en attente au maximum', () {
      final consultation = _codeSansCommentaires(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(consultation, contains('MAX_DEMANDES_EN_ATTENTE = 3'));
    });

    test('Une demande sans réponse s’efface au bout de 30 jours', () {
      // Le silence du parent ne vaut ni refus ni acceptation.
      expect(sql, contains("interval '30 days'"));
      expect(sql, contains('autorisee_le is null'));
    });

    test('La raison est bornée à 60 caractères des deux côtés', () {
      expect(sql, contains('between 1 and 60'));

      final page = _source('supabase/functions/_logique/page_partage.mts');

      expect(page, contains('maxlength="60"'));
    });

    test('Seul le parent de l’enfant peut autoriser', () {
      expect(sql, contains('enfant_du_parent(v_enfant)'));
    });

    test('Autoriser monte le plafond d’une seule unité', () {
      expect(sql, contains('least(appareils_max + 1, 50)'));
    });
  });

  mainPurge();

  group('L’accès secours ne bloque jamais', () {
    test('Il ne passe plus par la décision du verrou', () {
      // Décision de Fanny : on ne bloque pas ce qui peut sauver
      // l'enfant, on bloque ce qui peut attendre.
      final secours = _codeSansCommentaires(
        'supabase/functions/_logique/acces_secours.mts',
      );

      expect(secours, isNot(contains('decisionVerrou')));
      expect(secours, contains('places.some((place)'));
    });

    test('Une place non confirmée suffit à le déclencher', () {
      // Quelqu'un qui a ouvert la fiche une seule fois détient bien
      // le lien, et c'est tout ce qu'on lui demande.
      final secours =
          _source('supabase/functions/_logique/acces_secours.mts');

      expect(secours, contains('place non confirmée compte ici'));
    });

    test('Son plafond de dix reste intact', () {
      final sql = _source('supabase/schema_trois_appareils.sql');

      expect(sql, contains('declenche_en_secours = true'));
      expect(sql, contains('appareils_max >= 1 and appareils_max <= 50'));
    });
  });
}

// Le ménage des demandes sans réponse (01/09/2026).
//
// La fonction existait en base et **personne ne l'appelait**. Une
// purge que rien ne déclenche, c'est une règle qui n'existe pas —
// exactement le mode d'échec traqué toute la semaine, cette fois dans
// mon propre travail.
void mainPurge() {
  group('Les demandes sans réponse sont bien effacées', () {
    test('Le passage horaire appelle la purge', () {
      final fonction = _source(
        'supabase/functions/envoyer-notifications-parent/index.ts',
      );

      expect(fonction, contains("'purger_demandes_acces_partage'"));
    });

    test('Un échec de ménage ne remet pas les envois en cause', () {
      // Ils sont déjà faits, et le passage suivant reprendra.
      final fonction = _source(
        'supabase/functions/envoyer-notifications-parent/index.ts',
      );

      expect(fonction, contains('erreurPurge'));
      expect(fonction, contains('console.error(erreurPurge)'));
    });

    test('Seul le rôle de service peut la déclencher', () {
      // Ce n'est pas un geste d'utilisateur.
      final sql = _source('supabase/schema_trois_appareils.sql');

      expect(sql, contains('to service_role'));
      expect(
        sql,
        contains('purger_demandes_acces_partage()\n  from authenticated'),
      );
    });
  });
}
