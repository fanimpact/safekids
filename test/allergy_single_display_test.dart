import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/activity_pages/activity_recommendations_page.dart';
import 'package:kidsrelay/models/activity_session/activity_session_data.dart';
import 'package:kidsrelay/models/activity_session/complete_activity_session_data.dart';
import 'package:kidsrelay/models/allergy_data.dart';
import 'package:kidsrelay/models/child_profile_data.dart';
import 'package:kidsrelay/models/complete_child_profile_data.dart';
import 'package:kidsrelay/models/emergency_treatment_data.dart';
import 'package:kidsrelay/models/identity_data.dart';
import 'package:kidsrelay/models/pathology_data.dart';
import 'package:kidsrelay/models/primary_care_doctor_data.dart';
import 'package:kidsrelay/models/share_link_data.dart';
import 'package:kidsrelay/models/trigger_factor_data.dart';
import 'package:kidsrelay/recommendation_engine/recommendation_engine.dart';
import 'package:kidsrelay/recommendation_engine/rules/health_conditions_rules.dart';
import 'package:kidsrelay/repositories/child_repository.dart';
import 'package:kidsrelay/sharing/activity_recommendation_snapshot.dart';

/// Verrouille la correction du 22/08/2026 : chaque allergie était
/// affichée DEUX fois dans "Points importants" de la fiche de
/// recommandations d'activité (écran et PDF) et du lien de partage —
/// une fois par `HealthConditionsRules`, une fois par une liste de
/// textes reconstruite à la main dans la page (`_allergyTexts`) et
/// dans le snapshot. Les copies locales ont été supprimées : le
/// moteur est la seule source.
///
/// Conséquence voulue sur le masquage (arbitrage Fanny du
/// 22/08/2026) : les recommandations d'allergie sont désormais
/// critiques, donc jamais masquables, avec ou sans traitement
/// d'urgence lié — une allergie ne doit jamais pouvoir disparaître
/// d'une fiche. C'est ce que garantissaient de fait les anciennes
/// puces, qui n'étaient pas masquables.
void main() {
  ChildProfileData buildChild({
    required String childId,
    required bool withEmergencyTreatment,
  }) {
    return ChildProfileData(
      childId: childId,
      userId: 'test-user',
      identity: IdentityData(firstName: 'Camille'),
      pathologies: [
        PathologyData(
          pathologyId: 'pathologie-asthme',
          name: 'Asthme',
        ),
      ],
      medicalEvents: const [],
      medicalObservations: const [],
      triggerFactors: TriggerFactorData(),
      dailyTreatments: const [],
      discontinuedTreatments: const [],
      emergencyTreatments: withEmergencyTreatment
          ? [
              EmergencyTreatmentData(
                medicationName: 'Adrénaline',
                dosage: '1 dose',
                relatedAllergyIds: ['allergie-arachide'],
              ),
            ]
          : const [],
      allergies: [
        AllergyData(
          allergyId: 'allergie-arachide',
          allergen: 'Arachide',
          observedReaction: 'Œdème',
        ),
      ],
      medicalDevices: const [],
      contacts: const [],
      primaryCareDoctor: PrimaryCareDoctorData(),
    );
  }

  CompleteActivitySessionData buildSession(String childId) {
    return CompleteActivitySessionData(
      id: 'activite-1',
      activity: ActivitySessionData(
        activityName: 'Sortie au parc',
        date: DateTime.utc(2026, 9, 1, 10, 30),
        location: 'Parc municipal',
      ),
      childIds: [childId],
    );
  }

  setUp(() {
    ChildRepository.instance.clearForTesting();
  });

  group('Règle du moteur', () {
    test(
      'Une allergie est critique, avec ou sans traitement d’urgence '
      'lié ; une pathologie ne l’est pas',
      () {
        for (final withTreatment in [true, false]) {
          final child = CompleteChildProfileData(
            essentialInformation: buildChild(
              childId: 'enfant-criticite',
              withEmergencyTreatment: withTreatment,
            ),
          );

          final recommendations =
              const HealthConditionsRules().evaluate(child);

          final allergyRecommendation = recommendations.firstWhere(
            (recommendation) =>
                recommendation.id.startsWith('allergy_condition_'),
          );

          expect(
            allergyRecommendation.isCritical,
            isTrue,
            reason:
                'Une allergie ne doit jamais être masquable '
                '(traitement d’urgence lié : $withTreatment).',
          );

          final pathologyRecommendation = recommendations.firstWhere(
            (recommendation) =>
                recommendation.id.startsWith('pathology_condition_'),
          );

          expect(
            pathologyRecommendation.isCritical,
            isFalse,
            reason:
                'Les pathologies restent masquables : seules les '
                'allergies ont été rendues critiques.',
          );
        }
      },
    );

    test(
      'Le moteur ne produit qu’une seule vigilance par allergie',
      () {
        const childId = 'enfant-moteur';

        ChildRepository.instance.seedForTesting(
          buildChild(
            childId: childId,
            withEmergencyTreatment: false,
          ),
        );

        final result = RecommendationEngine().generateRecommendations(
          buildSession(childId),
        );

        final mentions = result.childResults
            .expand((childResult) => childResult.recommendations)
            .where(
              (recommendation) =>
                  recommendation.text.contains('Arachide'),
            )
            .toList();

        expect(
          mentions.length,
          equals(1),
          reason:
              'Sans traitement d’urgence lié, la vigilance allergie '
              'est la seule ligne qui doit nommer l’allergène.',
        );
      },
    );
  });

  group('Fiche de recommandations d’activité', () {
    testWidgets(
      'L’allergie n’est affichée qu’une seule fois',
      (tester) async {
        const childId = 'enfant-fiche';

        ChildRepository.instance.seedForTesting(
          buildChild(
            childId: childId,
            withEmergencyTreatment: false,
          ),
        );

        final session = buildSession(childId);

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityRecommendationsPage(
              activitySession: session,
              recommendationResult:
                  RecommendationEngine().generateRecommendations(
                session,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Arachide'),
          findsOneWidget,
          reason:
              'Avant correction, l’allergie apparaissait deux fois : '
              'une puce non masquable et une recommandation.',
        );
      },
    );

    testWidgets(
      'L’allergie ne porte pas d’icône de masquage, même côté '
      'professionnel',
      (tester) async {
        const childId = 'enfant-masquage';

        ChildRepository.instance.seedForTesting(
          buildChild(
            childId: childId,
            withEmergencyTreatment: false,
          ),
        );

        final session = buildSession(childId);

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityRecommendationsPage(
              activitySession: session,
              recommendationResult:
                  RecommendationEngine().generateRecommendations(
                session,
              ),
              initialMaskedKeys: const <String>{},
              onToggleMask: (cle, masquer) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find
                .ancestor(
                  of: find.textContaining('Arachide'),
                  matching: find.byType(Row),
                )
                .first,
            matching: find.byTooltip('Masquer pour moi'),
          ),
          findsNothing,
          reason:
              'Une allergie est critique : le professionnel ne doit '
              'pas pouvoir la retirer de la fiche.',
        );

        expect(
          find.descendant(
            of: find
                .ancestor(
                  of: find.textContaining('Asthme'),
                  matching: find.byType(Row),
                )
                .first,
            matching: find.byTooltip('Masquer pour moi'),
          ),
          findsOneWidget,
          reason:
              'La pathologie, elle, reste masquable — sans quoi ce '
              'test passerait aussi si le masquage était cassé '
              'partout.',
        );
      },
    );
  });

  group('Lien de partage', () {
    test(
      'L’allergie n’apparaît qu’une seule fois dans les points '
      'importants',
      () {
        const childId = 'enfant-partage';

        ChildRepository.instance.seedForTesting(
          buildChild(
            childId: childId,
            withEmergencyTreatment: false,
          ),
        );

        final session = buildSession(childId);

        final snapshot = ActivityRecommendationSnapshot.build(
          activitySession: session,
          recommendationResult:
              RecommendationEngine().generateRecommendations(session),
          child: ChildRepository.instance.findByChildId(childId)!,
          destinataire: ShareDestinataire.particulier,
        );

        final sections =
            (snapshot['sections'] as List).cast<Map<String, dynamic>>();

        final pointsImportants = sections.firstWhere(
          (section) => section['titre'] == 'Points importants',
        );

        final mentions = (pointsImportants['lignes'] as List)
            .cast<String>()
            .where((ligne) => ligne.contains('Arachide'))
            .toList();

        expect(
          mentions.length,
          equals(1),
          reason:
              'Avant correction, le snapshot ajoutait sa propre copie '
              'des allergies en plus de celle du moteur.',
        );
      },
    );
  });
}
