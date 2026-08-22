import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/recommendation_engine/rules/health_conditions_rules.dart';

CompleteChildProfileData _createTestChild({
  required String childId,
  List<PathologyData> pathologies = const [],
  List<AllergyData> allergies = const [],
}) {
  return CompleteChildProfileData(
    essentialInformation: ChildProfileData(
      childId: childId,
      userId: 'test-family',
      identity: IdentityData(
        firstName: 'Test',
        lastName: 'Enfant',
      ),
      pathologies: pathologies,
      medicalEvents: [],
      medicalObservations: [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: [],
      discontinuedTreatments: [],
      emergencyTreatments: [],
      allergies: allergies,
      medicalDevices: [],
      contacts: [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    ),
  );
}

/// Corrigé (19/08/2026) : avant cette règle, une allergie ou une
/// pathologie sans traitement d'urgence lié n'apparaissait dans
/// aucune recommandation — le moteur ne la lisait que via les
/// traitements qui la référencent.
void main() {
  const rules = HealthConditionsRules();

  test(
    'Une pathologie sans traitement lié génère quand même une '
    'recommandation',
    () {
      final child = _createTestChild(
        childId: 'test-pathology-no-treatment',
        pathologies: [
          PathologyData(
            pathologyId: 'p1',
            name: 'Épilepsie',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations
            .map((r) => r.text)
            .toList(),
        contains('Pathologie : Épilepsie.'),
      );
    },
  );

  test(
    'Une allergie sans traitement lié génère quand même une '
    'recommandation, avec la réaction si renseignée',
    () {
      final child = _createTestChild(
        childId: 'test-allergy-no-treatment',
        allergies: [
          AllergyData(
            allergyId: 'a1',
            allergen: 'Arachides',
            observedReaction: 'Urticaire',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations
            .map((r) => r.text)
            .toList(),
        contains(
          'Allergie : Arachides — réaction : Urticaire.',
        ),
      );
    },
  );

  test(
    'Une allergie sans réaction renseignée génère une recommandation '
    'sans mention de réaction',
    () {
      final child = _createTestChild(
        childId: 'test-allergy-no-reaction',
        allergies: [
          AllergyData(
            allergyId: 'a2',
            allergen: 'Fruits à coque',
          ),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(
        recommendations
            .map((r) => r.text)
            .toList(),
        contains('Allergie : Fruits à coque.'),
      );
    },
  );

  test(
    'Pathologie et allergie sans nom renseigné ne génèrent rien',
    () {
      final child = _createTestChild(
        childId: 'test-empty',
        pathologies: [
          PathologyData(pathologyId: 'p3'),
        ],
        allergies: [
          AllergyData(allergyId: 'a3'),
        ],
      );

      final recommendations = rules.evaluate(child);

      expect(recommendations, isEmpty);
    },
  );
}
