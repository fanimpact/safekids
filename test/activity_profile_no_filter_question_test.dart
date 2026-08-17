import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/activity_profile_pages/communication_page.dart';
import 'package:safekids/activity_profile_pages/overnight_stay_page.dart';
import 'package:safekids/activity_profile_pages/safety_page.dart';
import 'package:safekids/activity_profile_pages/transitions_page.dart';
import 'package:safekids/activity_profile_pages/transport_page.dart';
import 'package:safekids/controllers/activity_profile_controller.dart';

/// Vérifie que les questions filtres "Votre enfant a-t-il besoin
/// d'adaptations particulières pour X ?" ont bien disparu des sections
/// transport, nuitée, communication, transitions et sécurité du profil
/// activités, et que les questions détaillées de chaque section sont
/// affichées directement, sans qu'aucune réponse préalable soit
/// nécessaire — même correction que celle faite pour les facteurs
/// déclenchants : un parent ne doit plus pouvoir répondre "Non" par
/// réflexe à une question filtre et cacher ainsi une vraie information.
void main() {
  testWidgets(
    'Transport : aucune question filtre, la question sur le mal des '
    'transports est visible directement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransportPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières lors des transports',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant a-t-il le mal des transports ?',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Nuitée : aucune question filtre, la question sur l\'appareillage '
    'est visible directement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OvernightStayPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières lors d’un séjour avec nuitée',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant utilise-t-il un appareillage pendant la nuit ?',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Communication : aucune question filtre, les questions détaillées '
    'sont visibles directement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CommunicationPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières concernant la communication',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Les consignes doivent être formulées avec des mots simples.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Votre enfant utilise-t-il un support de communication particulier ?',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Transitions : aucune question filtre, les questions détaillées '
    'sont visibles directement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransitionsPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières lors des transitions',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Les changements d’activité peuvent provoquer un stress important.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Les changements de programme doivent être annoncés à l’avance.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Sécurité : aucune question filtre, les questions détaillées sont '
    'visibles directement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafetyPage(
            activityProfileController:
                ActivityProfileController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'des adaptations particulières concernant sa sécurité',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Votre enfant a déjà quitté brusquement un groupe.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Votre enfant nécessite-t-il un équipement de sécurité particulier ?',
        ),
        findsOneWidget,
      );
    },
  );
}
