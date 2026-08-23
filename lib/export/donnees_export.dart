/// Ce que l'application détient sur un parent et sur ses enfants, tel
/// qu'il sera remis à ce parent au titre du droit d'accès (RGPD,
/// article 15).
///
/// Volontairement composé des **lignes brutes** de la base plutôt que
/// des modèles métier de l'application : un droit d'accès porte sur ce
/// qui est stocké, pas sur une relecture qu'en ferait l'application.
/// Une donnée que l'app n'affiche nulle part doit quand même sortir
/// ici. Le PDF, lui, reconstruit des objets lisibles à partir de ces
/// mêmes lignes.
///
/// Aucun accès réseau, aucun accès base : ce fichier ne fait que
/// décrire. La collecte est dans `source_export.dart`.
library;

class DonneesExport {
  /// Change quand la structure du fichier de données change, pour
  /// qu'un outil qui le relit des années plus tard sache à quoi il a
  /// affaire.
  static const int versionFormat = 1;

  final CompteExporte compte;
  final List<EnfantExporte> enfants;

  /// Activités préparées par le parent lui-même. Celles préparées par
  /// un établissement ressortent, elles, dans les notes de chaque
  /// enfant.
  final List<Map<String, dynamic>> activitesPreparees;

  final DateTime exporteLe;

  const DonneesExport({
    required this.compte,
    required this.enfants,
    required this.activitesPreparees,
    required this.exporteLe,
  });

  bool get estVide => enfants.isEmpty && activitesPreparees.isEmpty;
}

class CompteExporte {
  final String id;
  final String? email;

  /// Ligne `comptes_parents` : adresse de secours, etat d'une demande
  /// de suppression. Nulle si le compte n'en a pas encore.
  final Map<String, dynamic>? detailsCompte;

  const CompteExporte({
    required this.id,
    required this.email,
    this.detailsCompte,
  });
}

/// Tout ce qui est rattaché à un enfant. Les listes sont vides plutôt
/// que nulles : un export doit pouvoir dire « rien » sans ambiguïté.
class EnfantExporte {
  final String enfantId;

  /// Ligne de la table `enfants`.
  final Map<String, dynamic> enfant;

  final Map<String, dynamic>? profilSante;
  final Map<String, dynamic>? profilActivites;

  final List<Map<String, dynamic>> partages;
  final List<Map<String, dynamic>> rattachementsEtablissement;
  final List<Map<String, dynamic>> notesProfessionnelles;
  final List<Map<String, dynamic>> journalConsultations;
  final List<Map<String, dynamic>> personnesDeConfiance;

  const EnfantExporte({
    required this.enfantId,
    required this.enfant,
    required this.profilSante,
    required this.profilActivites,
    this.partages = const [],
    this.rattachementsEtablissement = const [],
    this.notesProfessionnelles = const [],
    this.journalConsultations = const [],
    this.personnesDeConfiance = const [],
  });

  String get prenomOuDefaut {
    final prenom = (enfant['prenom'] as String?)?.trim();

    return prenom == null || prenom.isEmpty ? 'Enfant' : prenom;
  }

  String get nomComplet {
    final parties = [enfant['prenom'], enfant['nom']]
        .map((valeur) => (valeur as String?)?.trim())
        .where((valeur) => valeur != null && valeur.isNotEmpty)
        .cast<String>();

    final nom = parties.join(' ');

    return nom.isEmpty ? 'Enfant' : nom;
  }
}
