/// Traduction des noms de colonnes et de champs en intitulés lisibles,
/// et mise en forme des valeurs, pour le PDF de l'export.
///
/// Fonctions pures, sans dépendance : c'est ce qui rend le rendu du
/// PDF testable sans générer de PDF.
///
/// Le dictionnaire ci-dessous est **volontairement incomplet** : ce
/// n'est pas une liste blanche. Une colonne qui n'y figure pas sort
/// quand même, avec un intitulé fabriqué à partir de son nom technique
/// (voir [libelleChamp]). Un champ ajouté plus tard apparaîtra donc
/// tout seul dans l'export, au pire avec un intitulé maladroit —
/// jamais absent. Sur un document qui prétend être complet, une
/// omission silencieuse est le pire des défauts.
library;

const Map<String, String> _libelles = {
  // Identité
  'prenom': 'Prénom',
  'nom': 'Nom',
  'date_naissance': 'Date de naissance',
  'poids': 'Poids (kg)',
  'taille': 'Taille (cm)',
  'date_maj_poids': 'Mesures relevées le',
  'sexe': 'Sexe',

  // Santé
  'pathologies': 'Pathologies',
  'allergies': 'Allergies',
  'traitements_urgence': 'Traitements d’urgence',
  'traitements_reguliers': 'Traitements réguliers',
  'traitements_arretes': 'Traitements arrêtés',
  'dispositifs_medicaux': 'Dispositifs médicaux',
  'medecin_traitant': 'Médecin traitant',
  'facteurs_declenchants': 'Facteurs déclenchants',
  'contacts_urgence': 'Contacts à prévenir',
  'evenements_medicaux': 'Antécédents médicaux',
  'observations_medicales': 'Observations médicales',

  // Champs des sous-objets de santé
  'name': 'Nom',
  'allergen': 'Allergène',
  'observedReaction': 'Réaction observée',
  'medicationName': 'Médicament',
  'dosage': 'Dosage',
  'administrationTimes': 'Moments d’administration',
  'deviceName': 'Dispositif',
  'mainUse': 'Usage principal',
  'emergencyInstructionSteps': 'Consignes d’urgence',
  'approximateDiagnosisDate': 'Diagnostiquée vers',
  'approximateDate': 'Date approximative',
  'fullName': 'Nom complet',
  'relationship': 'Lien avec l’enfant',
  'phoneNumber': 'Téléphone',
  'workplace': 'Lieu d’exercice',
  'speciality': 'Spécialité',
  'description': 'Description',
  'categories': 'Catégories',

  // Activités
  'repas': 'Repas',
  'transport': 'Transport',
  'habillage': 'Habillage',
  'toilettes': 'Toilettes',
  'communication': 'Communication',
  'transitions': 'Transitions',
  'nuit': 'Nuit hors du domicile',
  'securite': 'Sécurité',
  'activites_aquatiques': 'Activités aquatiques',
  'effort_marche': 'Marche et effort',
  'autres_informations': 'Autres informations',
  'nom_activite': 'Nom de l’activité',
  'date_activite': 'Date de l’activité',
  'lieu': 'Lieu',
  'enfants_ids': 'Enfants concernés',

  // Partages et rattachements
  'type_fiche': 'Type de fiche',
  'destinataire': 'Destinataire',
  'date_creation': 'Créé le',
  'date_expiration': 'Expire le',
  'date_derniere_consultation': 'Dernière consultation',
  'statut': 'Statut',
  'etablissements': 'Établissement',
  'consulte_le': 'Consulté le',
  'contenu_fige': 'Contenu figé au moment du partage',

  // Notes et personnes de confiance
  'note': 'Note',
  'cree_le': 'Créé le',
  'email': 'Adresse email',
  'niveau_acces': 'Niveau d’accès',
  'invite_le': 'Invitée le',
  'accepte_le': 'Acceptée le',
  'revoque_le': 'Révoquée le',
  'token': 'Jeton',
};

const Map<String, String> _valeurs = {
  'secours': 'Fiche secours',
  'ce_qu_il_faut_savoir': 'Ce qu’il faut savoir',
  'recommandations_activite': 'Recommandations d’activité',
  'structure_accueil': 'Structure d’accueil',
  'particulier': 'Particulier',
  'lecture': 'Consultation seule',
  'lecture_ecriture': 'Consultation et modification',
  'actif': 'Actif',
  'invite': 'Invitée, en attente',
  'revoque': 'Révoquée',
  'en_attente': 'En attente',
  'note_ajoutee': 'Note ajoutée',
  'envoye': 'Envoyé',
  'echoue': 'Échoué',
};

/// Intitulé d'un champ. Repli sur le nom technique rendu présentable :
/// mieux vaut « Nombre repas » que rien du tout.
String libelleChamp(String cle) {
  final connu = _libelles[cle];

  if (connu != null) {
    return connu;
  }

  final mots = cle
      .replaceAll(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), '_')
      .split('_')
      .where((mot) => mot.isNotEmpty)
      .toList();

  if (mots.isEmpty) {
    return cle;
  }

  final premier = mots.first.toLowerCase();

  return [
    premier[0].toUpperCase() + premier.substring(1),
    ...mots.skip(1).map((mot) => mot.toLowerCase()),
  ].join(' ');
}

/// Un champ « vide » n'est pas imprimé dans le PDF. `false` en fait
/// partie **volontairement pas** : « ne sait pas nager : non » est une
/// information, pas une absence d'information.
bool estVide(dynamic valeur) {
  if (valeur == null) {
    return true;
  }

  if (valeur is String) {
    return valeur.trim().isEmpty;
  }

  if (valeur is Iterable) {
    return valeur.every(estVide);
  }

  if (valeur is Map) {
    return valeur.values.every(estVide);
  }

  return false;
}

String formaterDate(DateTime date) {
  final jour = date.day.toString().padLeft(2, '0');
  final mois = date.month.toString().padLeft(2, '0');

  return '$jour/$mois/${date.year}';
}

String formaterDateHeure(DateTime date) {
  final heure = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${formaterDate(date)} à ${heure}h$minute';
}

/// Valeur telle qu'elle doit se lire. Les dates ISO deviennent des
/// dates françaises, les booléens des Oui/Non, les codes internes leur
/// libellé — un parent ne doit pas avoir à deviner ce que veut dire
/// `structure_accueil`.
String valeurLisible(dynamic valeur) {
  if (valeur is bool) {
    return valeur ? 'Oui' : 'Non';
  }

  if (valeur is String) {
    final connue = _valeurs[valeur];

    if (connue != null) {
      return connue;
    }

    final date = DateTime.tryParse(valeur);

    if (date != null && _ressembleAUneDate(valeur)) {
      return valeur.length == 10
          ? formaterDate(date)
          : formaterDateHeure(date.toLocal());
    }

    return valeur;
  }

  return valeur.toString();
}

/// `DateTime.tryParse` accepte « 2024 » et le lit comme une année :
/// une pathologie « diagnostiquée vers 2024 » deviendrait
/// « 01/01/2024 », plus précis que ce que le parent a écrit. On
/// n'accepte donc que les formes complètes.
bool _ressembleAUneDate(String valeur) {
  return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(valeur);
}
