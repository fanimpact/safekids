import 'package:flutter/material.dart';
import 'dart:async';

import 'auth/auth_provider.dart';
import 'auth/supabase_auth_provider.dart';
import 'concept_page.dart';
import 'demarrage/destination_demarrage.dart';
import 'home/home_page.dart';
import 'professional/establishment_home_page.dart';
import 'professional/establishment_service.dart';
import 'profile_choice_page.dart';
import 'repositories/child_repository.dart';
import 'suppression/garde_suppression.dart';
import 'verrou/garde_verrou.dart';

/// Le premier écran, et celui qui décide où l'on va.
///
/// **Ce qu'il corrige.** L'application affichait l'écran de connexion à
/// chaque démarrage, même quand la session était valide : rien dans
/// l'interface ne consultait `hasSession`. Un parent qui ouvre cette
/// application en urgence est précisément celui qui ne retrouvera pas
/// son mot de passe.
///
/// **Pourquoi le délai de deux secondes a sauté quand il y a une
/// session.** Il servait à laisser voir le mot de bienvenue. Deux
/// secondes ne coûtent rien à quelqu'un qui découvre l'application ;
/// elles coûtent beaucoup à un parent devant les pompiers. L'écran
/// reste affiché le temps de la vérification, et pas une milliseconde
/// de plus.
class WelcomePage extends StatefulWidget {
  /// Injecté pour les tests.
  final AuthProvider? authProvider;

  const WelcomePage({super.key, this.authProvider});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    _decider();
  }

  AuthProvider get _auth =>
      widget.authProvider ?? SupabaseAuthProvider.instance;

  Future<void> _decider() async {
    final destination = await _destination();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _ecran(destination)),
    );
  }

  Future<DestinationDemarrage> _destination() async {
    bool session;
    bool anonyme;

    try {
      session = _auth.hasSession;
      anonyme = _auth.isAnonymous;
    } catch (_) {
      // Fournisseur non initialisé (tests de widgets sans Supabase) :
      // on se comporte comme sans session.
      session = false;
      anonyme = false;
    }

    if (!session || anonyme) {
      // Le mot de bienvenue garde ses deux secondes pour qui découvre
      // l'application.
      await Future<void>.delayed(const Duration(seconds: 2));

      return DestinationDemarrage.concept;
    }

    return destinationDemarrage(
      session: session,
      anonyme: anonyme,
      enfants: await _nombreEnfants(),
      etablissements: await _nombreEtablissements(),
    );
  }

  /// Hors connexion, le cache local fait foi : un parent sans réseau
  /// doit quand même arriver sur ses enfants.
  Future<int> _nombreEnfants() async {
    try {
      await ChildRepository.instance.loadFromSupabase();
    } catch (_) {
      // Le cache local prend le relais.
    }

    try {
      return ChildRepository.instance.children.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _nombreEtablissements() async {
    try {
      final etablissements =
          await EstablishmentService.instance.myEstablishments();

      return etablissements.length;
    } catch (_) {
      return 0;
    }
  }

  Widget _ecran(DestinationDemarrage destination) {
    switch (destination) {
      // Les trois destinations d'une session ouverte passent par le
      // verrou de l'appareil. Celle du parcours d'entree, non : il n'y
      // a rien a proteger avant la connexion.
      case DestinationDemarrage.accueilParent:
        // Le garde de suppression reste : un compte en cours de
        // suppression ne doit pas atterrir sur ses enfants.
        return const GardeVerrou(
          enfant: GardeSuppression(enfant: HomePage()),
        );

      case DestinationDemarrage.accueilProfessionnel:
        return const GardeVerrou(enfant: EstablishmentHomePage());

      case DestinationDemarrage.choixEspace:
        return const GardeVerrou(enfant: ProfileChoicePage());

      case DestinationDemarrage.concept:
        return const ConceptPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pas de fond impose : l'ecran herite du lin defini par le theme.
    return Scaffold(
      body: const Center(
        child: Text(
          "Bienvenue dans\nKidsRelay",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
