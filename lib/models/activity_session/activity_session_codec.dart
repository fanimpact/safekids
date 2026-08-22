import 'activity_answer.dart';
import 'activity_session_data.dart';
import 'complete_activity_session_data.dart';

/// Conversion entre `ActivitySessionData`/`CompleteActivitySessionData`
/// et les lignes de la table `activites_preparees` (colonnes
/// `nom_activite`/`date_activite`/`lieu`/`enfants_ids` + le reste des
/// champs dans la colonne `description` jsonb). Partagé entre
/// `ActivitySessionRepository` (parent) et `EstablishmentActivityService`
/// (professionnel) pour ne pas dupliquer cette conversion, même
/// principe que `ChildProfileCodec`.
class ActivitySessionCodec {
  ActivitySessionCodec._();

  static Map<String, dynamic> descriptionToJson(
    ActivitySessionData activity,
  ) {
    return {
      'hasWaterNearby': activity.hasWaterNearby,
      'childrenWillEnterWater':
          activity.childrenWillEnterWater,
      'swimmingSupervisedByLifeguard':
          activity.swimmingSupervisedByLifeguard,
      'hasProlongedWalking': activity.hasProlongedWalking,
      'hasSignificantPhysicalEffort':
          activity.hasSignificantPhysicalEffort,
      'hasTransport': activity.hasTransport,
      'transportTypes': activity.transportTypes
          .map((type) => type.name)
          .toList(),
      'hasOvernightStay': activity.hasOvernightStay,
      'collectiveAccommodation':
          activity.collectiveAccommodation,
      'electricityMayBeUnavailable':
          activity.electricityMayBeUnavailable?.name,
      'phoneNetworkMayBeUnavailable':
          activity.phoneNetworkMayBeUnavailable?.name,
      'hasHeightActivity': activity.hasHeightActivity,
      'hasAnimalContact': activity.hasAnimalContact,
      'hasLoudEnvironment': activity.hasLoudEnvironment,
      'hasLargeCrowd': activity.hasLargeCrowd,
      'hasConfinedSpace': activity.hasConfinedSpace,
      'hasClothingChange': activity.hasClothingChange,
      'hasMeal': activity.hasMeal,
    };
  }

  static ActivityThreeStateAnswer? _threeState(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return ActivityThreeStateAnswer.values.firstWhere(
      (answer) => answer.name == value,
      orElse: () => ActivityThreeStateAnswer.unknown,
    );
  }

  static ActivitySessionData activityFromRow(
    Map<String, dynamic> row,
  ) {
    final description =
        (row['description'] as Map?)
            ?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final dateActivite = row['date_activite'] as String?;

    final transportTypesRaw =
        (description['transportTypes'] as List?) ?? [];

    return ActivitySessionData(
      activityName: row['nom_activite'] as String?,
      date: dateActivite == null
          ? null
          : DateTime.parse(dateActivite).toLocal(),
      location: row['lieu'] as String?,
      hasWaterNearby:
          description['hasWaterNearby'] as bool?,
      childrenWillEnterWater:
          description['childrenWillEnterWater'] as bool?,
      swimmingSupervisedByLifeguard:
          description['swimmingSupervisedByLifeguard']
              as bool?,
      hasProlongedWalking:
          description['hasProlongedWalking'] as bool?,
      hasSignificantPhysicalEffort:
          description['hasSignificantPhysicalEffort']
              as bool?,
      hasTransport: description['hasTransport'] as bool?,
      transportTypes: transportTypesRaw
          .map(
            (name) => ActivityTransportType.values
                .firstWhere(
              (type) => type.name == name,
              orElse: () => ActivityTransportType.other,
            ),
          )
          .toSet(),
      hasOvernightStay:
          description['hasOvernightStay'] as bool?,
      collectiveAccommodation:
          description['collectiveAccommodation'] as bool?,
      electricityMayBeUnavailable: _threeState(
        description['electricityMayBeUnavailable'],
      ),
      phoneNetworkMayBeUnavailable: _threeState(
        description['phoneNetworkMayBeUnavailable'],
      ),
      hasHeightActivity:
          description['hasHeightActivity'] as bool?,
      hasAnimalContact:
          description['hasAnimalContact'] as bool?,
      hasLoudEnvironment:
          description['hasLoudEnvironment'] as bool?,
      hasLargeCrowd: description['hasLargeCrowd'] as bool?,
      hasConfinedSpace:
          description['hasConfinedSpace'] as bool?,
      hasClothingChange:
          description['hasClothingChange'] as bool?,
      hasMeal: description['hasMeal'] as bool?,
    );
  }

  static CompleteActivitySessionData completeFromRow(
    Map<String, dynamic> row,
  ) {
    final enfantsIds =
        (row['enfants_ids'] as List?)
            ?.cast<String>() ??
        const <String>[];

    return CompleteActivitySessionData(
      id: row['id'] as String?,
      activity: activityFromRow(row),
      childIds: enfantsIds,
      recommendationsGenerated: false,
    );
  }
}
