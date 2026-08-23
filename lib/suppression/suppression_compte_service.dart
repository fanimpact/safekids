import 'package:supabase_flutter/supabase_flutter.dart';

/// Suppression du compte avec délai de grâce.
///
/// Le compte devient inaccessible dès la demande ; les données sont
/// effacées définitivement 7 jours plus tard. Pendant ce délai, le
/// parent peut annuler et tout retrouver.
///
/// Le blocage et l'effacement sont dans la base (voir
/// `supabase/schema_conformite_rgpd.sql`) : c'est le seul endroit qui
/// tienne, puisqu'un compte bloqué doit l'être aussi pour qui
/// contournerait l'application. Ce service n'est que la porte
/// d'entrée.
abstract class SuppressionCompteService {
  /// Date d'effacement définitif si une demande est en cours, `null`
  /// sinon.
  Future<DateTime?> suppressionEnCours();

  /// Enregistre la demande et rend la date d'effacement définitif.
  Future<DateTime> demanderSuppression();

  Future<void> annulerSuppression();

  /// Prévient le parent par email. Séparé de [demanderSuppression] :
  /// un email qui ne part pas ne doit pas annuler une demande de
  /// suppression déjà enregistrée, mais le parent doit l'apprendre.
  Future<void> envoyerEmailConfirmation(DateTime effacementLe);
}

class SuppressionCompteServiceSupabase
    implements SuppressionCompteService {
  const SuppressionCompteServiceSupabase();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<DateTime?> suppressionEnCours() async {
    final resultat = await _client.rpc('suppression_en_cours');

    if (resultat == null) {
      return null;
    }

    return DateTime.parse(resultat as String).toLocal();
  }

  @override
  Future<DateTime> demanderSuppression() async {
    final resultat =
        await _client.rpc('demander_suppression_compte');

    return DateTime.parse(resultat as String).toLocal();
  }

  @override
  Future<void> annulerSuppression() async {
    await _client.rpc('annuler_suppression_compte');
  }

  @override
  Future<void> envoyerEmailConfirmation(
    DateTime effacementLe,
  ) async {
    await _client.functions.invoke(
      'confirmer-suppression-compte',
      body: {
        'effacementLe': effacementLe.toUtc().toIso8601String(),
      },
    );
  }
}
