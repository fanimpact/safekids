import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/share_link_data.dart';
import 'package:kidsrelay/models/tentative_partage_data.dart';

// La révocation sans effacement (27/08/2026).
//
// Avant : révoquer faisait un `delete` sur la ligne. L'accès était bien
// coupé, mais le parent perdait l'historique de ce qu'il avait partagé,
// et il ne restait aucune preuve que la révocation avait eu lieu.
//
// Désormais la ligne reste et porte `revoque_le`. Ce fichier teste ce
// qui décide de l'affichage — actif ou terminé — et vérifie par lecture
// de source que le service ne supprime plus.

ShareLinkData _lien({
  DateTime? dateExpiration,
  bool permanent = false,
  DateTime? revoqueLe,
  String? nomDestinataire,
  DateTime? dateDerniereConsultation,
}) {
  return ShareLinkData(
    id: 'partage-1',
    token: 'jeton',
    enfantId: 'enfant-1',
    ficheType: ShareFicheType.secours,
    destinataire: ShareDestinataire.particulier,
    dateCreation: DateTime(2026, 8, 20),
    dateExpiration: dateExpiration,
    dateDerniereConsultation: dateDerniereConsultation,
    nomDestinataire: nomDestinataire,
    permanent: permanent,
    revoqueLe: revoqueLe,
  );
}

/// Le code d'un fichier Dart, sans ses commentaires.
///
/// Une assertion « cette phrase a disparu » posee sur le fichier
/// entier se heurte au commentaire qui explique le retrait, et cite
/// donc la phrase retiree. Deja rencontre le 26/08/2026 sur les
/// scripts SQL : meme piege, meme parade.
String _codeSansCommentaires(String chemin) {
  return File(chemin)
      .readAsStringSync()
      .split('\n')
      .where((ligne) => !ligne.trimLeft().startsWith('//'))
      .join('\n');
}

DateTime get _demain => DateTime.now().add(const Duration(days: 1));
DateTime get _hier => DateTime.now().subtract(const Duration(days: 1));

