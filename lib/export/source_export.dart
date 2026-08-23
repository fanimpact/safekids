import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_provider.dart';
import 'donnees_export.dart';

/// Collecte des données à exporter.
///
/// Interface d'abord, implémentation Supabase ensuite — même découpage
/// que `AuthProvider` : la règle de cloisonnement (voir
/// [collecterExport]) est testable sans base ni réseau, avec un double.
abstract class SourceExport {
  /// Identifiant du compte connecté. `null` si aucune session.
  String? get identifiantCompte;

  /// Email du compte connecté.
  String? get emailCompte;

  /// Ligne `comptes_parents` du compte connecté, si elle existe.
  ///
  /// Elle porte des donnees personnelles que l'authentification ne
  /// connait pas : adresse de secours, etat d'une demande de
  /// suppression. Sans elle, l'export cesserait d'etre complet.
  Future<Map<String, dynamic>?> compteParent(String compteId);

  /// **Toutes** les lignes de `enfants` visibles par ce compte —
  /// c'est-à-dire ses propres enfants **et** ceux sur lesquels il est
  /// personne de confiance. Le tri est fait par [collecterExport], pas
  /// ici : une source ne décide pas de ce qui a le droit de sortir.
  Future<List<Map<String, dynamic>>> enfantsVisibles();

  Future<Map<String, dynamic>?> profilSante(String enfantId);
  Future<Map<String, dynamic>?> profilActivites(String enfantId);

  Future<List<Map<String, dynamic>>> partages(String enfantId);
  Future<List<Map<String, dynamic>>> rattachements(String enfantId);
  Future<List<Map<String, dynamic>>> notes(String enfantId);
  Future<List<Map<String, dynamic>>> journal(String enfantId);
  Future<List<Map<String, dynamic>>> personnesDeConfiance(
    String enfantId,
  );

  Future<List<Map<String, dynamic>>> activitesPreparees(
    String compteId,
  );
}

/// Levée quand l'export ne peut pas être produit **complet**. Jamais
/// remplacée par un export partiel : un document intitulé « copie
/// complète de vos données » qui n'est pas complet vaut moins que pas
/// de document du tout.
class ExportImpossible implements Exception {
  final String message;

  const ExportImpossible(this.message);

  @override
  String toString() => message;
}

/// Rassemble tout ce que l'application détient sur le compte connecté
/// et sur **ses** enfants.
///
/// La règle de cloisonnement tient en une ligne, et c'est la plus
/// importante du fichier : un enfant n'est exporté que si son
/// `parent_id` est celui du compte connecté.
///
/// Elle est nécessaire parce que `enfants` renvoie aussi, par le RLS,
/// les enfants sur lesquels le compte est personne de confiance (voir
/// `ChildRepository.loadFromSupabase`). Exporter la liste telle quelle
/// mettrait l'enfant d'une autre famille dans le document.
Future<DonneesExport> collecterExport(
  SourceExport source,
  DateTime maintenant,
) async {
  final compteId = source.identifiantCompte;

  if (compteId == null) {
    throw const ExportImpossible(
      'Aucun compte connecté : impossible de savoir quelles données '
      'exporter.',
    );
  }

  final visibles = await source.enfantsVisibles();

  final miens = visibles
      .where((ligne) => ligne['parent_id'] == compteId)
      .toList();

  final enfants = <EnfantExporte>[];

  for (final ligne in miens) {
    final enfantId = ligne['id'] as String?;

    if (enfantId == null) {
      continue;
    }

    enfants.add(
      EnfantExporte(
        enfantId: enfantId,
        enfant: ligne,
        profilSante: await source.profilSante(enfantId),
        profilActivites: await source.profilActivites(enfantId),
        partages: await source.partages(enfantId),
        rattachementsEtablissement:
            await source.rattachements(enfantId),
        notesProfessionnelles: await source.notes(enfantId),
        journalConsultations: await source.journal(enfantId),
        personnesDeConfiance:
            await source.personnesDeConfiance(enfantId),
      ),
    );
  }

  return DonneesExport(
    compte: CompteExporte(
      id: compteId,
      email: source.emailCompte,
      detailsCompte: await source.compteParent(compteId),
    ),
    enfants: enfants,
    activitesPreparees: await source.activitesPreparees(compteId),
    exporteLe: maintenant,
  );
}

/// Le compte possède-t-il au moins un enfant ?
///
/// Décide de l'affichage du bouton. Une personne de confiance « pure »
/// n'en possède aucun : la fonction ne lui est pas proposée. Un compte
/// qui est à la fois parent et personne de confiance l'a, et n'exporte
/// que ses enfants.
bool possedeAuMoinsUnEnfant(
  List<Map<String, dynamic>> enfantsVisibles,
  String? compteId,
) {
  if (compteId == null) {
    return false;
  }

  return enfantsVisibles.any(
    (ligne) => ligne['parent_id'] == compteId,
  );
}

/// Implémentation Supabase. Tout ce qui sait qu'on parle à Supabase est
/// ici ; la règle de cloisonnement, elle, n'en sait rien.
///
/// Les lectures ne sont pas filtrées côté client au-delà de
/// `enfant_id` : le RLS filtre déjà, et [collecterExport] refiltre les
/// enfants. Doubler un filtre déjà appliqué donnerait l'illusion d'une
/// garantie supplémentaire là où il n'y en a pas.
class SourceExportSupabase implements SourceExport {
  const SourceExportSupabase();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  String? get identifiantCompte =>
      SupabaseAuthProvider.instance.currentUserId;

  @override
  String? get emailCompte =>
      SupabaseAuthProvider.instance.currentUserEmail;

  Future<List<Map<String, dynamic>>> _lignes(
    Future<dynamic> Function() requete,
  ) async {
    final resultat = await requete();

    return (resultat as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> compteParent(String compteId) async {
    return await _client
        .from('comptes_parents')
        .select()
        .eq('id', compteId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> enfantsVisibles() {
    return _lignes(() => _client.from('enfants').select());
  }

  @override
  Future<Map<String, dynamic>?> profilSante(String enfantId) async {
    return await _client
        .from('profils_sante')
        .select()
        .eq('enfant_id', enfantId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> profilActivites(
    String enfantId,
  ) async {
    return await _client
        .from('profils_activites')
        .select()
        .eq('enfant_id', enfantId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> partages(String enfantId) {
    return _lignes(
      () => _client
          .from('partages')
          .select()
          .eq('enfant_id', enfantId)
          .order('date_creation', ascending: false),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rattachements(String enfantId) {
    return _lignes(
      () => _client
          .from('enfants_etablissements')
          .select('*, etablissements(nom)')
          .eq('enfant_id', enfantId)
          .order('date_creation', ascending: false),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> notes(String enfantId) {
    return _lignes(
      () => _client
          .from('notes_activite')
          .select()
          .eq('enfant_id', enfantId)
          .order('cree_le', ascending: false),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> journal(String enfantId) {
    return _lignes(
      () => _client
          .from('journal_consultations_fiche')
          .select('*, etablissements(nom)')
          .eq('enfant_id', enfantId)
          .order('consulte_le', ascending: false),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> personnesDeConfiance(
    String enfantId,
  ) {
    return _lignes(
      () => _client
          .from('enfants_confiance')
          .select()
          .eq('enfant_id', enfantId)
          .order('invite_le', ascending: false),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> activitesPreparees(
    String compteId,
  ) {
    return _lignes(
      () => _client
          .from('activites_preparees')
          .select()
          .eq('parent_id', compteId)
          .order('cree_le', ascending: false),
    );
  }
}
