import 'donnees_export.dart';
import 'export_json.dart';
import 'export_libelles.dart';

/// Le contenu du document lisible, sous forme de texte — avant toute
/// mise en page.
///
/// Séparé du PDF pour une raison précise : dans un PDF, le texte est
/// écrit en identifiants de glyphes de la police embarquée, pas en
/// clair. On ne peut donc pas relire un PDF produit pour vérifier ce
/// qu'il contient. Un test qui essaierait passerait toujours, y compris
/// sur un document qui divulgue un jeton de partage.
///
/// Ici, tout est du texte : ce que le document dira est vérifiable
/// ligne par ligne.
///
/// Le rendu est **générique** : il parcourt les lignes de la base
/// plutôt que de dérouler une liste de champs écrite à la main. Un
/// rendu écrit à la main oublie silencieusement toute colonne ajoutée
/// après lui — sur un document qui prétend être complet, c'est le pire
/// des défauts. Ici, une colonne nouvelle sort toute seule, au pire
/// avec un intitulé approximatif (voir `export_libelles.dart`).

enum StyleBloc { titreDocument, titreSection, sousTitre, ligne, puce }

class BlocExport {
  final StyleBloc style;
  final String texte;

  /// Retrait, pour les objets imbriqués (médecin traitant, facteurs
  /// déclenchants) et les listes d'objets (pathologies, allergies).
  final int profondeur;

  const BlocExport(
    this.style,
    this.texte, {
    this.profondeur = 0,
  });
}

/// Colonnes retirées du document lisible : identifiants techniques,
/// sans valeur pour un lecteur humain, et présents dans le fichier de
/// données.
const Set<String> clesTechniques = {
  'id',
  'enfant_id',
  'parent_id',
  'activite_id',
  'etablissement_id',
  'auteur_id',
  'user_id',
  'membre_id',
  'partage_id',
};

/// Le document, page par page. Chaque liste intérieure démarre sur une
/// nouvelle page : sur un export de plusieurs enfants, deux fiches qui
/// se suivent sur la même page se confondent.
List<List<BlocExport>> pagesExport(DonneesExport donnees) {
  return [
    _pagePresentation(donnees),
    ...donnees.enfants.map(_pageEnfant),
    if (donnees.activitesPreparees.isNotEmpty)
      [
        const BlocExport(
          StyleBloc.titreDocument,
          'Activités que vous avez préparées',
        ),
        ..._listeDeLignes(donnees.activitesPreparees),
      ],
  ];
}

List<BlocExport> _pagePresentation(DonneesExport donnees) {
  return [
    const BlocExport(StyleBloc.titreDocument, 'Vos données KidsRelay'),

    const BlocExport(
      StyleBloc.ligne,
      'Ce document rassemble ce que l’application KidsRelay détient '
      'sur votre compte et sur vos enfants, au titre du droit d’accès '
      '(RGPD, article 15).',
    ),

    BlocExport(
      StyleBloc.ligne,
      'Établi le ${formaterDateHeure(donnees.exporteLe)} pour '
      '${donnees.compte.email ?? 'votre compte'}.',
    ),

    const BlocExport(
      StyleBloc.titreSection,
      'Ce que contient ce document',
    ),

    if (donnees.enfants.isEmpty)
      const BlocExport(
        StyleBloc.puce,
        'Aucun enfant n’est rattaché à ce compte : il n’y a donc '
        'aucune fiche d’enfant à présenter.',
      ),

    for (final enfant in donnees.enfants)
      BlocExport(
        StyleBloc.puce,
        '${enfant.nomComplet} — profil de santé, profil activités, '
        'partages, rattachements, notes, consultations, personnes de '
        'confiance',
      ),

    if (donnees.activitesPreparees.isNotEmpty)
      BlocExport(
        StyleBloc.puce,
        donnees.activitesPreparees.length > 1
            ? '${donnees.activitesPreparees.length} activités préparées '
                'par vos soins'
            : '1 activité préparée par vos soins',
      ),

    const BlocExport(
      StyleBloc.titreSection,
      'À savoir sur ce document',
    ),

    const BlocExport(
      StyleBloc.puce,
      'Seuls les champs que vous avez renseignés apparaissent ici. Les '
      'champs laissés vides ne sont pas imprimés, pour que ce qui est '
      'renseigné reste lisible.',
    ),
    const BlocExport(
      StyleBloc.puce,
      'Les identifiants techniques ne sont pas imprimés : ils ne '
      'veulent rien dire pour un lecteur.',
    ),
    const BlocExport(
      StyleBloc.puce,
      'Le fichier de données joint à ce PDF, lui, contient tout, y '
      'compris les champs vides et les identifiants.',
    ),
    const BlocExport(
      StyleBloc.puce,
      'Les jetons de partage et de rattachement ont été retirés des '
      'deux fichiers : ce sont des clés d’accès aux fiches de vos '
      'enfants, et ce document est fait pour être transmis. Les '
      'partages eux-mêmes y figurent.',
    ),
    const BlocExport(
      StyleBloc.puce,
      'Aucune donnée d’un enfant dont vous n’êtes pas le parent ne '
      'figure ici, y compris si vous êtes personne de confiance sur la '
      'fiche d’un autre enfant.',
    ),
  ];
}

