import 'activity_answer.dart';

enum ActivityTransportType {
  car,
  bus,
  train,
  tram,
  metro,
  plane,
  boatOrFerry,
  other,
}

class ActivitySessionData {
  String? activityName;
  DateTime? date;
  String? location;

  /// Renseigné uniquement pendant le parcours de préparation côté
  /// établissement, pour que `ActivitySessionCompletePage` sache vers
  /// quelle sauvegarde router l'activité une fois les enfants
  /// sélectionnés — jamais persisté tel quel (voir
  /// `ActivitySessionCodec`, qui ne l'inclut pas dans la description
  /// enregistrée).
  String? etablissementId;

  /// Renseigné uniquement en mode "modifier les caractéristiques d'une
  /// activité déjà générée" (depuis `ActivityRecommendationsPage`) :
  /// signale à `ActivitySessionCompletePage` qu'il s'agit d'une mise à
  /// jour de cette activité existante, pas d'une nouvelle activité —
  /// jamais persisté tel quel, comme `etablissementId`. Les enfants
  /// concernés n'ont pas besoin d'être repassés ici : la ligne
  /// retournée par la mise à jour en base les porte déjà (ils ne sont
  /// pas modifiés par ce parcours).
  String? activiteId;

  final List<String> selectedChildIds;

  bool? hasWaterNearby;
  bool? childrenWillEnterWater;
  bool? swimmingSupervisedByLifeguard;

  bool? hasProlongedWalking;
  bool? hasSignificantPhysicalEffort;

  bool? hasTransport;
  final Set<ActivityTransportType> transportTypes;

  bool? hasOvernightStay;
  bool? collectiveAccommodation;
  ActivityThreeStateAnswer? electricityMayBeUnavailable;
  ActivityThreeStateAnswer? phoneNetworkMayBeUnavailable;

  bool? hasHeightActivity;
  bool? hasAnimalContact;

  bool? hasLoudEnvironment;
  bool? hasLargeCrowd;
  bool? hasConfinedSpace;

  bool? hasClothingChange;

  /// Déclenche les recommandations liées aux repas, comme
  /// `hasWaterNearby` déclenche celles de la baignade : sans repas
  /// prévu, la section Repas du profil ne remonte pas sur la fiche.
  bool? hasMeal;

  ActivitySessionData({
    this.activityName,
    this.date,
    this.location,
    this.activiteId,
    List<String>? selectedChildIds,
    this.hasWaterNearby,
    this.childrenWillEnterWater,
    this.swimmingSupervisedByLifeguard,
    this.hasProlongedWalking,
    this.hasSignificantPhysicalEffort,
    this.hasTransport,
    Set<ActivityTransportType>? transportTypes,
    this.hasOvernightStay,
    this.collectiveAccommodation,
    this.electricityMayBeUnavailable,
    this.phoneNetworkMayBeUnavailable,
    this.hasHeightActivity,
    this.hasAnimalContact,
    this.hasLoudEnvironment,
    this.hasLargeCrowd,
    this.hasConfinedSpace,
    this.hasClothingChange,
    this.hasMeal,
  })  : selectedChildIds = selectedChildIds ?? [],
        transportTypes = transportTypes ?? {};
}