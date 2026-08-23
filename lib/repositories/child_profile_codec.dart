import '../models/activity_profile_data.dart';
import '../models/allergy_data.dart';
import '../models/aquatic_activity_data.dart';
import '../models/child_profile_data.dart';
import '../models/clothing_data.dart';
import '../models/communication_data.dart';
import '../models/contact_data.dart';
import '../models/daily_treatment_data.dart';
import '../models/discontinued_treatment_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/identity_data.dart';
import '../models/medical_device_data.dart';
import '../models/medical_event_data.dart';
import '../models/medical_observation_data.dart';
import '../models/meals_data.dart';
import '../models/other_information_data.dart';
import '../models/overnight_stay_data.dart';
import '../models/pathology_data.dart';
import '../models/primary_care_doctor_data.dart';
import '../models/safety_data.dart';
import '../models/toilets_data.dart';
import '../models/transitions_data.dart';
import '../models/transport_data.dart';
import '../models/trigger_factor_data.dart';
import '../models/walking_effort_data.dart';

/// Conversion entre les lignes Supabase (`enfants`, `profils_sante`,
/// `profils_activites`) et les modèles Flutter — extrait de
/// `ChildRepository` pour être réutilisé tel quel par l'espace
/// professionnel (`ProfessionalChildRepository`), qui lit les mêmes
/// tables mais pour le trombinoscope d'un établissement plutôt que les
/// enfants d'un parent. Une seule version de cette conversion, jamais
/// deux logiques différentes à maintenir en parallèle.
class ChildProfileCodec {
  ChildProfileCodec._();

  // ---------------------------------------------------------------------
  // Enfant / identité <-> table "enfants"
  // ---------------------------------------------------------------------

  static Map<String, dynamic> enfantRow(
    ChildProfileData child,
    String parentId,
  ) {
    final identity = child.identity;

    return {
      'id': child.childId,
      'parent_id': parentId,
      'prenom': identity.firstName,
      'nom': identity.lastName,
      'date_naissance': dateOnly(identity.dateOfBirth),
      'poids': identity.weightKg,
      'taille': identity.heightCm,
      'date_maj_poids':
          dateOnly(identity.measurementsUpdatedAt),
      'a_pathologies_diagnostiquees':
          identity.hasDiagnosedPathologies,
      'consentement_sante_le':
          child.consentementSanteLe?.toIso8601String(),
    };
  }

  static IdentityData identityFromRow(
    Map<String, dynamic> enfant,
  ) {
    return IdentityData(
      firstName: enfant['prenom'] as String?,
      lastName: enfant['nom'] as String?,
      dateOfBirth: parseDate(
        enfant['date_naissance'] as String?,
      ),
      heightCm: (enfant['taille'] as num?)?.toDouble(),
      weightKg: (enfant['poids'] as num?)?.toDouble(),
      measurementsUpdatedAt: parseDate(
        enfant['date_maj_poids'] as String?,
      ),
      hasDiagnosedPathologies:
          enfant['a_pathologies_diagnostiquees']
              as bool?,
    );
  }

  // ---------------------------------------------------------------------
  // Profil santé <-> table "profils_sante"
  // ---------------------------------------------------------------------

  static Map<String, dynamic> santeRow(
    String childId,
    ChildProfileData child,
  ) {
    return {
      'enfant_id': childId,
      'a_pathologies': child.hasPathologies,
      'a_allergies': child.hasAllergies,
      'a_traitements_reguliers': child.hasDailyTreatments,
      'a_traitements_arretes':
          child.hasDiscontinuedTreatments,
      'a_traitements_urgence': child.hasEmergencyTreatments,
      'a_dispositifs_medicaux': child.hasMedicalDevices,
      'pathologies': toJsonList(child.pathologies),
      'allergies': toJsonList(child.allergies),
      'traitements_urgence':
          toJsonList(child.emergencyTreatments),
      'traitements_reguliers':
          toJsonList(child.dailyTreatments),
      'dispositifs_medicaux':
          toJsonList(child.medicalDevices),
      'medecin_traitant':
          child.primaryCareDoctor.toJson(),
      'facteurs_declenchants':
          child.triggerFactors.toJson(),
      'contacts_urgence': toJsonList(child.contacts),
      'evenements_medicaux':
          toJsonList(child.medicalEvents),
      'observations_medicales':
          toJsonList(child.medicalObservations),
      'traitements_arretes':
          toJsonList(child.discontinuedTreatments),
    };
  }

