import '../models/activity_profile_draft.dart';
import '../models/child_profile_data.dart';
import '../models/child_profile_draft.dart';
import '../repositories/child_profile_codec.dart';

/// Un questionnaire commencé et pas terminé.
///
/// Jusqu'au 25/08/2026, rien n'était écrit avant la dernière page : le
/// profil de santé après le sixième écran, le profil Activités après le
/// onzième. Un parent interrompu au milieu perdait tout — onze sections
/// sur les repas, les toilettes, la nuitée, à refaire.
///
/// Ce fichier ne fait que décrire et convertir. Il ne touche ni au
/// disque ni au réseau : c'est `BrouillonRepository` qui range, et la
/// règle de péremption comme les conversions se testent sans rien.

/// Un brouillon dort au plus 30 jours.
///
/// Ce n'est pas une commodité technique : un questionnaire de santé
/// abandonné contient des pathologies, des allergies et des
/// traitements. Ces données n'ont aucune raison de rester
/// indéfiniment sur un téléphone parce que quelqu'un a été interrompu.
const Duration dureeVieBrouillon = Duration(days: 30);

enum TypeBrouillon { sante, activites }

TypeBrouillon _typeDepuisTexte(String valeur) {
  return valeur == 'activites'
      ? TypeBrouillon.activites
      : TypeBrouillon.sante;
}

String texteDepuisType(TypeBrouillon type) {
  return type == TypeBrouillon.activites ? 'activites' : 'sante';
}

class BrouillonProfil {
  final TypeBrouillon type;

  /// L'identifiant est généré dès le premier écran par
  /// `ChildProfileDraft` : un brouillon a donc une identité stable
  /// avant même que l'enfant existe en base.
  final String childId;

  /// Pour l'annoncer au parent. Nul tant qu'il n'a pas saisi le prénom
  /// — c'est le tout premier champ du tout premier écran, donc ce cas
  /// ne dure pas.
  final String? prenom;

  final DateTime commenceLe;
  final DateTime modifieLe;

  /// Les lignes telles qu'elles partiraient en base, réutilisées comme
  /// format de stockage : `ChildProfileCodec` sait déjà les écrire et
  /// les relire, et le cache hors-ligne s'en sert depuis toujours.
  final Map<String, dynamic> contenu;

  const BrouillonProfil({
    required this.type,
    required this.childId,
    required this.prenom,
    required this.commenceLe,
    required this.modifieLe,
    required this.contenu,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': texteDepuisType(type),
      'childId': childId,
      'prenom': prenom,
      'commenceLe': commenceLe.toIso8601String(),
      'modifieLe': modifieLe.toIso8601String(),
      'contenu': contenu,
    };
  }

  /// `null` si la ligne est illisible — un brouillon corrompu se jette,
  /// il ne fait pas échouer le chargement des autres.
  static BrouillonProfil? fromJson(Map<String, dynamic> json) {
    final childId = json['childId'];
    final commence = DateTime.tryParse(
      json['commenceLe'] as String? ?? '',
    );
    final modifie = DateTime.tryParse(
      json['modifieLe'] as String? ?? '',
    );
    final contenu = json['contenu'];

    if (childId is! String ||
        childId.isEmpty ||
        commence == null ||
        modifie == null ||
        contenu is! Map) {
      return null;
    }

    return BrouillonProfil(
      type: _typeDepuisTexte(json['type'] as String? ?? 'sante'),
      childId: childId,
      prenom: json['prenom'] as String?,
      commenceLe: commence,
      modifieLe: modifie,
      contenu: Map<String, dynamic>.from(contenu),
    );
  }
}

/// Un brouillon qui dort depuis plus de [dureeVieBrouillon].
bool brouillonPerime(BrouillonProfil brouillon, DateTime maintenant) {
  return maintenant.difference(brouillon.modifieLe) >
      dureeVieBrouillon;
}

List<BrouillonProfil> sansPerimes(
  List<BrouillonProfil> brouillons,
  DateTime maintenant,
) {
  return brouillons
      .where((brouillon) => !brouillonPerime(brouillon, maintenant))
      .toList();
}

// --- Questionnaire santé ---------------------------------------------

BrouillonProfil brouillonDepuisSante(
  ChildProfileDraft draft, {
  required DateTime commenceLe,
  required DateTime modifieLe,
}) {
  final profil = ChildProfileData.fromDraft(draft);
  final prenom = draft.identity.firstName?.trim();

  return BrouillonProfil(
    type: TypeBrouillon.sante,
    childId: draft.childId,
    prenom: prenom == null || prenom.isEmpty ? null : prenom,
    commenceLe: commenceLe,
    modifieLe: modifieLe,
    contenu: {
      // `parent_id` vide : un brouillon n'appartient à personne en
      // base, il ne quitte pas l'appareil.
      'enfant': ChildProfileCodec.enfantRow(profil, ''),
      'sante': ChildProfileCodec.santeRow(draft.childId, profil),
    },
  );
}

ChildProfileDraft? santeDepuisBrouillon(BrouillonProfil brouillon) {
  final enfant = brouillon.contenu['enfant'];
  final sante = brouillon.contenu['sante'];

  if (enfant is! Map) {
    return null;
  }

  return ChildProfileDraft.fromChildProfileData(
    ChildProfileCodec.childProfileFromRows(
      childId: brouillon.childId,
      enfant: Map<String, dynamic>.from(enfant),
      sante: sante is Map ? Map<String, dynamic>.from(sante) : null,
    ),
  );
}

// --- Profil Activités -------------------------------------------------

BrouillonProfil brouillonDepuisActivites(
  ActivityProfileDraft draft, {
  required String childId,
  required String? prenom,
  required DateTime commenceLe,
  required DateTime modifieLe,
}) {
  return BrouillonProfil(
    type: TypeBrouillon.activites,
    childId: childId,
    prenom: prenom,
    commenceLe: commenceLe,
    modifieLe: modifieLe,
    contenu: {
      'activites': ChildProfileCodec.activitesRow(
        childId,
        draft.toProfile(),
      ),
    },
  );
}

ActivityProfileDraft? activitesDepuisBrouillon(
  BrouillonProfil brouillon, {
  String? userId,
}) {
  final activites = brouillon.contenu['activites'];

  if (activites is! Map) {
    return null;
  }

  final profil = ChildProfileCodec.activityProfileFromRow(
    Map<String, dynamic>.from(activites),
  );

  if (profil == null) {
    return null;
  }

  return ActivityProfileDraft.fromActivityProfileData(
    profil,
    userId: userId,
    childId: brouillon.childId,
  );
}

/// Ce que le parent lit dans « Mes enfants ».
///
/// Volontairement explicite sur le fait qu'il s'agit d'une reprise :
/// une reprise silencieuse laisserait croire à un profil complet, et le
/// parent ne saurait pas qu'il lui reste des écrans à remplir.
String libelleReprise(BrouillonProfil brouillon) {
  final quoi = brouillon.type == TypeBrouillon.sante
      ? 'le profil'
      : 'le profil Activités';

  final qui = brouillon.prenom == null
      ? ''
      : ' de ${brouillon.prenom}';

  return 'Reprendre $quoi$qui, commencé le '
      '${_dateCourte(brouillon.commenceLe)}';
}

String _dateCourte(DateTime date) {
  final jour = date.day.toString().padLeft(2, '0');
  final mois = date.month.toString().padLeft(2, '0');

  return '$jour/$mois';
}