void main() {
  group('Actif, révoqué, expiré', () {
    test('Un lien à échéance future est actif', () {
      final lien = _lien(dateExpiration: _demain);

      expect(lien.estActif, isTrue);
      expect(lien.estExpire, isFalse);
      expect(lien.estRevoque, isFalse);
    });

    test('Un lien dont l’échéance est passée n’est plus actif', () {
      expect(_lien(dateExpiration: _hier).estActif, isFalse);
    });

    test('Un lien révoqué n’est plus actif, même avant l’échéance', () {
      // C'est tout l'objet du chantier : la ligne survit, l'accès non.
      final lien = _lien(
        dateExpiration: _demain,
        revoqueLe: DateTime(2026, 8, 26),
      );

      expect(lien.estRevoque, isTrue);
      expect(lien.estActif, isFalse);
    });

    test('Un lien permanent n’expire jamais', () {
      final lien = _lien(permanent: true);

      expect(lien.estExpire, isFalse);
      expect(lien.estActif, isTrue);
    });

    test('Un lien permanent révoqué n’est plus actif', () {
      // Seule la révocation peut arrêter un lien sans date de fin.
      final lien = _lien(
        permanent: true,
        revoqueLe: DateTime(2026, 8, 26),
      );

      expect(lien.estActif, isFalse);
    });

    test('Sans date et sans être permanent, le lien n’expire pas seul', () {
      // La contrainte en base l'interdit. Le modèle ne doit pas planter
      // pour autant : `estExpire` répond faux, et c'est le serveur qui
      // refusera l'ouverture.
      final lien = _lien();

      expect(lien.estExpire, isFalse);
      expect(lien.estActif, isTrue);
    });
  });

  group('La ligne rendue par la base se relit', () {
    test('Les colonnes nouvelles arrivent', () {
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': '2026-09-20T10:00:00Z',
        'date_derniere_consultation': null,
        'nom_destinataire': 'Aurélie, animatrice piscine',
        'permanent': false,
        'revoque_le': '2026-08-26T09:00:00Z',
      });

      expect(lien.nomDestinataire, 'Aurélie, animatrice piscine');
      expect(lien.permanent, isFalse);
      expect(lien.revoqueLe, isNotNull);
      expect(lien.estRevoque, isTrue);
    });

    test('Un lien permanent se relit sans date d’expiration', () {
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': null,
        'date_derniere_consultation': null,
        'nom_destinataire': null,
        'permanent': true,
        'revoque_le': null,
      });

      expect(lien.dateExpiration, isNull);
      expect(lien.permanent, isTrue);
      expect(lien.estActif, isTrue);
    });

    test('Une ligne d’avant la refonte se relit encore', () {
      // Les colonnes ajoutées le 27/08/2026 peuvent manquer d'une
      // réponse construite ailleurs : rien ne doit planter.
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-20T10:00:00Z',
        'date_expiration': '2026-09-20T10:00:00Z',
        'date_derniere_consultation': null,
      });

      expect(lien.nomDestinataire, isNull);
      expect(lien.permanent, isFalse);
      expect(lien.revoqueLe, isNull);
      expect(lien.estActif, isTrue);
    });
  });

  group('Le service ne supprime plus', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('revokeLink marque au lieu d’effacer', () {
      final code = source('lib/sharing/share_link_service.dart');
      final debut = code.indexOf('Future<void> revokeLink');
      final fin = code.indexOf('Future<String> createLink');
      final methode = code.substring(debut, fin);

      expect(methode, contains("update({'revoque_le'"));
      expect(
        methode,
        isNot(contains('.delete()')),
        reason:
            'Le delete emportait l’historique du parent et la preuve '
            'que la révocation avait eu lieu',
      );
    });

    test('L’écran sépare les actifs des terminés', () {
      final code = source('lib/children/child_profile_page.dart');

      expect(code, contains('link.estActif'));
      expect(code, contains('Partages terminés'));
      expect(code, contains('_partageTermineCard('));
    });

    test('Un partage terminé n’offre pas de bouton de révocation', () {
      // Proposer un geste sans effet ferait douter de ce que l'écran
      // dit par ailleurs.
      final code = source('lib/children/child_profile_page.dart');
      final debut = code.indexOf('Widget _partageTermineCard(');
      final fin = code.indexOf('Widget _partageCard(');
      final methode = code.substring(debut, fin);

      expect(methode, isNot(contains('onRevoke')));
    });
  });

  group('Le serveur refuse un lien révoqué', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('La révocation est vérifiée avant l’échéance', () {
      // L'ordre compte : un lien révoqué mais non expiré doit être
      // refusé, et un lien permanent n'a pas d'échéance à comparer.
      final code = source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(code, contains("statut: 'lienRevoque'"));
      expect(
        code.indexOf('partage.revoque_le'),
        lessThan(code.indexOf('lienEncoreValide(\n      partage')),
      );
    });

    test('Un lien révoqué répond comme un lien expiré', () {
      // Dire « révoqué » apprendrait à qui détient le lien que le
      // parent a coupé l'accès volontairement. Cela ne le regarde pas.
      final code = source(
        'supabase/functions/consulter-partage/index.ts',
      );

      expect(code, contains("case 'lienRevoque':"));
      expect(code, contains('return erreur(410);'));
    });
  });

  group('Le nom du destinataire', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('Le champ est proposé à la création, et obligatoire', () {
      // Obligatoire depuis le 27/08/2026 : sans nom, la liste devient
      // une suite de lignes indistinctes, et un parent qui ne sait
      // plus a quoi correspond un lien ne le revoquera jamais.
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('À qui donnez-vous ce lien ?'));
      expect(code, contains('_nomDestinataireController'));
      expect(code, contains('Aurélie, animatrice piscine'));
      expect(
        code,
        isNot(contains('Facultatif')),
        reason: 'Le champ n’est plus facultatif depuis le 27/08/2026',
      );
    });

    test('La génération est refusée si le champ est vide', () {
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('if (nomDestinataire == null)'));
      expect(
        code,
        contains('Indiquez à qui vous donnez ce lien.'),
      );

      // Le refus doit tomber AVANT l'ecriture, jamais apres.
      expect(
        code.indexOf('if (nomDestinataire == null)'),
        lessThan(code.indexOf('createLink(')),
      );
    });

    test('La base refuse aussi, elle ne fait pas confiance à l’écran',
        () {
      final sql =
          source('supabase/schema_partages_refonte.sql');

      expect(
        sql,
        contains('alter column nom_destinataire set not null'),
      );
      expect(
        sql,
        contains('check (length(trim(nom_destinataire)) > 0)'),
        reason:
            'Un nom fait uniquement d’espaces passe « not null » sans '
            'rien nommer',
      );
    });

    test('L’écran dit que ce nom ne sort pas de l’application', () {
      // Sans cette ligne, un parent peut croire que la personne qui
      // ouvre le lien voit le nom qu'il a saisi.
      final code = source('lib/sharing/create_share_link_page.dart');

      expect(code, contains('n’apparaît'));
      expect(code, contains('la fiche partagée'));
    });

    test('Une saisie vide part en `null`, jamais en chaîne vide', () {
      // Une colonne qui contient '' se lit comme « nommé, mais sans
      // nom » : l'écran afficherait un tiret suivi de rien.
      final code = source('lib/sharing/create_share_link_page.dart');
      final debut = code.indexOf('String? _nomDestinataireSaisi()');
      final fin = code.indexOf('Future<void> _copyLink()');

      expect(
        code.substring(debut, fin),
        contains('saisie.isEmpty ? null : saisie'),
      );
    });

    test('Le service l’écrit dans sa propre colonne', () {
      // Jamais dans `destinataire`, qui porte le choix particulier /
      // structure d'accueil et gouverne la mention accolée aux
      // traitements.
      final code = source('lib/sharing/share_link_service.dart');

      expect(code, contains("'nom_destinataire': nomDestinataire,"));
      expect(code, contains("'destinataire': destinataire,"));
    });

    test('Il passe en tête de carte, le type de fiche en second', () {
      expect(
        _lien(
          dateExpiration: _demain,
          nomDestinataire: 'Aurélie, animatrice piscine',
        ).nomDestinataire,
        'Aurélie, animatrice piscine',
      );

      final code = source('lib/children/child_profile_page.dart');
      final debut = code.indexOf('String _shareLinkTitle(');
      final fin = code.indexOf('String _shareLinkStatusLabel(');

      expect(
        code.substring(debut, fin),
        contains('link.ficheType.label'),
        reason: 'Un lien sans nom reste identifiable par sa fiche',
      );
    });
  });

  group('Les durées, libérées du plafond de 7 jours', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/sharing/create_share_link_page.dart');

    test('Les cinq raccourcis sont proposés', () {
      // Chacun correspond a un usage reel cote parent, pas a une
      // commodite d'echelle : « 3 jours » couvre le week-end chez un
      // proche, qui est le cas le plus frequent. Ne pas modifier cette
      // liste sans demander a Fanny.
      for (final libelle in [
        "'24 heures'",
        "'3 jours'",
        "'7 jours'",
        "'1 mois'",
        "'1 an'",
      ]) {
        expect(
          ecran,
          contains(libelle),
          reason: '$libelle manque dans les raccourcis',
        );
      }
    });

    test('Le plafond de 7 jours a sauté', () {
      // L'echelle s'arretait a une semaine. Elle va maintenant a
      // l'annee, et au-dela avec le calendrier et le permanent.
      expect(ecran, contains("mois1('1 mois'"));
      expect(ecran, contains("an1('1 an'"));
    });

    test('« 3 jours » est protégé contre un retrait par commodité', () {
      // Retire une fois par commodite d'echelle, remis aussitot : la
      // liste repond a des usages, pas a une progression reguliere.
      expect(ecran, contains("jours3('3 jours'"));
      expect(ecran, contains('Ne pas modifier cette liste'));
    });

    test('La date libre et le permanent sont proposés', () {
      expect(ecran, contains("dateChoisie('Choisir une date'"));
      expect(ecran, contains("permanent('Sans date de fin'"));
      expect(ecran, contains('showDatePicker('));
    });

    test('La phrase qui disait qu’on ne peut pas prolonger a disparu',
        () {
      // Elle est devenue fausse : le parent peut désormais modifier
      // l'échéance d'un partage en cours.
      final code = _codeSansCommentaires(
        'lib/sharing/create_share_link_page.dart',
      );

      expect(code, isNot(contains('ne peut pas être prolongé')));
      expect(code, contains('Vous pourrez '));
    });

    test('« Choisir une date » sans date choisie est refusé', () {
      // Le choix ne vaut rien tant qu'aucune date n'est retenue : sans
      // ce refus, la génération partirait sans échéance.
      expect(ecran, contains('Choisissez la date de fin du lien.'));
      expect(
        ecran.indexOf('Choisissez la date de fin du lien.'),
        lessThan(ecran.indexOf('createLink(')),
      );
    });

    test('Le lien permanent annonce le rappel semestriel', () {
      // Un lien qui n'expire jamais demande que le parent garde la
      // main dessus. Le lui dire à la création vaut mieux que de le
      // découvrir six mois plus tard.
      expect(ecran, contains('n’a pas de date de fin'));
      expect(ecran, contains('Tous les 6 mois'));
    });

    test('Le service accepte une échéance nulle et le drapeau', () {
      final service = source('lib/sharing/share_link_service.dart');

      expect(service, contains('required DateTime? dateExpiration'));
      expect(service, contains('bool permanent = false'));
      expect(service, contains("'permanent': permanent,"));
    });
  });

  group('Prolonger ou raccourcir un partage en cours', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('Le service expose la modification d’échéance', () {
      final service = source('lib/sharing/share_link_service.dart');

      expect(service, contains('Future<void> updateExpiration('));
      expect(service, contains("'date_expiration':"));
      expect(service, contains("'permanent': permanent,"));
    });

    test('Date et drapeau partent toujours ensemble', () {
      // La base impose « soit une date, soit permanent, jamais les
      // deux ni aucun ». Écrire l'un sans l'autre ferait échouer la
      // contrainte, avec un message que le parent ne comprendrait pas.
      final service = source('lib/sharing/share_link_service.dart');
      final debut = service.indexOf('Future<void> updateExpiration(');
      final fin = service.indexOf('/// Crée un lien de partage');
      final methode = service.substring(debut, fin);

      expect(methode, contains('permanent ? null :'));
      expect(methode, contains("'permanent': permanent,"));
    });

    test('Le geste est proposé sur les partages actifs', () {
      final ecran = source('lib/children/child_profile_page.dart');

      expect(ecran, contains('onChangerDate:'));
      expect(ecran, contains("tooltip: 'Modifier la date de fin'"));
      expect(ecran, contains('_changerEcheance('));
    });

    test('Jamais sur un partage terminé', () {
      // Il n'y a plus rien à prolonger : le lien est révoqué ou
      // expiré, et le parent doit en créer un nouveau.
      final ecran = source('lib/children/child_profile_page.dart');
      final debut = ecran.indexOf('Widget _partageTermineCard(');
      final fin = ecran.indexOf('Widget _partageCard(');

      expect(
        ecran.substring(debut, fin),
        isNot(contains('onChangerDate')),
      );
    });

    test('La date choisie vaut jusqu’à la fin du jour', () {
      // Même règle qu'à la création : un parent qui choisit le 12
      // s'attend à ce que le lien marche encore le 12 au soir.
      final ecran = source('lib/children/child_profile_page.dart');
      final debut = ecran.indexOf('Future<void> _changerEcheance(');
      final fin = ecran.indexOf('Widget _partageCard(');
      final methode = ecran.substring(debut, fin);

      expect(methode, contains('23,'));
      expect(methode, contains('59,'));
    });
  });

  group('Les ouvertures depuis un autre appareil', () {
    TentativePartageData tentative({bool toleree = false}) {
      return TentativePartageData(
        id: 'tentative-1',
        partageId: 'partage-1',
        tenteeLe: DateTime(2026, 8, 27, 14),
        toleree: toleree,
      );
    }

    test('Rien à dire quand rien ne s’est passé', () {
      expect(libelleTentatives([]), isNull);
    });

    test('Un refus se dit au singulier', () {
      expect(
        libelleTentatives([tentative()]),
        'Une ouverture a été refusée depuis un autre appareil.',
      );
    });

    test('Plusieurs refus se comptent', () {
      expect(
        libelleTentatives([tentative(), tentative(), tentative()]),
        contains('3 ouvertures'),
      );
    });

    test('Une reprise tolérée se dit autrement qu’un refus', () {
      // Correction de Fanny : la fenêtre de quinze minutes ne doit pas
      // être un trou invisible. Le parent la voit, mais comme une
      // information et non comme un refus.
      final libelle = libelleTentatives([tentative(toleree: true)]);

      expect(libelle, isNotNull);
      expect(libelle, isNot(contains('refusée')));
      expect(libelle, contains('rouvert'));
    });

    test('Un refus prime sur une tolérance', () {
      // C'est lui qui demande une décision au parent.
      expect(
        libelleTentatives([
          tentative(toleree: true),
          tentative(),
        ]),
        contains('refusée'),
      );
    });

    test('La ligne rendue par la base se relit', () {
      final lue = TentativePartageData.fromRow({
        'id': 'tentative-1',
        'partage_id': 'partage-1',
        'tentee_le': '2026-08-27T14:00:00Z',
        'toleree': true,
      });

      expect(lue.partageId, 'partage-1');
      expect(lue.toleree, isTrue);
    });
  });

  group('Le verrouillage, côté application', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('Le parent peut autoriser un nouvel appareil', () {
      // Sans ce geste, un destinataire légitime verrouillé dehors
      // n'aurait aucun recours, et le parent devrait révoquer puis
      // tout retransmettre — pour un lien qui n'a jamais fuité.
      final service = source('lib/sharing/share_link_service.dart');

      expect(service, contains('Future<void> libererVerrou('));
      expect(service, contains("'verrou_empreinte': null"));
      expect(service, contains("'verrou_pose_le': null"));
    });

    test('L’écran propose le geste et dit quoi faire', () {
      final ecran = source('lib/children/child_profile_page.dart');

      expect(ecran, contains('Autoriser ce nouvel appareil'));
      expect(ecran, contains('Sinon, révoquez le '));
      expect(ecran, contains('_libererVerrou('));
    });

    test('Le serveur ne stocke jamais le secret en clair', () {
      // C'est l'empreinte qui est stockée : une fuite de la table ne
      // donnerait à personne de quoi rouvrir un lien.
      final logique = source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(logique, contains('await empreinteDuSecret(nouveauSecret)'));
    });

    test('Un appareil refusé n’a rien à lire', () {
      // Le refus tombe avant la lecture de l'enfant et des profils.
      final logique = source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(
        logique.indexOf("statut: 'lienVerrouille'"),
        lessThan(logique.indexOf('depot.enfant(')),
      );
    });

    test('Le refus a son propre message, pas celui d’un lien invalide',
        () {
      // « Lien invalide » aurait laissé croire à une panne, et la
      // personne aurait réessayé au lieu de rappeler le parent.
      final logique = source(
        'supabase/functions/_logique/partage_consultation.mts',
      );

      expect(logique, contains('LIEN_VERROUILLE'));
      expect(logique, contains('Demandez un nouveau lien au parent.'));
    });

    test('La page range le secret par lien, pas globalement', () {
      // Deux liens différents ne doivent pas se marcher dessus.
      final page = source(
        'supabase/functions/_logique/page_partage.mts',
      );

      expect(page, contains("'kidsrelay_partage_' + token"));
      expect(page, contains('localStorage'));
    });

    test('Un stockage refusé n’empêche pas la page de s’ouvrir', () {
      // Navigation privée stricte, cookies bloqués : on ouvre sans
      // secret, et le serveur décide.
      final page = source(
        'supabase/functions/_logique/page_partage.mts',
      );

      expect(page, contains('catch (e)'));
      expect(page, contains('afficherVerrouille('));
    });
  });

  group('Le nombre d’appareils, choisi par le parent', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/sharing/create_share_link_page.dart');

    test('Trois choix, et une seule personne par défaut', () {
      expect(ecran, contains("un('Une seule personne', 1)"));
      expect(ecran, contains("deux('Jusqu’à 2 personnes', 2)"));
      expect(ecran, contains("cinq('Jusqu’à 5 personnes', 5)"));
      expect(
        ecran,
        contains('_NombreAppareils _appareils = _NombreAppareils.un'),
        reason: 'Une seule personne est le défaut',
      );
    });

    test('La question et sa ligne d’explication sont posées', () {
      expect(
        ecran,
        contains(
          'Combien de personnes doivent pouvoir consulter la fiche ?',
        ),
      );

      // Ce n'est pas un avertissement : c'est ce qui explique le
      // chiffre. Sans cette ligne, le parent qui choisit « 2 » pour
      // deux grands-parents sera surpris que la grand-mère consomme
      // les deux places à elle seule.
      expect(ecran, contains('Chaque appareil compte.'));
    });

    test('Le choix part jusqu’à la base', () {
      expect(ecran, contains('appareilsMax: _appareils.nombre'));

      final service = source('lib/sharing/share_link_service.dart');

      expect(service, contains('int appareilsMax = 1'));
      expect(service, contains("'appareils_max': appareilsMax,"));
    });

    test('Le modèle relit la colonne, et vaut 1 si elle manque', () {
      final lien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-27T10:00:00Z',
        'date_expiration': '2026-08-28T10:00:00Z',
        'date_derniere_consultation': null,
        'appareils_max': 5,
      });

      expect(lien.appareilsMax, 5);

      final ancien = ShareLinkData.fromRow({
        'id': 'partage-1',
        'token': 'jeton',
        'enfant_id': 'enfant-1',
        'type_fiche': 'secours',
        'destinataire': 'particulier',
        'date_creation': '2026-08-27T10:00:00Z',
        'date_expiration': '2026-08-28T10:00:00Z',
        'date_derniere_consultation': null,
      });

      expect(ancien.appareilsMax, 1);
    });

    test('Le QR n’est pas traité à part', () {
      // Décision du 27/08/2026 : restreindre le QR à un seul appareil
      // pousserait la maîtresse à photographier la fiche et à
      // l'envoyer par messagerie — et là, plus de verrou, plus de
      // révocation, plus de journal.
      expect(ecran, contains('QR compris'));
    });
  });

  group('La fenêtre de tolérance ne glisse plus', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    test('Un remplacement ne touche pas à la date de prise', () {
      // Le défaut constaté en production le 27/08/2026 :
      // `verrou_pose_le` était réécrit à chaque reprise, donc la
      // tolérance était renouvelable sans fin.
      // Sans les commentaires : celui de la méthode cite `pris_le`
      // pour expliquer qu'on n'y touche pas, et une assertion posée
      // sur le texte brut s'y heurterait. Troisième fois ce soir.
      final depot = _codeSansCommentaires(
        'supabase/functions/_enveloppe/depot_partages.mts',
      );
      final debut = depot.indexOf('async remplacerPlace(');
      final fin = depot.indexOf('async journaliserTentative(');
      final methode = depot.substring(debut, fin);

      expect(methode, contains('.update({ empreinte })'));
      expect(
        methode,
        isNot(contains('pris_le')),
        reason: 'Réécrire la date ferait glisser la fenêtre',
      );
    });

    test('La base garde les deux colonnes de l’ancien verrou', () {
      // Les supprimer avant le redéploiement casserait la fonction
      // déployée, qui les lit encore : plus aucun lien ne s'ouvrirait
      // entre les deux.
      final sql = source('supabase/schema_appareils_partage.sql');

      expect(sql, contains('drop column verrou_empreinte'));
      expect(
        sql.indexOf('--   alter table public.partages'),
        greaterThan(0),
        reason: 'La suppression doit rester commentée',
      );
    });
  });

  group('La préautorisation de l’accès secours', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/secours/acces_secours_page.dart');

    test('Elle se décide par enfant, pas par partage', () {
      // Elle était d'abord à la création de chaque partage. Le parent
      // aurait dû y penser à chaque fois — et le jour où il oublie
      // serait le jour de l'accident. Décision du 28/08/2026.
      final creation =
          source('lib/sharing/create_share_link_page.dart');

      expect(creation, isNot(contains('Accès secours')));
      expect(creation, isNot(contains('accesSecoursAutorise')));
    });

    test('Deux boutons, et non une case à cocher', () {
      // Une case non cochée ne prouve rien : on ne peut pas distinguer
      // un parent qui a refusé d'un parent qui a lu en travers. Or
      // c'est la préautorisation qui doit pouvoir être démontrée.
      expect(ecran, contains('J’accepte'));
      expect(ecran, contains('Je refuse'));
      expect(ecran, isNot(contains('CheckboxListTile')));
    });

    test('Les deux réponses ont strictement le même poids', () {
      // Si « J'accepte » était plus visible que « Je refuse », le
      // refus ne serait plus libre, et la préautorisation perdrait la
      // valeur qu'on lui cherche.
      final debut = ecran.indexOf('Row(');
      final fin = ecran.indexOf('Répondre plus tard');
      final zone = ecran.substring(debut, fin);

      // Même widget des deux côtés, et aucun bouton d'accent.
      expect('OutlinedButton('.allMatches(zone).length, 2);
      expect(zone, isNot(contains('FilledButton')));
      expect(zone, isNot(contains('ElevatedButton')));

      // Aucune couleur posée sur l'un des deux.
      expect(zone, isNot(contains('backgroundColor')));
      expect(zone, isNot(contains('foregroundColor')));

      // Même largeur : les deux sont dans un Expanded.
      expect('Expanded('.allMatches(zone).length, 2);
    });

    test('Aucune réponse n’est pré-sélectionnée', () {
      // L'écran ne porte aucun état de réponse : il n'y a rien à
      // pré-cocher, et rien qui puisse l'être par inadvertance.
      expect(ecran, isNot(contains('bool _autorise')));
      expect(ecran, contains('this.valeurInitiale'));
    });

    test('Poursuivre sans répondre reste possible', () {
      // L'absence de réponse ne bloque pas la création du profil.
      expect(ecran, contains('Répondre plus tard'));
      expect(ecran, contains('ReponseAccesSecours.plusTard'));
    });

    test('Refuser ne coûte rien : aucune confirmation, aucun retour',
        () {
      // Pas d'écran qui fait douter le parent, pas de tentative de le
      // faire revenir sur son choix.
      final debut = ecran.indexOf('Future<void> _repondre(');
      final fin = ecran.indexOf('Widget build(');
      final methode = ecran.substring(debut, fin);

      expect(methode, isNot(contains('showDialog')));
      expect(methode, isNot(contains('Êtes-vous sûr')));
    });

    test('Il dit aussi ce que le refus laisse, et ce qu’il coûte',
        () {
      // Au conditionnel, et AVANT que le parent choisisse : il doit
      // le lire pour décider, pas le découvrir après.
      expect(ecran, contains('Si vous refusez et que '));
      expect(ecran, contains('la fiche resterait sur le téléphone '));
      expect(ecran, contains('camion n’aurait rien'));
      expect(ecran, contains('Vous seul pourriez leur donner '));
    });

    test('Le texte dit les trois choses qui engagent le parent', () {
      expect(ecran, contains('sans attendre votre réponse'));
      expect(ecran, contains('prévenu immédiatement'));
      expect(ecran, contains('mettre fin à tout moment'));
    });

    test('Il dit aussi ce que l’accès ne donne pas, et sa durée', () {
      // La phrase est coupée en deux lignes dans la source : on
      // vérifie les deux moitiés telles qu'elles y sont écrites.
      expect(ecran, contains('ne donne que les '));
      expect(
        ecran,
        contains('informations pour les secours, et dure 24 heures.'),
      );
    });

    test('Elle est demandée après le questionnaire, avant la base', () {
      // Le parent vient de voir ce que la fiche contient, et le choix
      // part en base avec le reste, sans seconde écriture.
      final contacts =
          source('lib/transmission_pages/contacts_page.dart');

      expect(contacts, contains('AccesSecoursPage('));
      expect(
        contacts.indexOf('AccesSecoursPage('),
        lessThan(contacts.indexOf('TransitionToActivitiesPage(')),
      );
    });

    test('Le modèle porte trois états, pas deux', () {
      final modele = source('lib/models/child_profile_data.dart');
      final codec =
          source('lib/repositories/child_profile_codec.dart');

      expect(modele, contains('bool? accesSecoursAutorise;'));

      // Nul quand la question n'a jamais été posée : un état à part
      // entière, pas un refus par défaut.
      expect(
        codec,
        contains("enfant['acces_secours_autorise'] as bool?,"),
      );
    });
  });

  group('La ligne dans le profil de l’enfant', () {
    String source(String chemin) => File(chemin).readAsStringSync();

    final ecran = source('lib/children/child_profile_page.dart');

    test('Elle est en tête de la section Partages', () {
      // Elle gouverne TOUS les partages de cet enfant.
      expect(
        ecran.indexOf('_ligneAccesSecours(context)'),
        lessThan(ecran.indexOf('_buildPartagesSection(context)')),
      );
    });

    test('Les trois états ont chacun leur titre', () {
      expect(ecran, contains('Accès secours : autorisé'));
      expect(ecran, contains('Accès secours : non autorisé'));
      expect(
        ecran,
        contains('vous n’avez pas encore répondu'),
        reason:
            'Un silence n’est pas une décision et ne doit pas être '
            'présenté comme un refus',
      );
    });

    test('Le bouton dit ce qu’il fait, dans les trois états', () {
      expect(ecran, contains("'Modifier'"));
      expect(ecran, contains('Autoriser l’accès secours'));
      expect(ecran, contains("'Répondre'"));
    });

    test('Le refus dit sa conséquence, pas seulement son statut', () {
      // Un parent a pu passer vite sur l'écran du questionnaire sans
      // mesurer ce qu'il refusait. Il ne doit pas le découvrir le jour
      // de l'accident.
      expect(ecran, contains('la fiche restera '));
      expect(ecran, contains('celle qui monte dans le camion '));
      expect(ecran, contains('Vous seul pourrez leur donner '));
    });

    test('Il ne dit plus qu’on ne peut rien transmettre', () {
      // C'était faux, et corrigé le 28/08/2026 : rien n'interdit de
      // montrer son écran ou de lire la fiche à voix haute à un
      // soignant. Ce que le refus empêche, c'est de DONNER un accès
      // durable à quelqu'un d'autre.
      expect(
        ecran,
        isNot(contains('ne pourra pas transmettre les informations ')),
      );
    });

    test('Le refus n’est pas peint en ambre', () {
      // L'ambre signale ailleurs une action attendue. L'employer ici
      // transformerait un choix légitime en anomalie à corriger.
      final debut = ecran.indexOf('Widget _ligneAccesSecours(');
      final fin = ecran.indexOf('Future<void> _modifierAccesSecours(');

      expect(
        ecran.substring(debut, fin),
        isNot(contains('ambreFond')),
      );
    });
  });

}
