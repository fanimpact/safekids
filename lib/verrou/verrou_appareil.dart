import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'regle_verrou.dart';

/// Ce que le déverrouillage a donné.
enum ResultatVerrou {
  /// La personne a prouvé qu'elle tient bien ce téléphone.
  ouvert,

  /// L'appareil n'a **aucun verrou** — ni biométrie, ni code. Il n'y a
  /// rien à demander, et l'application s'ouvre.
  ///
  /// Exiger un mot de passe sur un téléphone que n'importe qui peut
  /// allumer et consulter ne protégerait rien : cela gênerait le
  /// parent sans arrêter personne.
  aucunVerrouSurLAppareil,

  /// Échec ou annulation. **Jamais le mot de passe du compte** en
  /// repli : c'est exactement celui qu'un parent ne retrouve pas au
  /// moment où il en a besoin.
  refuse,
}

/// Le déverrouillage par l'appareil : empreinte, visage, ou code du
/// téléphone selon ce que le parent utilise.
///
/// **L'ordre est celui du système**, pas le nôtre : `local_auth` avec
/// `biometricOnly: false` propose la biométrie d'abord et bascule sur
/// le code de l'appareil si elle échoue ou manque. Le parent connaît ce
/// code, il l'utilise vingt fois par jour — contrairement au mot de
/// passe de son compte.
class VerrouAppareil {
  VerrouAppareil._();

  static final VerrouAppareil instance = VerrouAppareil._();

  static const _cleDerniereOuverture = 'kidsrelay_derniere_ouverture';

  /// Injectés pour les tests.
  @visibleForTesting
  LocalAuthentication auth = LocalAuthentication();

  @visibleForTesting
  DateTime Function() horloge = DateTime.now;

  /// Vrai s'il faut redemander le déverrouillage maintenant.
  Future<bool> estRequis() async {
    return verrouRequis(
      derniereOuverture: await _derniereOuverture(),
      maintenant: horloge(),
    );
  }

  /// Demande le déverrouillage, et note l'ouverture si elle réussit.
  Future<ResultatVerrou> demander() async {
    bool protege;

    try {
      protege = await auth.isDeviceSupported();
    } catch (erreur) {
      // Plateforme sans support (web, bureau) : rien a demander.
      debugPrint('Verrou indisponible : $erreur');
      protege = false;
    }

    if (!protege) {
      await marquerOuverture();
      return ResultatVerrou.aucunVerrouSurLAppareil;
    }

    bool ouvert;

    try {
      ouvert = await auth.authenticate(
        localizedReason:
            'Déverrouillez pour accéder aux informations de santé de '
            'vos enfants.',
        // `false` : c'est ce qui autorise le code de l'appareil en
        // repli de la biometrie. Le mettre a `true` enfermerait
        // dehors un parent aux doigts mouilles.
        biometricOnly: false,
        // L'authentification survit a un passage en arriere-plan —
        // une notification qui s'affiche pendant la demande ne doit
        // pas tout annuler.
        persistAcrossBackgrounding: true,
      );
    } catch (erreur) {
      // Aucun verrou configuré sur l'appareil, ou plugin indisponible.
      // On ouvre : il n'y a rien a proteger que le telephone ne
      // protege deja.
      debugPrint('Déverrouillage impossible : $erreur');
      await marquerOuverture();
      return ResultatVerrou.aucunVerrouSurLAppareil;
    }

    if (!ouvert) {
      return ResultatVerrou.refuse;
    }

    await marquerOuverture();
    return ResultatVerrou.ouvert;
  }

  /// À appeler quand l'application s'ouvre ou revient au premier plan.
  Future<void> marquerOuverture() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _cleDerniereOuverture,
        horloge().toIso8601String(),
      );
    } catch (erreur) {
      // Stockage indisponible : le verrou sera redemandé au prochain
      // démarrage. Gênant, jamais bloquant.
      debugPrint('Ouverture non enregistrée : $erreur');
    }
  }

  Future<DateTime?> _derniereOuverture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cleDerniereOuverture);

      return brut == null ? null : DateTime.tryParse(brut);
    } catch (erreur) {
      debugPrint('Dernière ouverture illisible : $erreur');
      return null;
    }
  }
}
