import 'dart:convert';

import 'donnees_export.dart';

/// Le fichier de données réutilisable de l'export.
///
/// Fonctions pures : elles prennent un [DonneesExport] et rendent du
/// texte. Aucun accès réseau, aucun accès base, aucune lecture de
/// l'horloge — la date d'export vient du modèle.

/// Jetons remplacés plutôt qu'exportés.
///
/// Un jeton de partage ou de rattachement est une **clé d'accès** : qui
/// l'a peut ouvrir la fiche de l'enfant sans se connecter. Or ce
/// fichier est fait pour être transmis — à un médecin, à un
/// établissement, à qui le parent veut. Y laisser les jetons actifs
/// reviendrait à distribuer les clés en même temps que le dossier.
///
/// Ce que le droit d'accès demande, c'est de savoir **qu'un partage
/// existe** : quand, vers qui, jusqu'à quand, et s'il a été consulté.
/// Tout cela reste dans l'export. Seule la clé est retirée.
const String jetonRetire = '[retiré de l’export — voir _lisez_moi]';

const List<String> _clesJeton = ['token', 'jeton', 'jeton_hash'];

const String _lisezMoi =
    'Export de vos données KidsRelay, au titre du droit d’accès '
    '(RGPD, article 15). Ce fichier contient tout ce que '
    'l’application détient sur votre compte et sur vos enfants, tel '
    'que stocké. Il est accompagné d’un PDF qui présente les mêmes '
    'informations sous une forme lisible. '
    'Les jetons de partage et de rattachement ont été remplacés par '
    'une mention : ce sont des clés d’accès aux fiches de vos '
    'enfants, et ce fichier est fait pour être transmis. Les partages '
    'eux-mêmes (date, destinataire, expiration, consultations) sont '
    'bien présents. '
    'Aucune donnée d’un enfant dont vous n’êtes pas le parent ne '
    'figure ici, y compris si vous êtes personne de confiance sur la '
    'fiche d’un autre enfant.';

/// Recopie une ligne en neutralisant les jetons qu'elle contient.
Map<String, dynamic> ligneSansJeton(Map<String, dynamic> ligne) {
  final copie = <String, dynamic>{};

  ligne.forEach((cle, valeur) {
    copie[cle] = _clesJeton.contains(cle) && valeur != null
        ? jetonRetire
        : valeur;
  });

  return copie;
}

List<Map<String, dynamic>> _lignesSansJeton(
  List<Map<String, dynamic>> lignes,
) {
  return lignes.map(ligneSansJeton).toList();
}

Map<String, dynamic> construireExportJson(DonneesExport donnees) {
  return {
    '_lisez_moi': _lisezMoi,
    'format': 'kidsrelay-export-donnees',
    'version_format': DonneesExport.versionFormat,
    'exporte_le': donnees.exporteLe.toIso8601String(),
    'compte': {
      'id': donnees.compte.id,
      'email': donnees.compte.email,
      'details': donnees.compte.detailsCompte == null
          ? null
          : ligneSansJeton(donnees.compte.detailsCompte!),
    },
    'enfants': donnees.enfants.map(_enfantEnJson).toList(),
    'activites_preparees':
        _lignesSansJeton(donnees.activitesPreparees),
  };
}

Map<String, dynamic> _enfantEnJson(EnfantExporte enfant) {
  return {
    'enfant': ligneSansJeton(enfant.enfant),
    'profil_sante': enfant.profilSante == null
        ? null
        : ligneSansJeton(enfant.profilSante!),
    'profil_activites': enfant.profilActivites == null
        ? null
        : ligneSansJeton(enfant.profilActivites!),
    'partages': _lignesSansJeton(enfant.partages),
    'rattachements_etablissement':
        _lignesSansJeton(enfant.rattachementsEtablissement),
    'notes_professionnelles':
        _lignesSansJeton(enfant.notesProfessionnelles),
    'journal_consultations':
        _lignesSansJeton(enfant.journalConsultations),
    'personnes_de_confiance':
        _lignesSansJeton(enfant.personnesDeConfiance),
  };
}

/// Indenté volontairement : le fichier doit s'ouvrir dans un éditeur
/// de texte ordinaire et rester lisible. Le poids gagné en le
/// compactant ne vaut rien face à un parent qui veut le relire.
String encoderExportJson(DonneesExport donnees) {
  return const JsonEncoder.withIndent('  ')
      .convert(construireExportJson(donnees));
}

/// Nom des deux fichiers produits, sans extension. Daté, pour qu'un
/// parent qui exporte deux fois ne se retrouve pas avec deux fichiers
/// de même nom.
String nomFichierExport(DateTime exporteLe) {
  final annee = exporteLe.year.toString().padLeft(4, '0');
  final mois = exporteLe.month.toString().padLeft(2, '0');
  final jour = exporteLe.day.toString().padLeft(2, '0');

  return 'kidsrelay-mes-donnees-$annee-$mois-$jour';
}