List<BlocExport> _pageEnfant(EnfantExporte enfant) {
  return [
    BlocExport(StyleBloc.titreDocument, enfant.nomComplet),

    ..._rubrique('Identité', [enfant.enfant]),
    ..._rubrique(
      'Profil de santé',
      enfant.profilSante == null ? const [] : [enfant.profilSante!],
    ),
    ..._rubrique(
      'Profil activités',
      enfant.profilActivites == null
          ? const []
          : [enfant.profilActivites!],
    ),
    ..._rubrique('Liens de partage', enfant.partages),
    ..._rubrique(
      'Rattachements à un établissement',
      enfant.rattachementsEtablissement,
    ),
    ..._rubrique(
      'Notes ajoutées par un professionnel',
      enfant.notesProfessionnelles,
    ),
    ..._rubrique(
      'Consultations de la fiche',
      enfant.journalConsultations,
    ),
    ..._rubrique('Personnes de confiance', enfant.personnesDeConfiance),
  ];
}

/// Une rubrique vide est **affichée** comme vide plutôt qu'omise : sur
/// un document qui prouve ce qui est détenu, « aucun partage » est une
/// information, et son absence pourrait passer pour un oubli.
List<BlocExport> _rubrique(
  String titre,
  List<Map<String, dynamic>> lignes,
) {
  return [
    BlocExport(StyleBloc.titreSection, titre),
    if (lignes.isEmpty)
      const BlocExport(StyleBloc.puce, 'Aucune donnée enregistrée.')
    else
      ..._listeDeLignes(lignes),
  ];
}

List<BlocExport> _listeDeLignes(List<Map<String, dynamic>> lignes) {
  final blocs = <BlocExport>[];

  for (var index = 0; index < lignes.length; index++) {
    if (lignes.length > 1) {
      blocs.add(BlocExport(StyleBloc.sousTitre, '${index + 1}.'));
    }

    // Les jetons sont neutralisés ici comme dans le fichier de
    // données : ce sont des clés d'accès, et ce document est fait pour
    // être transmis.
    final contenu = _champs(ligneSansJeton(lignes[index]), 0);

    blocs.addAll(
      contenu.isEmpty
          ? [
              const BlocExport(
                StyleBloc.ligne,
                'Aucune information renseignée.',
              ),
            ]
          : contenu,
    );
  }

  return blocs;
}

List<BlocExport> _champs(dynamic valeur, int profondeur) {
  final blocs = <BlocExport>[];

  if (valeur is Map) {
    valeur.forEach((cle, contenu) {
      final nom = cle.toString();

      if (clesTechniques.contains(nom) || estVide(contenu)) {
        return;
      }

      if (contenu is Map || contenu is List) {
        blocs.add(
          BlocExport(
            StyleBloc.sousTitre,
            libelleChamp(nom),
            profondeur: profondeur,
          ),
        );
        blocs.addAll(_champs(contenu, profondeur + 1));
      } else {
        blocs.add(
          BlocExport(
            StyleBloc.ligne,
            '${libelleChamp(nom)} : ${valeurLisible(contenu)}',
            profondeur: profondeur,
          ),
        );
      }
    });

    return blocs;
  }

  if (valeur is List) {
    for (final element in valeur) {
      if (estVide(element)) {
        continue;
      }

      if (element is Map || element is List) {
        blocs.addAll(_champs(element, profondeur));
      } else {
        blocs.add(
          BlocExport(
            StyleBloc.ligne,
            valeurLisible(element),
            profondeur: profondeur,
          ),
        );
      }
    }

    return blocs;
  }

  return [
    BlocExport(
      StyleBloc.ligne,
      valeurLisible(valeur),
      profondeur: profondeur,
    ),
  ];
}
