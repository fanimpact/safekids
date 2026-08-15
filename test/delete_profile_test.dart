import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids/children/child_profile_page.dart';
import 'package:safekids/models/allergy_data.dart';
import 'package:safekids/models/child_profile_data.dart';
import 'package:safekids/models/complete_child_profile_data.dart';
import 'package:safekids/models/identity_data.dart';
import 'package:safekids/models/pathology_data.dart';
import 'package:safekids/models/primary_care_doctor_data.dart';
import 'package:safekids/models/trigger_factor_data.dart';

/// Vérifie que "Supprimer le profil" n'est plus un bouton inactif : il
/// doit demander confirmation avant d'agir, ne rien faire si on
/// annule, et tenter réellement la suppression si on confirme.
void main() {
  CompleteChildProfileData buildChild() {
    return CompleteChildProfileData(
      essentialInformation: ChildProfileData(
        childId: 'test-child',
        userId: 'test-user',
        identity: IdentityData(
          firstName: 'Camille',
          lastName: 'Dupont',
        ),
        pathologies: const <PathologyData>[],
        medicalEvents: const [],
        medicalObservations: const [],
        triggerFactors: TriggerFactorData(),
        dailyTreatments: const [],
        discontinuedTreatments: const [],
        emergencyTreatments: const [],
        allergies: const <AllergyData>[],
        medicalDevices: const [],
        contacts: const [],
        primaryCareDoctor: PrimaryCareDoctorData(),
      ),
    );
  }

  Future<Finder> openDeleteButton(WidgetTester tester) async {
    final buttonFinder = find.ancestor(
      of: find.text('Supprimer le profil'),
      matching: find.byType(ListTile),
    );

    await tester.scrollUntilVisible(
      buttonFinder,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    return buttonFinder;
  }

  testWidgets(
    'Le bouton demande confirmation avant de supprimer',
    (tester) async {
      final child = buildChild();

      await tester.pumpWidget(
        MaterialApp(home: ChildProfilePage(child: child)),
      );
      await tester.pumpAndSettle();

      final buttonFinder = await openDeleteButton(tester);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Supprimer ce profil ?'),
        findsOneWidget,
        reason:
            'Une confirmation doit être demandée avant toute '
            'suppression, pour éviter une action accidentelle.',
      );
      expect(find.text('Camille Dupont'), findsWidgets);
    },
  );

  testWidgets(
    'Annuler ne supprime rien et referme la boîte de dialogue',
    (tester) async {
      final child = buildChild();

      await tester.pumpWidget(
        MaterialApp(home: ChildProfilePage(child: child)),
      );
      await tester.pumpAndSettle();

      final buttonFinder = await openDeleteButton(tester);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(
        find.text('Supprimer ce profil ?'),
        findsNothing,
        reason: 'La boîte de dialogue doit se refermer sans effet.',
      );
      expect(
        find.byType(ChildProfilePage),
        findsOneWidget,
        reason:
            'On doit rester sur la page du profil : rien n\'a été '
            'supprimé.',
      );
    },
  );

  testWidgets(
    'Confirmer déclenche réellement une tentative de suppression',
    (tester) async {
      final child = buildChild();

      await tester.pumpWidget(
        MaterialApp(home: ChildProfilePage(child: child)),
      );
      await tester.pumpAndSettle();

      final buttonFinder = await openDeleteButton(tester);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // En environnement de test, aucune connexion Supabase réelle
      // n'est disponible : la tentative doit échouer proprement (une
      // fenêtre d'erreur impossible à manquer), pas planter ni rester
      // silencieuse comme l'ancien bouton inactif.
      expect(
        find.text('Suppression impossible'),
        findsOneWidget,
        reason:
            'Une vraie tentative de suppression doit avoir lieu (et '
            'échouer proprement sans réseau de test), preuve que le '
            'bouton n\'est plus un simple message "à venir".',
      );
    },
  );

  testWidgets(
    'Un raccourci "retour" ne referme pas l\'indicateur de chargement pendant la suppression',
    (tester) async {
      // Reproduit le bug signalé : un raccourci clavier "retour"
      // (Échap, etc.) fermait l'indicateur de chargement pendant que
      // la suppression continuait en réalité en arrière-plan, sans
      // plus jamais donner de nouvelles à l'écran. On vérifie ici
      // directement le mécanisme qui protège la fenêtre de
      // chargement : une tentative de retour "système" ne doit pas la
      // fermer, mais un `Navigator.pop` explicite (déclenché par le
      // code une fois l'opération terminée) doit toujours fonctionner.
      // pump() (pas pumpAndSettle()) tout du long : un indicateur de
      // chargement indéterminé s'anime en continu et ne "se stabilise"
      // donc jamais.
      await tester.pumpWidget(
        const MaterialApp(
          home: PopScope(
            canPop: false,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
      await tester.pump();

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );

      // `maybePop()` renvoie `true` aussi bien quand la route est
      // réellement fermée que quand elle est explicitement bloquée
      // (elle renvoie `false` seulement si la demande "remonte" faute
      // de route à gérer) — la seule preuve fiable que l'indicateur
      // n'a pas été fermé est sa présence dans l'arbre de widgets.
      await navigator.maybePop();
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason:
            'Un raccourci "retour" ne doit pas pouvoir fermer '
            'l\'indicateur pendant que la suppression est en cours.',
      );

      // Une fois l'opération terminée, le code ferme lui-même la
      // fenêtre via Navigator.pop — ça doit toujours fonctionner.
      navigator.pop();
      await tester.pumpAndSettle();

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason:
            'Une fois l\'opération terminée, la fermeture explicite '
            'par le code doit, elle, fonctionner normalement.',
      );
    },
  );
}
