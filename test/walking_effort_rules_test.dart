import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/activity_profile_data.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/aquatic_activity_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/clothing_data.dart';
import 'package:kidsrelay/models/communication_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/other_information_data.dart';
import 'package:kidsrelay/models/overnight_stay_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/safety_data.dart';
import 'package:kidsrelay/models/toilets_data.dart';
import 'package:kidsrelay/models/transitions_data.dart';
import 'package:kidsrelay/models/transport_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/models/walking_effort_data.dart';
import 'package:kidsrelay/recommendation_engine/rules/walking_effort_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  bool? triggerFactorPhysicalEffort,
  bool? intensePhysicalEffortRequiresVigilance,
}) {
  return CompleteChildProfileData(
    essentialInformation: ChildProfileData(
      childId: childId,
      userId: 'test-family',
      identity: IdentityData(
        firstName: 'Test',
        lastName: 'Enfant',
      ),
      pathologies: [],
      medicalEvents: [],
      medicalObservations: [],
      triggerFactors: TriggerFactorData(
        physicalEffort: triggerFactorPhysicalEffort,
      ),
      dailyTreatments: [],
      discontinuedTreatments: [],
      emergencyTreatments: [],
      allergies: [],
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    ),
    activityProfile: ActivityProfileData(
      aquaticActivity: AquaticActivityData(),
      transport: TransportData(),
      walkingEffort: WalkingEffortData(
        intensePhysicalEffortRequiresVigilance:
            intensePhysicalEffortRequiresVigilance,
      ),
      overnightStay: OvernightStayData(),
      clothing: ClothingData(),
      toilets: ToiletsData(),
      communication: CommunicationData(),
      transitions: TransitionsData(),
      safety: SafetyData(),
      otherInformation: OtherInformationData(),
    ),
  );
}

/// Corrigé (19/08/2026) : le facteur déclenchant "effort physique" du
/// profil santé (critique) et cette question du profil activités
/// généraient deux recommandations quasi identiques sous la même
/// condition d'activité quand les deux étaient renseignées à "oui".
void main() {
  const rules = WalkingEffortRules();

  test(
    'Effort intense seul (sans le facteur déclenchant santé) génère '
    'sa propre recommandation',
    () {
      final child = _createTestChild(
        childId: 'test-effort-only',
        triggerFactorPhysicalEffort: false,
        intensePhysicalEffortRequiresVigilance: true,
      );

      final recommendations = rules.evaluate(
        child,
        ActivitySessionData(
          hasSignificantPhysicalEffort: true,
        ),
      );

      expect(
        recommendations
            .map((r) => r.id)
            .toList(),
        contains('intense_physical_effort_vigilance'),
      );
    },
  );

  test(
    'Effort intense ET facteur déclenchant santé tous les deux à '
    'oui : une seule recommandation, pas deux',
    () {
      final child = _createTestChild(
        childId: 'test-effort-both',
        triggerFactorPhysicalEffort: true,
        intensePhysicalEffortRequiresVigilance: true,
      );

      final recommendations = rules.evaluate(
        child,
        ActivitySessionData(
          hasSignificantPhysicalEffort: true,
        ),
      );

      expect(
        recommendations
            .map((r) => r.id)
            .toList(),
        isNot(
          contains('intense_physical_effort_vigilance'),
        ),
        reason:
            'Le facteur déclenchant du profil santé '
            '(trigger_physical_effort_vigilance, critique) couvre '
            'déjà ce risque — cette règle ne doit pas dupliquer.',
      );
    },
  );
}
