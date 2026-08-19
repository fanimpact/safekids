import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/emergency_treatment_data.dart';
import 'package:safekids/utils/emergency_treatment_step.dart';

/// Corrigé (19/08/2026) : le Mode Urgence n'affichait jamais le
/// traitement d'urgence (nom, dose, condition, mode) alors que les
/// consignes numérotées rédigées par le parent en dépendent souvent
/// ("au bout de 5 min, administrer X"). Ces tests couvrent le
/// rattachement d'un traitement à l'étape où il s'administre : choix
/// explicite du parent en priorité, jamais une recherche de mot
/// devinée dans le texte libre — sauf en repli, pour les profils
/// remplis avant que ce choix existe.
void main() {
  group('EmergencyTreatmentData — cartes étape par pathologie/allergie', () {
    test(
      'un aller-retour toJson/fromJson conserve les étapes choisies',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'BUCCOLAM',
          relatedPathologyIds: ['pathology_1'],
          administrationStepByPathologyId: {'pathology_1': 5},
        );

        final restored = EmergencyTreatmentData.fromJson(
          treatment.toJson(),
        );

        expect(
          restored.administrationStepByPathologyId,
          equals({'pathology_1': 5}),
        );
      },
    );

    test(
      'un traitement sans carte enregistrée (profil déjà existant) '
      'se décode avec une carte vide, pas une erreur',
      () {
        final treatment = EmergencyTreatmentData.fromJson({
          'medicationName': 'BUCCOLAM',
          'dosage': '1 seringue',
          'administrationCondition': 'crise plus de 5 min',
          'administrationMethod': 'dans la bouche (joue)',
          'relatedPathologyIds': ['pathology_1'],
          'relatedAllergyIds': [],
          // Pas de administrationStepByPathologyId/AllergyId ici —
          // c'est exactement la forme des données déjà enregistrées
          // avant cette fonctionnalité.
        });

        expect(
          treatment.administrationStepByPathologyId,
          isEmpty,
        );
        expect(
          treatment.administrationStepByAllergyId,
          isEmpty,
        );
      },
    );
  });

  group('resolveAdministrationStepIndex', () {
    test(
      'le choix explicite du parent est toujours prioritaire',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'BUCCOLAM',
          administrationStepByPathologyId: {'pathology_1': 2},
        );

        final resolved = resolveAdministrationStepIndex(
          treatment: treatment,
          pathologyOrAllergyId: 'pathology_1',
          isPathology: true,
          steps: [
            'Éloigner les objets dangereux',
            'Allonger en PLS',
            'Rien à voir avec BUCCOLAM ici',
            'Appeler les secours',
          ],
        );

        expect(resolved, equals(2));
      },
    );

    test(
      'sans choix explicite, repli sur le nom du médicament dans le '
      'texte de l’étape — reproduit le cas réel de Théo',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'BUCCOLAM',
        );

        final resolved = resolveAdministrationStepIndex(
          treatment: treatment,
          pathologyOrAllergyId: 'pathology_1',
          isPathology: true,
          steps: const [
            'Eloigner objets risquant de blesser',
            'Allonger en PLS',
            'Verifier qu il n y a rien dans la bouche ou enlever',
            'Declencher chrono',
            'Appeler secours',
            'Au bout de 5 min administrer BUCCOLAM dans la joue',
          ],
        );

        expect(resolved, equals(5));
      },
    );

    test(
      'la recherche de repli est insensible à la casse',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'Buccolam',
        );

        final resolved = resolveAdministrationStepIndex(
          treatment: treatment,
          pathologyOrAllergyId: 'pathology_1',
          isPathology: true,
          steps: const ['Donner le BUCCOLAM prescrit'],
        );

        expect(resolved, equals(0));
      },
    );

    test(
      'aucun choix, aucune correspondance dans le texte : pas '
      'd’étape trouvée — le traitement devra apparaître dans le '
      'filet de sécurité, pas être perdu',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'BUCCOLAM',
        );

        final resolved = resolveAdministrationStepIndex(
          treatment: treatment,
          pathologyOrAllergyId: 'pathology_1',
          isPathology: true,
          steps: const [
            'Mettre en PLS',
            'Appeler les secours',
          ],
        );

        expect(resolved, isNull);
      },
    );

    test(
      'un choix explicite devenu invalide (étape supprimée depuis) '
      'retombe sur le repli au lieu de planter',
      () {
        final treatment = EmergencyTreatmentData(
          medicationName: 'BUCCOLAM',
          administrationStepByPathologyId: {
            'pathology_1': 99,
          },
        );

        final resolved = resolveAdministrationStepIndex(
          treatment: treatment,
          pathologyOrAllergyId: 'pathology_1',
          isPathology: true,
          steps: const ['Administrer le BUCCOLAM'],
        );

        expect(resolved, equals(0));
      },
    );
  });

  group('emergencyTreatmentDetailLine', () {
    test('assemble nom, dose, condition et mode', () {
      final treatment = EmergencyTreatmentData(
        medicationName: 'BUCCOLAM',
        dosage: '1 seringue',
        administrationCondition: 'crise plus de 5 min',
        administrationMethod: 'dans la bouche (joue)',
      );

      expect(
        emergencyTreatmentDetailLine(treatment),
        equals(
          'BUCCOLAM — 1 seringue — crise plus de 5 min — '
          'dans la bouche (joue)',
        ),
      );
    });
  });
}
