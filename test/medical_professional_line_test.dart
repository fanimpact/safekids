import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/medical_professional_data.dart';
import 'package:safekids/utils/medical_professional_line.dart';

/// Corrections de l'audit passe 2 : spécialité, lieu d'exercice et
/// téléphone d'un médecin référent étaient saisis mais jamais
/// affichés (seul le nom apparaissait, et uniquement sur "Ce qu'il
/// faut savoir sur...").
void main() {
  test('assemble nom, spécialité, lieu et téléphone', () {
    final line = medicalProfessionalLine(
      MedicalProfessionalData(
        name: 'Dr Cabasson',
        specialty: 'Neurologue',
        workplace: 'CHU Pau',
        phoneNumber: '0559000000',
      ),
    );

    expect(
      line,
      equals(
        'Dr Cabasson — Neurologue — CHU Pau — Tél. : 0559000000',
      ),
    );
  });

  test('omet les champs vides sans laisser de tirets orphelins', () {
    final line = medicalProfessionalLine(
      MedicalProfessionalData(name: 'Dr Cabasson'),
    );

    expect(line, equals('Dr Cabasson'));
  });

  test('sans nom, aucune ligne (jamais un professionnel anonyme)', () {
    expect(
      medicalProfessionalLine(
        MedicalProfessionalData(specialty: 'Neurologue'),
      ),
      isNull,
    );
    expect(medicalProfessionalLine(null), isNull);
  });
}
