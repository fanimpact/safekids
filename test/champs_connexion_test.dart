import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Les champs de connexion (28/08/2026).
//
// Deux corrections d'un coup, toutes deux vécues par Fanny :
//
//   - la touche Entrée ne faisait rien, sur aucun champ. Il fallait
//     viser le bouton, ce qui est pénible à la souris et pire au doigt ;
//   - le trousseau du téléphone était désactivé partout, de peur qu'il
//     propose le compte professionnel à la place du compte parent. Mais
//     il PROPOSE, il n'impose pas.
//
// Lecture de sources : ces écrans demandent une session Supabase pour
// se monter, et ce qu'on protège est la présence d'attributs qui
// disparaissent sans bruit.

const _ecransConnexion = [
  'lib/login_page.dart',
  'lib/register_page.dart',
  'lib/forgot_password_page.dart',
  'lib/professional/professional_login_page.dart',
  'lib/professional/professional_register_page.dart',
];

const _tousLesEcrans = [
  ..._ecransConnexion,
  'lib/auth/device_verification_page.dart',
  'lib/auth/set_new_password_page.dart',
];

String _source(String chemin) => File(chemin).readAsStringSync();

void main() {
  group('Le trousseau est réactivé partout', () {
    test('Plus aucun champ ne le désactive', () {
      // C'était `autofillHints: const []` dans sept endroits.
      for (final ecran in [..._tousLesEcrans, 'lib/widgets/sk_password_field.dart']) {
        expect(
          _source(ecran),
          isNot(contains('autofillHints: const []')),
          reason: '$ecran prive encore la personne du trousseau',
        );
      }
    });

    test('Les cinq champs email annoncent une adresse', () {
      for (final ecran in _ecransConnexion) {
        expect(
          _source(ecran),
          contains('AutofillHints.email'),
          reason: '$ecran ne dit pas que ce champ est une adresse',
        );
      }
    });

    test('Une création annonce un NOUVEAU mot de passe', () {
      // `newPassword` et non `password` : sur une création, l'OS doit
      // proposer d'en générer un, pas de remplir l'ancien.
      for (final ecran in [
        'lib/register_page.dart',
        'lib/professional/professional_register_page.dart',
        'lib/auth/set_new_password_page.dart',
      ]) {
        expect(
          _source(ecran),
          contains('AutofillHints.newPassword'),
          reason: '$ecran proposerait l’ancien mot de passe',
        );
      }
    });

    test('Une connexion annonce le mot de passe existant', () {
      // C'est le défaut du champ partagé : `password`.
      expect(
        _source('lib/widgets/sk_password_field.dart'),
        contains('const [AutofillHints.password]'),
      );
    });

    test('Le code reçu par email est reconnu comme tel', () {
      // Sur iOS, il arrive au-dessus du clavier sans que la personne
      // ait à basculer vers sa boîte mail pour le recopier.
      expect(
        _source('lib/auth/device_verification_page.dart'),
        contains('AutofillHints.oneTimeCode'),
      );
    });
  });

  group('La touche du clavier valide', () {
    test('Chaque écran de saisie a une action de clavier', () {
      for (final ecran in _tousLesEcrans) {
        expect(
          _source(ecran),
          contains('TextInputAction.'),
          reason: '$ecran laisse le clavier sur un retour à la ligne',
        );
      }
    });

    test('Chaque écran valide au clavier', () {
      for (final ecran in _tousLesEcrans) {
        expect(
          _source(ecran),
          contains('onSubmitted'),
          reason: '$ecran oblige à viser le bouton',
        );
      }
    });

    test('Le dernier champ valide, il ne passe pas au suivant', () {
      // Le mot de passe d'une connexion, la confirmation d'une
      // création, le code : après eux il n'y a rien.
      expect(
        _source('lib/login_page.dart'),
        contains('onSubmitted: () {'),
      );
      expect(
        _source('lib/auth/device_verification_page.dart'),
        contains('TextInputAction.done'),
      );
    });

    test('Un écran à un seul champ valide au lieu d’enchaîner', () {
      // Mot de passe oublié : il n'y a rien après l'adresse.
      final code = _source('lib/forgot_password_page.dart');

      expect(code, contains('TextInputAction.done'));
      expect(code, isNot(contains('TextInputAction.next')));
    });

    test('La validation au clavier respecte l’envoi en cours', () {
      // Sans ce garde, une double frappe enverrait deux fois.
      for (final ecran in _tousLesEcrans) {
        final code = _source(ecran);

        expect(
          code.contains('if (!_isSubmitting)') ||
              code.contains('if (!_isVerifying)'),
          isTrue,
          reason: '$ecran peut envoyer deux fois',
        );
      }
    });
  });
}
