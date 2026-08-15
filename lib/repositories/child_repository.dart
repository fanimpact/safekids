import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_profile_data.dart';
import '../models/allergy_data.dart';
import '../models/aquatic_activity_data.dart';
import '../models/child_profile_data.dart';
import '../models/clothing_data.dart';
import '../models/communication_data.dart';
import '../models/complete_child_profile_data.dart';
import '../models/contact_data.dart';
import '../models/daily_treatment_data.dart';
import '../models/discontinued_treatment_data.dart';
import '../models/emergency_treatment_data.dart';
import '../models/identity_data.dart';
import '../models/medical_device_data.dart';
import '../models/medical_event_data.dart';
import '../models/medical_observation_data.dart';
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

/// Source de vérité : Supabase (tables `enfants`, `profils_sante`,
/// `profils_activites`). `_children` est un cache en mémoire, rempli une
/// fois au démarrage par [loadFromSupabase] : les lectures (`children`,
/// `findByChildId`) restent synchrones pour ne rien changer aux ~30
/// endroits de l'app qui les utilisent directement dans un `build()`.
class ChildRepository {
  ChildRepository._();

  static final ChildRepository instance = ChildRepository._();

  final List<CompleteChildProfileData> _children = [];

  SupabaseClient get _client => Supabase.instance.client;

  List<CompleteChildProfileData> get children =>
      List.unmodifiable(_children);

  CompleteChildProfileData? findByChildId(
    String childId,
  ) {
    for (final child in _children) {
      if (child.childId == childId) {
        return child;
      }
    }

    return null;
  }

  Future<void> loadFromSupabase() async {
    final parentId = _client.auth.currentUser?.id;

    if (parentId == null) {
      _children.clear();
      return;
    }

    final enfantsRows = await _client
        .from('enfants')
        .select();

    final loaded = <CompleteChildProfileData>[];

    for (final enfant in enfantsRows) {
      final childId = enfant['id'] as String;

      final sante = await _client
          .from('profils_sante')
          .select()
          .eq('enfant_id', childId)
          .maybeSingle();

      final activites = await _client
          .from('profils_activites')
          .select()
          .eq('enfant_id', childId)
          .maybeSingle();

      loaded.add(
        CompleteChildProfileData(
          essentialInformation: _childProfileFromRows(
            childId: childId,
            enfant: enfant,
            sante: sante,
          ),
          activityProfile: _activityProfileFromRow(
            activites,
          ),
          activityProfileCompleted: activites != null,
        ),
      );
    }

    _children
      ..clear()
      ..addAll(loaded);
  }

  Future<void> addChild(
    ChildProfileData child,
  ) async {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    if (findByChildId(childId) != null) {
      return;
    }

    final parentId = _requireParentId();

    // upsert plutôt qu'insert : si un essai précédent a échoué après
    // avoir déjà créé la ligne "enfants" (coupure réseau, etc.), on
    // doit pouvoir réessayer avec les mêmes réponses sans provoquer
    // une erreur de doublon.
    await _client
        .from('enfants')
        .upsert(_enfantRow(child, parentId));
    await _client
        .from('profils_sante')
        .upsert(
          _santeRow(childId, child),
          onConflict: 'enfant_id',
        );

    _children.add(
      CompleteChildProfileData(
        essentialInformation: child,
      ),
    );
  }

  Future<void> replaceChild(
    ChildProfileData child,
  ) async {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    final existing = findByChildId(childId);

    if (existing == null) {
      await addChild(child);
      return;
    }

    final parentId = _requireParentId();

    await _client
        .from('enfants')
        .update(_enfantRow(child, parentId))
        .eq('id', childId);
    await _client
        .from('profils_sante')
        .upsert(
          _santeRow(childId, child),
          onConflict: 'enfant_id',
        );

    existing.essentialInformation = child;
  }

  Future<void> saveActivityProfile({
    required String childId,
    required ActivityProfileData activityProfile,
  }) async {
    final child = findByChildId(childId);

    if (child == null) {
      return;
    }

    await _client
        .from('profils_activites')
        .upsert(
          _activitesRow(childId, activityProfile),
          onConflict: 'enfant_id',
        );

    child.activityProfile = activityProfile;
    child.activityProfileCompleted = true;
  }

  /// Ajoute uniquement au cache local, sans appel réseau — utilisé par
  /// les tests unitaires et les profils de démo pour ne pas dépendre
  /// d'une connexion Supabase.
  void seedForTesting(ChildProfileData child) {
    final childId = child.childId;

    if (childId == null || findByChildId(childId) != null) {
      return;
    }

    _children.add(
      CompleteChildProfileData(
        essentialInformation: child,
      ),
    );
  }

  /// Équivalent de [saveActivityProfile], mais uniquement dans le cache
  /// local — même usage que [seedForTesting].
  void seedActivityProfileForTesting({
    required String childId,
    required ActivityProfileData activityProfile,
  }) {
    final child = findByChildId(childId);

    if (child == null) {
      return;
    }

    child.activityProfile = activityProfile;
    child.activityProfileCompleted = true;
  }

  String _requireParentId() {
    final parentId = _client.auth.currentUser?.id;

    if (parentId == null) {
      throw StateError(
        "Impossible d'enregistrer : aucun utilisateur "
        'Supabase connecté.',
      );
    }

    return parentId;
  }

  // ---------------------------------------------------------------------
  // Enfant / identité <-> table "enfants"
  // ---------------------------------------------------------------------

