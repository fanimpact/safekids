import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/journal_consultation_data.dart';

/// Corrections de l'audit passe 1 (RGPD) : le parent doit pouvoir voir
/// qui a consulté la fiche de son enfant et quand.
void main() {
  group('TypeFicheConsultee', () {
    test('a un libellé français pour chaque type de fiche', () {
      expect(
        typeFicheConsulteeLabel(TypeFicheConsultee.secours),
        equals('Informations pour les secours'),
      );
      expect(
        typeFicheConsulteeLabel(
          TypeFicheConsultee.ceQuIlFautSavoir,
        ),
        equals('Ce qu’il faut savoir sur l’enfant'),
      );
      expect(
        typeFicheConsulteeLabel(
          TypeFicheConsultee.profilActivites,
        ),
        equals('Profil Activités'),
      );
      expect(
        typeFicheConsulteeLabel(TypeFicheConsultee.modeUrgence),
        equals('Mode Urgence'),
      );
    });
  });

  group('JournalConsultationData', () {
    test(
      'se construit depuis une ligne Supabase avec le nom de '
      'l’établissement joint',
      () {
        final consultation = JournalConsultationData.fromRow({
          'id': 'log-1',
          'enfant_id': 'theo',
          'etablissement_id': 'etab-1',
          'etablissements': {'nom': 'École des Tilleuls'},
          'type_fiche': 'secours',
          'consulte_le': '2026-08-19T10:00:00.000Z',
        });

        expect(
          consultation.etablissementNom,
          equals('École des Tilleuls'),
        );
        expect(
          consultation.typeFiche,
          equals(TypeFicheConsultee.secours),
        );
      },
    );

    test(
      'un établissement absent (ligne jointe nulle) ne fait pas '
      'échouer le décodage',
      () {
        final consultation = JournalConsultationData.fromRow({
          'id': 'log-2',
          'enfant_id': 'theo',
          'etablissement_id': null,
          'etablissements': null,
          'type_fiche': 'mode_urgence',
          'consulte_le': '2026-08-19T10:00:00.000Z',
        });

        expect(consultation.etablissementNom, isNull);
        expect(
          consultation.typeFiche,
          equals(TypeFicheConsultee.modeUrgence),
        );
      },
    );
  });
}
