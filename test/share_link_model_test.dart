import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/models/share_link_data.dart';

/// Vérifie le décodage des lignes Supabase pour les liens de partage
/// ponctuels (`partages`) et la logique d'expiration côté parent —
/// utilisée par la section "Partages" de la fiche enfant
/// (corrections de l'inventaire du 19/08/2026, point 4).
void main() {
  group('ShareFicheType', () {
    test('reconnaît les 3 valeurs autorisées par la contrainte SQL', () {
      expect(
        ShareFicheType.fromValue('secours'),
        equals(ShareFicheType.secours),
      );
      expect(
        ShareFicheType.fromValue('ce_qu_il_faut_savoir'),
        equals(ShareFicheType.ceQuIlFautSavoir),
      );
      expect(
        ShareFicheType.fromValue('recommandations_activite'),
        equals(ShareFicheType.recommandationsActivite),
      );
    });
  });

  group('ShareLinkData', () {
    test('se construit depuis une ligne Supabase', () {
      final link = ShareLinkData.fromRow({
        'id': 'lien-1',
        'token': 'abc123',
        'enfant_id': 'theo',
        'type_fiche': 'secours',
        'date_creation': '2026-08-17T10:00:00.000Z',
        'date_expiration': '2099-08-18T10:00:00.000Z',
        'date_derniere_consultation': null,
      });

      expect(link.ficheType, equals(ShareFicheType.secours));
      expect(link.dateDerniereConsultation, isNull);
      expect(link.estExpire, isFalse);
    });

    test('une date d’expiration passée est détectée', () {
      final link = ShareLinkData.fromRow({
        'id': 'lien-2',
        'token': 'def456',
        'enfant_id': 'noe',
        'type_fiche': 'ce_qu_il_faut_savoir',
        'date_creation': '2025-01-01T10:00:00.000Z',
        'date_expiration': '2025-01-02T10:00:00.000Z',
        'date_derniere_consultation': '2025-01-01T12:00:00.000Z',
      });

      expect(link.estExpire, isTrue);
      expect(
        link.dateDerniereConsultation,
        equals(DateTime.parse('2025-01-01T12:00:00.000Z')),
      );
    });
  });
}
