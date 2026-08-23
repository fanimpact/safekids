import 'package:kidsrelay/export/source_export.dart';

/// Double de [SourceExport] : décrit l'état de la base sans base.
///
/// Enregistre les identifiants d'enfant pour lesquels chaque rubrique a
/// été demandée : c'est ce qui permet de prouver qu'aucune donnée n'est
/// **lue** pour un enfant qui ne doit pas sortir, et pas seulement
/// qu'elle n'est pas écrite dans le document final.
class FakeSourceExport implements SourceExport {
  @override
  final String? identifiantCompte;

  @override
  final String? emailCompte;

  final List<Map<String, dynamic>> lignesEnfants;
  final Map<String, Map<String, dynamic>> sante;
  final Map<String, Map<String, dynamic>> activites;
  final Map<String, List<Map<String, dynamic>>> lignesPartages;
  final Map<String, List<Map<String, dynamic>>> lignesRattachements;
  final Map<String, List<Map<String, dynamic>>> lignesNotes;
  final Map<String, List<Map<String, dynamic>>> lignesJournal;
  final Map<String, List<Map<String, dynamic>>> lignesConfiance;
  final List<Map<String, dynamic>> lignesActivitesPreparees;

  /// Chaque `(rubrique, enfantId)` demandé, dans l'ordre.
  final List<String> lectures = [];

  FakeSourceExport({
    this.identifiantCompte = 'parent-1',
    this.emailCompte = 'parent@exemple.fr',
    this.lignesEnfants = const [],
    this.sante = const {},
    this.activites = const {},
    this.lignesPartages = const {},
    this.lignesRattachements = const {},
    this.lignesNotes = const {},
    this.lignesJournal = const {},
    this.lignesConfiance = const {},
    this.lignesActivitesPreparees = const [],
  });

  void _noter(String rubrique, String enfantId) {
    lectures.add('$rubrique:$enfantId');
  }

  @override
  Future<List<Map<String, dynamic>>> enfantsVisibles() async {
    lectures.add('enfantsVisibles');
    return lignesEnfants;
  }

  @override
  Future<Map<String, dynamic>?> profilSante(String enfantId) async {
    _noter('sante', enfantId);
    return sante[enfantId];
  }

  @override
  Future<Map<String, dynamic>?> profilActivites(
    String enfantId,
  ) async {
    _noter('activites', enfantId);
    return activites[enfantId];
  }

  @override
  Future<List<Map<String, dynamic>>> partages(String enfantId) async {
    _noter('partages', enfantId);
    return lignesPartages[enfantId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> rattachements(
    String enfantId,
  ) async {
    _noter('rattachements', enfantId);
    return lignesRattachements[enfantId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> notes(String enfantId) async {
    _noter('notes', enfantId);
    return lignesNotes[enfantId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> journal(String enfantId) async {
    _noter('journal', enfantId);
    return lignesJournal[enfantId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> personnesDeConfiance(
    String enfantId,
  ) async {
    _noter('confiance', enfantId);
    return lignesConfiance[enfantId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> activitesPreparees(
    String compteId,
  ) async {
    lectures.add('activitesPreparees:$compteId');
    return lignesActivitesPreparees;
  }
}