  static ChildProfileData childProfileFromRows({
    required String childId,
    required Map<String, dynamic> enfant,
    Map<String, dynamic>? sante,
  }) {
    return ChildProfileData(
      childId: childId,
      userId: enfant['parent_id'] as String?,
      consentementSanteLe: DateTime.tryParse(
        enfant['consentement_sante_le'] as String? ?? '',
      ),
      identity: identityFromRow(enfant),
      hasPathologies: sante?['a_pathologies'] as bool?,
      hasAllergies: sante?['a_allergies'] as bool?,
      hasDailyTreatments:
          sante?['a_traitements_reguliers'] as bool?,
      hasDiscontinuedTreatments:
          sante?['a_traitements_arretes'] as bool?,
      hasEmergencyTreatments:
          sante?['a_traitements_urgence'] as bool?,
      hasMedicalDevices:
          sante?['a_dispositifs_medicaux'] as bool?,
      pathologies: fromJsonList(
        sante?['pathologies'],
        PathologyData.fromJson,
      ),
      medicalEvents: fromJsonList(
        sante?['evenements_medicaux'],
        MedicalEventData.fromJson,
      ),
      medicalObservations: fromJsonList(
        sante?['observations_medicales'],
        MedicalObservationData.fromJson,
      ),
      triggerFactors: fromJsonObject(
        sante?['facteurs_declenchants'],
        TriggerFactorData.fromJson,
        TriggerFactorData(),
      ),
      dailyTreatments: fromJsonList(
        sante?['traitements_reguliers'],
        DailyTreatmentData.fromJson,
      ),
      discontinuedTreatments: fromJsonList(
        sante?['traitements_arretes'],
        DiscontinuedTreatmentData.fromJson,
      ),
      emergencyTreatments: fromJsonList(
        sante?['traitements_urgence'],
        EmergencyTreatmentData.fromJson,
      ),
      allergies: fromJsonList(
        sante?['allergies'],
        AllergyData.fromJson,
      ),
      medicalDevices: fromJsonList(
        sante?['dispositifs_medicaux'],
        MedicalDeviceData.fromJson,
      ),
      contacts: fromJsonList(
        sante?['contacts_urgence'],
        ContactData.fromJson,
      ),
      primaryCareDoctor: fromJsonObject(
        sante?['medecin_traitant'],
        PrimaryCareDoctorData.fromJson,
        PrimaryCareDoctorData(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Profil activités <-> table "profils_activites"
  // ---------------------------------------------------------------------

  static Map<String, dynamic> activitesRow(
    String childId,
    ActivityProfileData profile,
  ) {
    return {
      'enfant_id': childId,
      'habillage': profile.clothing.toJson(),
      'toilettes': profile.toilets.toJson(),
      'communication': profile.communication.toJson(),
      'transport': profile.transport.toJson(),
      'securite': profile.safety.toJson(),
      'nuitee': profile.overnightStay.toJson(),
      'activite_aquatique':
          profile.aquaticActivity.toJson(),
      'effort_marche': profile.walkingEffort.toJson(),
      'transitions': profile.transitions.toJson(),
      'autres_informations':
          profile.otherInformation.toJson(),
      'repas': profile.meals.toJson(),
    };
  }

  static ActivityProfileData? activityProfileFromRow(
    Map<String, dynamic>? row,
  ) {
    if (row == null) {
      return null;
    }

    return ActivityProfileData(
      aquaticActivity: fromJsonObject(
        row['activite_aquatique'],
        AquaticActivityData.fromJson,
        AquaticActivityData(),
      ),
      transport: fromJsonObject(
        row['transport'],
        TransportData.fromJson,
        TransportData(),
      ),
      walkingEffort: fromJsonObject(
        row['effort_marche'],
        WalkingEffortData.fromJson,
        WalkingEffortData(),
      ),
      overnightStay: fromJsonObject(
        row['nuitee'],
        OvernightStayData.fromJson,
        OvernightStayData(),
      ),
      clothing: fromJsonObject(
        row['habillage'],
        ClothingData.fromJson,
        ClothingData(),
      ),
      toilets: fromJsonObject(
        row['toilettes'],
        ToiletsData.fromJson,
        ToiletsData(),
      ),
      communication: fromJsonObject(
        row['communication'],
        CommunicationData.fromJson,
        CommunicationData(),
      ),
      transitions: fromJsonObject(
        row['transitions'],
        TransitionsData.fromJson,
        TransitionsData(),
      ),
      safety: fromJsonObject(
        row['securite'],
        SafetyData.fromJson,
        SafetyData(),
      ),
      otherInformation: fromJsonObject(
        row['autres_informations'],
        OtherInformationData.fromJson,
        OtherInformationData(),
      ),
      meals: fromJsonObject(
        row['repas'],
        MealsData.fromJson,
        MealsData(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Utilitaires jsonb <-> modèles
  // ---------------------------------------------------------------------

  static List<Map<String, dynamic>> toJsonList<T>(
    List<T> items,
  ) {
    return items
        .map(
          (item) =>
              (item as dynamic).toJson()
                  as Map<String, dynamic>,
        )
        .toList();
  }

  static List<T> fromJsonList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) {
      return [];
    }

    return (raw as List<dynamic>)
        .map(
          (item) => fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static T fromJsonObject<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    if (raw == null) {
      return fallback;
    }

    return fromJson(Map<String, dynamic>.from(raw as Map));
  }

  static String? dateOnly(DateTime? date) {
    if (date == null) {
      return null;
    }

    return date.toIso8601String().substring(0, 10);
  }

  static DateTime? parseDate(String? value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value);
  }
}
