import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/tentative_partage_data.dart';

// La reprise d'accès et le déverrouillage par le parent (28/08/2026).
//
// Le secret du verrou vit dans le `localStorage` du navigateur qui a
// ouvert la fiche. Ce cloisonnement n'est pas le nôtre : c'est celui du
// système. Un lecteur de QR ou une messagerie qui ouvre la page dans
// son propre navigateur intégré y range le secret, et la même personne
// se présente ensuite comme une inconnue depuis Safari.
//
// Le moment où ça se voit est le pire possible : une maîtresse rouvre
// la fiche parce qu'il se passe quelque chose avec l'enfant.

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

TentativePartageData _tentative({
  required bool toleree,
  bool reprise = false,
}) {
  return TentativePartageData(
    id: 't1',
    partageId: 'p1',
    tenteeLe: DateTime(2026, 8, 28, 14),
    toleree: toleree,
    reprise: reprise,
  );
}

void main() {
  group('Ce que le parent lit', () {
    test('Un refus prime sur tout le reste', () {
      // C'est lui qui demande une décision.
      final libelle = libelleTentatives([
        _tentative(toleree: false),
        _tentative(toleree: true, reprise: true),
      ]);

      expect(libelle, contains('refusée'));
    });

    test('Une reprise se distingue d’une tolérance silencieuse', () {
      // Le parent ne lit pas la même chose selon qu'un lien a été
      // rouvert tout seul dans le quart d'heure ou que quelqu'un a
      // repris la main des heures après.
      final reprise = libelleTentatives([
        _tentative(toleree: true, reprise: true),
      ]);

      final tolerance = libelleTentatives([
        _tentative(toleree: true),
      ]);

      expect(reprise, contains('repris l’accès'));
      expect(reprise, contains('c’était bien lui'));

      expect(tolerance, contains('peu après'));
      expect(tolerance, isNot(contains('repris')));
    });

    test('Plusieurs reprises se comptent', () {
      final libelle = libelleTentatives([
        _tentative(toleree: true, reprise: true),
        _tentative(toleree: true, reprise: true),
      ]);

      expect(libelle, contains('2 reprises'));
    });

    test('Une ligne d’avant le 28/08/2026 se relit sans reprise', () {
      final ancienne = TentativePartageData.fromRow({
        'id': 't1',
        'partage_id': 'p1',
        'tentee_le': '2026-08-25T10:00:00.000Z',
        'toleree': true,
      });

      expect(ancienne.reprise, isFalse);
    });
  });

  group('Le déverrouillage par le parent, réparé', () {
    final service = _codeSansCommentaires('lib/sharing/share_link_service.dart');

    test('Il agit sur les places, pas sur les colonnes mortes', () {
      // Jusqu'au 28/08/2026 il remettait à zéro `verrou_empreinte` et
      // `verrou_pose_le`, que plus personne ne lit depuis que la
      // décision se prend sur `appareils_partage`. Le bouton ne
      // faisait rien, et disait pourtant le contraire à l'écran.
      expect(service, contains("'liberer_place_partage'"));
      expect(service, isNot(contains("'verrou_empreinte'")));
      expect(service, isNot(contains("'verrou_pose_le'")));
    });

    test('Le bouton existe toujours dans la liste du parent', () {
      final ecran =
          _codeSansCommentaires('lib/children/child_profile_page.dart');

      expect(ecran, contains('Autoriser ce nouvel appareil'));
      expect(ecran, contains('_libererVerrou('));
    });

    test('Une seule place, pas toutes', () {
      // Libérer tout évincerait des lecteurs légitimes que le parent
      // n'a pas visés.
      final sql = _source('supabase/schema_reprise_acces.sql');

      expect(sql, contains('order by a.pris_le desc'));
      expect(sql, contains('limit 1'));
      expect(sql, contains('delete from public.appareils_partage where id'));
    });

    test('Seul le parent de l’enfant peut libérer', () {
      final sql = _source('supabase/schema_reprise_acces.sql');

      expect(sql, contains('enfant_du_parent(v_enfant)'));
    });
  });

  group('La reprise, côté serveur', () {
    final verrou = _codeSansCommentaires(
      'supabase/functions/_logique/verrou_partage.mts',
    );

    final consultation = _codeSansCommentaires(
      'supabase/functions/_logique/partage_consultation.mts',
    );

    test('Elle ne prend la place que du refus', () {
      // Les trois règles d'origine passent avant, dans leur ordre :
      // même appareil, fenêtre de tolérance, place libre.
      final regle4 = verrou.indexOf('repriseDemandee && derniere');
      final placeLibre = verrou.indexOf('places.length < appareilsMax');
      final refus = verrou.lastIndexOf("action: 'refuser'");

      expect(placeLibre, lessThan(regle4));
      expect(regle4, lessThan(refus));
    });

    test('Elle est demandée, jamais déduite', () {
      // Sans geste explicite, un simple rechargement prendrait la
      // place de quelqu'un d'autre.
      final fonction = _source(
        'supabase/functions/consulter-partage/index.ts',
      );

      expect(fonction, contains("parametres.get('reprise') === '1'"));
    });

    test('Elle remplace la place, elle n’en consomme pas une autre', () {
      expect(verrou, contains("action: 'remplacer', placeId: derniere.id"));
    });

    test('Le parent est prévenu', () {
      // C'est elle qui rend la reprise acceptable : sans notification,
      // ce serait un affaiblissement muet.
      expect(consultation, contains('notifierRepriseAcces('));
      expect(consultation, contains('if (decision.reprise) {'));
    });

    test('Aucun compteur, aucun délai imposé', () {
      // Décision de Fanny : « la notification et la révocation
      // suffisent ». Un verrou de plus se retournerait contre la
      // personne au pire moment.
      expect(verrou, isNot(contains('maxReprises')));
      expect(verrou, isNot(contains('delaiEntreReprises')));
      expect(consultation, isNot(contains('nombreDeReprises')));
    });

    test('Le type d’événement est déclaré en base', () {
      final sql = _source('supabase/schema_reprise_acces.sql');

      expect(sql, contains("'acces_repris'"));
    });
  });

  mainEnvoiImmediat();

  group('Ce que voit la personne refusée', () {
    final page = _source('supabase/functions/_logique/page_partage.mts');

    test('L’écran propose de reprendre plutôt que de renvoyer chez le parent',
        () {
      expect(page, contains('C’est moi, reprendre l’accès'));
      expect(
        page,
        contains('Cette fiche a déjà été ouverte sur un autre appareil'),
      );
    });

    test('Il annonce que le parent sera informé', () {
      expect(page, contains('Le parent en sera informé immédiatement'));
    });

    test('Il dit aussi quoi faire quand ce n’est pas vous', () {
      expect(page, contains('Si ce n’est pas vous, n’appuyez pas.'));
    });

    test('La phrase à ne jamais retirer est toujours là', () {
      // Protégée par Fanny le 27/08/2026 : c'est elle qui évite
      // l'appel au parent pour un renvoi inutile, et tout le
      // mécanisme de demande d'accès en dépend.
      expect(
        page,
        contains('un nouveau lien ne changerait rien'),
      );
    });

    test('Le bouton rejoue la même demande, avec un drapeau', () {
      // Une seule chaîne de traitement pour les deux cas, donc un seul
      // endroit où elle peut se tromper.
      expect(page, contains('function ouvrirFiche(reprise)'));
      expect(page, contains("urlFonction += '&reprise=1'"));
      expect(page, contains('ouvrirFiche(true)'));
      expect(page, contains('ouvrirFiche(false)'));
    });

    test('Le bouton redevient utilisable si la reprise échoue', () {
      expect(page, contains('boutonReprise.disabled = false'));
    });
  });
}

