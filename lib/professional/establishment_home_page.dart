import 'package:flutter/material.dart';

import '../models/etablissement_data.dart';
import 'claim_attachment_page.dart';
import 'establishment_onboarding_page.dart';
import 'establishment_service.dart';

/// Accueil de l'espace professionnel une fois connecté. Phase 2 :
/// un seul établissement possible (celui qu'on a créé), trombinoscope
/// simple (prénom uniquement) et rattachement d'un enfant via un code.
/// L'invitation d'autres membres du personnel et la fiche secours/
/// profil activités détaillés arrivent dans les étapes suivantes.
class EstablishmentHomePage extends StatefulWidget {
  const EstablishmentHomePage({super.key});

  @override
  State<EstablishmentHomePage> createState() =>
      _EstablishmentHomePageState();
}

class _EstablishmentHomePageState extends State<EstablishmentHomePage> {
  Future<List<EtablissementData>>? _establishmentsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _establishmentsFuture =
          EstablishmentService.instance.myEstablishments();
    });
  }

  Future<void> _openClaimPage(EtablissementData establishment) async {
    final attached = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClaimAttachmentPage(establishment: establishment),
      ),
    );

    if (attached == true) {
      _reload();
    }
  }

  Future<void> _openOnboarding() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EstablishmentOnboardingPage(),
      ),
    );

    if (created != null) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace professionnel'),
      ),
      body: FutureBuilder<List<EtablissementData>>(
        future: _establishmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger votre établissement. '
                  'Vérifiez votre connexion.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final establishments = snapshot.data ?? [];

          if (establishments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Vous n’êtes rattaché(e) à aucun établissement '
                      'pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _openOnboarding,
                      child: const Text('Créer mon établissement'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Phase 2 : un seul établissement par compte, l'écran de
          // choix entre plusieurs établissements viendra si besoin.
          final establishment = establishments.first;

          return _EstablishmentRoster(
            establishment: establishment,
            onClaimPressed: () => _openClaimPage(establishment),
          );
        },
      ),
    );
  }
}

class _EstablishmentRoster extends StatefulWidget {
  final EtablissementData establishment;
  final VoidCallback onClaimPressed;

  const _EstablishmentRoster({
    required this.establishment,
    required this.onClaimPressed,
  });

  @override
  State<_EstablishmentRoster> createState() =>
      _EstablishmentRosterState();
}

class _EstablishmentRosterState extends State<_EstablishmentRoster> {
  late Future<List<({String enfantId, String prenom})>>
      _rosterFuture;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void didUpdateWidget(covariant _EstablishmentRoster oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.establishment.id != widget.establishment.id) {
      _loadRoster();
    }
  }

  void _loadRoster() {
    _rosterFuture = EstablishmentService.instance.roster(
      widget.establishment.id,
    );
  }

  Future<void> _refresh() async {
    setState(_loadRoster);
    await _rosterFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.establishment.nom,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onClaimPressed,
              icon: const Icon(Icons.add_link),
              label: const Text('Rattacher un enfant'),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Enfants rattachés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          FutureBuilder<List<({String enfantId, String prenom})>>(
            future: _rosterFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final roster = snapshot.data ?? [];

              if (roster.isEmpty) {
                return const Text(
                  'Aucun enfant rattaché pour le moment.',
                );
              }

              return Column(
                children: [
                  for (final enfant in roster)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.child_care),
                        title: Text(enfant.prenom),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
