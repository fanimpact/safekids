import 'package:flutter_test/flutter_test.dart';
import 'package:kidsrelay/utils/treatment_audience.dart';

/// Corrigé (19/08/2026) : chaque traitement affiché doit s'accompagner
/// d'une mention rappelant le cadre d'administration — selon le PAI
/// pour une structure d'accueil, selon les indications du parent pour
/// un particulier, aucune mention pour le parent qui consulte la
/// fiche de son propre enfant.
void main() {
  test('aucune mention pour le propriétaire de la fiche', () {
    expect(
      treatmentMentionSuffix(TreatmentAudience.owner),
      isNull,
    );
  });

  test('rappelle les indications du parent pour un particulier', () {
    expect(
      treatmentMentionSuffix(TreatmentAudience.particulier),
      contains('indications du parent'),
    );
  });

  test('rappelle le PAI pour un professionnel/structure d’accueil', () {
    expect(
      treatmentMentionSuffix(TreatmentAudience.professionnel),
      contains('PAI'),
    );
  });
}