  Map<String, dynamic> _enfantRow(
    ChildProfileData child,
    String parentId,
  ) {
    final identity = child.identity;

    return {
      'id': child.childId,
      'parent_id': parentId,
      'prenom': identity.firstName,
      'nom': identity.lastName,
      'date_naissance': _dateOnly(identity.dateOfBirth),
      'poids': identity.weightKg,
      'taille': identity.heightCm,
      'date_maj_poids':
          _dateOnly(identity.measurementsUpdatedAt),
      'a_pathologies_diagnostiquees':
          identity.hasDiagnosedPathologies,
    };
  }

  IdentityData _identityFromRow(
    Map<String, dynamic> enfant,
  ) {
    return IdentityData(
      firstName: enfant['prenom'] as String?,
      lastName: enfant['nom'] as String?,
      dateOfBirth: _parseDate(
        enfant['date_naissance'] as String?,
      ),
      heightCm: (enfant['taille'] as num?)?.toDouble(),
      weightKg: (enfant['poids'] as num?)?.toDouble(),
      measurementsUpdatedAt: _parseDate(
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

  Map<String, dynamic> _santeRow(
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
      'pathologies': _toJsonList(child.pathologies),
      'allergies': _toJsonList(child.allergies),
      'traitements_urgence':
          _toJsonList(child.emergencyTreatments),
      'traitements_reguliers':
          _toJsonList(child.dailyTreatments),
      'dispositifs_medicaux':
          _toJsonList(child.medicalDevices),
      'medecin_traitant':
          child.primaryCareDoctor.toJson(),
      'facteurs_declenchants':
          child.triggerFactors.toJson(),
      'contacts_urgence': _toJsonList(child.contacts),
      'evenements_medicaux':
          _toJsonList(child.medicalEvents),
      'observations_medicales':
          _toJsonList(child.medicalObservations),
      'traitements_arretes':
          _toJsonList(child.discontinuedTreatments),
    };
  }

  ChildProfileData _childProfileFromRows({
    required String childId,
    required Map<String, dynamic> enfant,
    Map<String, dynamic>? sante,
  }) {
    return ChildProfileData(
      childId: childId,
      identity: _identityFromRow(enfant),
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
      pathologies: _fromJsonList(
        sante?['pathologies'],
        PathologyData.fromJson,
      ),
      medicalEvents: _fromJsonList(
        sante?['evenements_medicaux'],
        MedicalEventData.fromJson,
      ),
      medicalObservations: _fromJsonList(
        sante?['observations_medicales'],
        MedicalObservationData.fromJson,
      ),
      triggerFactors: _fromJsonObject(
        sante?['facteurs_declenchants'],
        TriggerFactorData.fromJson,
        TriggerFactorData(),
      ),
      dailyTreatments: _fromJsonList(
        sante?['traitements_reguliers'],
        DailyTreatmentData.fromJson,
      ),
      discontinuedTreatments: _fromJsonList(
        sante?['traitements_arretes'],
        DiscontinuedTreatmentData.fromJson,
      ),
      emergencyTreatments: _fromJsonList(
        sante?['traitements_urgence'],
        EmergencyTreatmentData.fromJson,
      ),
      allergies: _fromJsonList(
        sante?['allergies'],
        AllergyData.fromJson,
      ),
      medicalDevices: _fromJsonList(
        sante?['dispositifs_medicaux'],
        MedicalDeviceData.fromJson,
      ),
      contacts: _fromJsonList(
        sante?['contacts_urgence'],
        ContactData.fromJson,
      ),
      primaryCareDoctor: _fromJsonObject(
        sante?['medecin_traitant'],
        PrimaryCareDoctorData.fromJson,
        PrimaryCareDoctorData(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Profil activités <-> table "profils_activites"
  // ---------------------------------------------------------------------

  Map<String, dynamic> _activitesRow(
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
    };
  }

  ActivityProfileData? _activityProfileFromRow(
    Map<String, dynamic>? row,
  ) {
    if (row == null) {
      return null;
    }

    return ActivityProfileData(
      aquaticActivity: _fromJsonObject(
        row['activite_aquatique'],
        AquaticActivityData.fromJson,
        AquaticActivityData(),
      ),
      transport: _fromJsonObject(
        row['transport'],
        TransportData.fromJson,
        TransportData(),
      ),
      walkingEffort: _fromJsonObject(
        row['effort_marche'],
        WalkingEffortData.fromJson,
        WalkingEffortData(),
      ),
      overnightStay: _fromJsonObject(
        row['nuitee'],
        OvernightStayData.fromJson,
        OvernightStayData(),
      ),
      clothing: _fromJsonObject(
        row['habillage'],
        ClothingData.fromJson,
        ClothingData(),
      ),
      toilets: _fromJsonObject(
        row['toilettes'],
        ToiletsData.fromJson,
        ToiletsData(),
      ),
      communication: _fromJsonObject(
        row['communication'],
        CommunicationData.fromJson,
        CommunicationData(),
      ),
      transitions: _fromJsonObject(
        row['transitions'],
        TransitionsData.fromJson,
        TransitionsData(),
      ),
      safety: _fromJsonObject(
        row['securite'],
        SafetyData.fromJson,
        SafetyData(),
      ),
      otherInformation: _fromJsonObject(
        row['autres_informations'],
        OtherInformationData.fromJson,
        OtherInformationData(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Utilitaires jsonb <-> modèles
  // ---------------------------------------------------------------------

  List<Map<String, dynamic>> _toJsonList<T>(
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

  List<T> _fromJsonList<T>(
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

  T _fromJsonObject<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    if (raw == null) {
      return fallback;
    }

    return fromJson(Map<String, dynamic>.from(raw as Map));
  }

  String? _dateOnly(DateTime? date) {
    if (date == null) {
      return null;
    }

    return date.toIso8601String().substring(0, 10);
  }

  DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value);
  }
}
