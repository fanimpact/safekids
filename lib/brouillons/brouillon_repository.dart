import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_profile_draft.dart';
import '../models/child_profile_draft.dart';
import 'brouillon_profil.dart';

/// Range les questionnaires commencés, sur l'appareil et nulle part
/// ailleurs.
///
/// **Sur l'appareil, délibérément.** Écrire un brouillon en base
/// aurait voulu dire créer une ligne `enfants` incomplète — et donc
/// apprendre à toute l'application, jusqu'au Mode Urgence, à
/// distinguer un enfant d'un brouillon. Un enfant à moitié saisi
/// apparaissant dans le Mode Urgence avec « Aucune consigne
/// particulière » aurait été un mauvais échange contre la survie au
/// changement d'appareil.
///
/// Ce que cela coûte, et qu'il faut savoir : le brouillon meurt avec
/// l'appareil. Réinstallation, téléphone perdu, second appareil — on
/// repart de zéro. Une table de brouillons en base réglerait cela ;
/// elle attend qu'un besoin réel se manifeste.
class BrouillonRepository extends ChangeNotifier {
  BrouillonRepository._();

  static final BrouillonRepository instance = BrouillonRepository._();

  static const _cle = 'kidsrelay_brouillons_profil';

  /// Injectée pour les tests ; en production, l'heure de l'appareil.
  @visibleForTesting
  DateTime Function() horloge = DateTime.now;

  List<BrouillonProfil> _brouillons = [];
  bool _charge = false;

  List<BrouillonProfil> get brouillons =>
      List.unmodifiable(_brouillons);

  /// Charge, en jetant au passage ce qui a dormi plus de 30 jours.
  ///
  /// La purge a lieu **à la lecture** et est réécrite aussitôt : un
  /// brouillon périmé ne doit pas survivre parce que personne n'a
  /// pensé à repasser derrière.
  Future<List<BrouillonProfil>> charger() async {
    String? brut;

    try {
      final prefs = await SharedPreferences.getInstance();
      brut = prefs.getString(_cle);
    } catch (erreur) {
      // Stockage indisponible : l'ecran doit s'ouvrir quand meme, sans
      // reprise proposee.
      debugPrint('Brouillons illisibles : $erreur');
      _brouillons = [];
      _charge = true;
      return brouillons;
    }

    if (brut == null) {
      _brouillons = [];
      _charge = true;
      return brouillons;
    }

    var lus = <BrouillonProfil>[];

    try {
      final liste = jsonDecode(brut) as List<dynamic>;

      lus = liste
          .whereType<Map<String, dynamic>>()
          .map(BrouillonProfil.fromJson)
          .whereType<BrouillonProfil>()
          .toList();
    } catch (erreur) {
      // Stockage illisible : on repart de rien plutôt que d'empêcher
      // l'application de s'ouvrir. Un brouillon perdu est ennuyeux ;
      // une application bloquée l'est davantage.
      debugPrint('Brouillons illisibles, remis à zéro : $erreur');
      lus = [];
    }

    final vivants = sansPerimes(lus, horloge());

    _brouillons = vivants;
    _charge = true;

    if (vivants.length != lus.length) {
      try {
        await _ecrire();
      } catch (erreur) {
        // La purge reessaiera au prochain chargement ; elle ne doit pas
        // remonter jusqu'a l'ecran.
        debugPrint('Purge des brouillons non ecrite : $erreur');
      }
    }

    return brouillons;
  }

  Future<void> enregistrerSante(ChildProfileDraft draft) async {
    await _remplacer(
      TypeBrouillon.sante,
      draft.childId,
      (commenceLe) => brouillonDepuisSante(
        draft,
        commenceLe: commenceLe,
        modifieLe: horloge(),
      ),
    );
  }

  Future<void> enregistrerActivites(
    ActivityProfileDraft draft, {
    required String childId,
    required String? prenom,
  }) async {
    await _remplacer(
      TypeBrouillon.activites,
      childId,
      (commenceLe) => brouillonDepuisActivites(
        draft,
        childId: childId,
        prenom: prenom,
        commenceLe: commenceLe,
        modifieLe: horloge(),
      ),
    );
  }

  /// Appelée quand le questionnaire est allé au bout : le brouillon n'a
  /// plus de raison d'être, et il contient des données de santé.
  Future<void> supprimer(
    TypeBrouillon type,
    String childId,
  ) async {
    if (!_charge) {
      await charger();
    }

    final avant = _brouillons.length;

    _brouillons = _brouillons
        .where(
          (brouillon) =>
              brouillon.type != type || brouillon.childId != childId,
        )
        .toList();

    if (_brouillons.length != avant) {
      await _ecrire();
    }
  }

  BrouillonProfil? trouver(TypeBrouillon type, String childId) {
    for (final brouillon in _brouillons) {
      if (brouillon.type == type && brouillon.childId == childId) {
        return brouillon;
      }
    }

    return null;
  }

  @visibleForTesting
  Future<void> viderPourTests() async {
    _brouillons = [];
    _charge = true;
    await _ecrire();
  }

  /// La date de début est celle du brouillon existant, s'il y en a un :
  /// c'est elle que le parent lit — « commencé le 25/08 » doit désigner
  /// le jour où il a commencé, pas celui du dernier écran rempli.
  Future<void> _remplacer(
    TypeBrouillon type,
    String childId,
    BrouillonProfil Function(DateTime commenceLe) construire,
  ) async {
    if (!_charge) {
      await charger();
    }

    final existant = trouver(type, childId);
    final nouveau = construire(existant?.commenceLe ?? horloge());

    _brouillons = [
      ..._brouillons.where(
        (brouillon) =>
            brouillon.type != type || brouillon.childId != childId,
      ),
      nouveau,
    ];

    await _ecrire();
  }

  Future<void> _ecrire() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cle,
      jsonEncode(
        _brouillons.map((brouillon) => brouillon.toJson()).toList(),
      ),
    );

    notifyListeners();
  }
}
