import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/textes/consigne_domaine_jeune.dart';

// La consigne « regardez dans vos courriers indésirables »
// (28/08/2026).
//
// Le premier mail réel de KidsRelay est arrivé dans les indésirables
// d'une boîte Hotmail. L'authentification n'était pas en cause —
// Microsoft a répondu `compauth=pass reason=100`, son verdict le plus
// élevé — et l'IP d'envoi n'était sur aucune liste noire. Il ne restait
// qu'une explication : `kidsrelay.fr` n'a pas d'historique d'envoi.
//
// Fanny a refusé de laisser les parents découvrir le problème seuls.
//
// Ce que ces tests protègent : le ton, la présence aux deux endroits,
// et surtout **la possibilité de tout retirer d'un geste** le jour où
// la réputation sera faite.

String _source(String chemin) => File(chemin).readAsStringSync();

/// Le module serveur, qui porte le texte réellement envoyé.
final String _moduleServeur =
    _source('supabase/functions/_logique/consigne_domaine_jeune.mts');

void main() {
  group('Les deux endroits disent la même chose', () {
    test('Le texte du mail est identique des deux côtés', () {
      // Deux langages, donc deux fichiers. Mais jamais deux textes qui
      // divergent sans qu'on s'en aperçoive : c'est ce test qui le
      // garantit.
      // Le texte serveur est écrit en morceaux concaténés : on prend
      // tout ce qui suit la déclaration, jusqu'au point-virgule.
      final bloc = _moduleServeur
          .split('export const CONSIGNE_DOMAINE_JEUNE =')[1]
          .split(';')[0];

      final morceaux = RegExp("'([^']*)'")
          .allMatches(bloc)
          .map((m) => m.group(1)!)
          .join();

      expect(morceaux, isNotEmpty, reason: 'texte serveur introuvable');
      expect(morceaux, consigneDomaineJeuneEmail);
    });

    test('Les deux drapeaux sont dans le même état', () {
      // Sans cela, on pourrait éteindre l'écran et laisser le mail
      // parler d'une application récente pendant des mois.
      final serveurActif =
          _moduleServeur.contains('CONSIGNE_DOMAINE_JEUNE_ACTIVE = true');

      expect(
        serveurActif,
        consigneDomaineJeuneActive,
        reason: 'un drapeau a été changé sans l’autre',
      );
    });
  });

  group('Le ton, qui était une consigne ferme', () {
    final textes = [
      titreConsigneDomaineJeune,
      consigneDomaineJeuneEcran,
      consigneDomaineJeuneEmail,
    ];

    test('Aucune conséquence, aucun enfant, aucun secours', () {
      // « Vous risquez de ne pas être prévenu si votre enfant part
      // avec les pompiers » était explicitement interdit. On parle
      // d'une application jeune et d'un geste à faire, rien d'autre.
      for (final texte in textes) {
        for (final interdit in [
          'enfant',
          'secours',
          'pompiers',
          'urgence',
          'risque',
          'danger',
          'important',
          'attention',
        ]) {
          expect(
            texte.toLowerCase(),
            isNot(contains(interdit)),
            reason: '« $interdit » fait peur, et c’était exclu',
          );
        }
      }
    });

    test('« courriers indésirables », jamais « spam »', () {
      // C'est le terme affiché en français par Hotmail, Gmail et
      // Outlook. Une personne peu à l'aise cherche le mot qu'elle a
      // sous les yeux.
      expect(consigneDomaineJeuneEcran, contains('courriers indésirables'));
      expect(consigneDomaineJeuneEmail, contains('courriers indésirables'));

      for (final texte in textes) {
        expect(texte.toLowerCase(), isNot(contains('spam')));
        expect(texte.toLowerCase(), isNot(contains('pourriel')));
      }
    });

    test('« légitime », jamais une formulation négative', () {
      // Décision de Fanny, y compris là où le bouton du fournisseur
      // dit autre chose.
      expect(consigneDomaineJeuneEcran, contains('légitime'));
      expect(consigneDomaineJeuneEmail, contains('légitimes'));

      for (final texte in textes) {
        expect(texte, isNot(contains('indésirable.')));
        expect(texte.toLowerCase(), isNot(contains('non-courrier')));
      }
    });

    test('Le titre ne s’adresse qu’à celui qui a le problème', () {
      // Sans lui, tout le monde lit un paragraphe qui ne le concerne
      // pas, sur un écran où l'on attend déjà.
      expect(titreConsigneDomaineJeune, 'Vous ne recevez rien ?');
    });
  });

  group('Elle est aux deux endroits', () {
    test('À l’écran, sous le bouton de renvoi', () {
      // Le point le plus important : si la consigne n'était que dans
      // le mail, la personne ne la lirait jamais — le mail est
      // justement dans les indésirables.
      final ecran = _source('lib/auth/device_verification_page.dart');

      expect(ecran, contains('if (consigneDomaineJeuneActive)'));
      expect(ecran, contains('titreConsigneDomaineJeune'));
      expect(ecran, contains('consigneDomaineJeuneEcran'));

      expect(
        ecran.indexOf('Renvoyer le code'),
        lessThan(ecran.indexOf('consigneDomaineJeuneActive')),
      );
    });

    test('En pied du mail de code', () {
      final emails = _source('supabase/functions/_logique/emails.mts');

      expect(emails, contains('piedConsigneHtml()'));
      expect(emails, contains('piedConsigneTexte()'));
    });

    test('Le mail de code existe aussi en texte simple', () {
      // Un message qui n'existe qu'en HTML est un signal de courrier
      // indésirable — c'est précisément le problème traité ici.
      final emails = _source('supabase/functions/_logique/emails.mts');

      expect(emails, contains('texte:'));
    });
  });

  group('On peut la retirer d’un geste', () {
    test('Un seul drapeau de chaque côté, et rien d’autre', () {
      // Le jour venu, on passe les deux à `false` et les deux textes
      // disparaissent ensemble. Aucune autre condition à trouver.
      expect(
        _moduleServeur,
        contains('if (!CONSIGNE_DOMAINE_JEUNE_ACTIVE) {'),
      );

      final ecran = _source('lib/auth/device_verification_page.dart');

      expect(
        RegExp('consigneDomaineJeuneActive').allMatches(ecran).length,
        1,
        reason: 'une seule condition à l’écran, pas plusieurs',
      );
    });

    test('Le fichier dit à quoi reconnaître le moment', () {
      // Sans critère écrit, la consigne resterait pour toujours ou
      // partirait trop tôt.
      final dart = _source('lib/textes/consigne_domaine_jeune.dart');

      expect(dart, contains('boîte Hotmail neuve'));
      expect(dart, contains('sans que personne'));
    });
  });
}