// L'envoi immédiat des notifications (28/08/2026).
//
// Le filet chez OVH ne passe qu'une fois par heure — limite de
// l'hébergement mutualisé, pas un choix, vérifiée avant que Fanny y
// passe du temps. Dire à un parent que son enfant part avec les
// pompiers cinquante minutes plus tard n'est pas acceptable : le
// canal normal est l'envoi immédiat, le filet ne fait que rattraper.

void mainEnvoiImmediat() {
  group('L’accès secours prévient le parent tout de suite', () {
    test('Le chemin du lien envoie derrière sa réponse', () {
      // La personne qui déclenche attend son code à l'écran. Elle ne
      // doit pas patienter pendant qu'un email part.
      final fonction = _source(
        'supabase/functions/declencher-acces-secours/index.ts',
      );

      expect(fonction, contains('envoyerNotificationsEnFond()'));

      final immediat = _source(
        'supabase/functions/_enveloppe/envoi_immediat.mts',
      );

      expect(immediat, contains('EdgeRuntime.waitUntil'));
    });

    test('Il n’envoie que sur un accès réellement créé', () {
      // Sur une reprise, le parent a déjà été prévenu de celui-là.
      final fonction = _codeSansCommentaires(
        'supabase/functions/declencher-acces-secours/index.ts',
      );

      expect(fonction, contains('if (resultat.acces.creeMaintenant)'));
    });

    test('Le chemin de l’application appelle la fonction dédiée', () {
      // Là, la ligne est écrite par la base dans la même transaction
      // que l'accès : aucune fonction serveur n'est en position
      // d'envoyer, il faut que l'application le demande.
      final service =
          _codeSansCommentaires('lib/secours/service_acces_secours.dart');

      expect(service, contains("'envoyer-notifications-maintenant'"));
      expect(service, contains('if (ouvert.creeMaintenant)'));
    });

    test('L’appel n’attend pas et ne fait jamais échouer le geste', () {
      // L'accès est ouvert, le professionnel a son code : c'est une
      // urgence, elle passe avant la notification.
      final service =
          _codeSansCommentaires('lib/secours/service_acces_secours.dart');

      expect(service, contains('unawaited('));
      expect(service, contains('onError:'));
    });
  });

  group('Les deux fonctions d’envoi ne se protègent pas pareil', () {
    test('Le filet se protège par une clé partagée', () {
      final filet = _source(
        'supabase/functions/envoyer-notifications-parent/index.ts',
      );

      expect(filet, contains("'x-cle-planificateur'"));
      expect(filet, contains('CLE_PLANIFICATEUR'));
    });

    test('Celle de l’application se protège par le compte connecté', () {
      // Une application installée ne peut pas garder de clé : ce qui
      // est dans l'application est public.
      final maintenant = _source(
        'supabase/functions/envoyer-notifications-maintenant/index.ts',
      );

      expect(maintenant, contains('enTeteAutorisation(requete)'));
      expect(maintenant, isNot(contains('CLE_PLANIFICATEUR')));
    });

    test('Aucune des deux ne rend de donnée', () {
      // Des compteurs, et rien d'autre : ni prénom, ni adresse.
      for (final chemin in [
        'supabase/functions/envoyer-notifications-parent/index.ts',
        'supabase/functions/envoyer-notifications-maintenant/index.ts',
      ]) {
        expect(_source(chemin), contains('reponseJson(bilan, 200)'));
      }
    });
  });

  group('La tâche planifiée chez OVH', () {
    test('La vraie clé n’entre pas dans git', () {
      final ignore = _source('.gitignore');

      expect(
        ignore,
        contains('hebergement_ovh/tache_notifications.php'),
      );

      final exemple =
          _source('hebergement_ovh/tache_notifications.php.exemple');

      expect(exemple, contains('REMPLACER_PAR_LA_CLE_PLANIFICATEUR'));
    });

    test('Le journal ne grossit pas et ne dit rien de personnel', () {
      // Un fichier qui grossit sans fin sur un mutualisé finit par
      // poser problème, et la fonction ne rend que des compteurs.
      final exemple =
          _source('hebergement_ovh/tache_notifications.php.exemple');

      expect(exemple, contains('file_put_contents'));
      expect(exemple, isNot(contains('FILE_APPEND')));
    });
  });
}
