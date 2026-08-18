import 'package:flutter/material.dart';

import '../models/etablissement_data.dart';
import 'claim_attachment_page.dart';
import 'establishment_onboarding_page.dart';
import 'establishment_service.dart';
import 'professional_child_detail_page.dart';
import 'professional_child_repository.dart';

/// Accueil de l'espace professionnel une fois connecté. Phase 2 :
/// un seul établissement possible (celui qu'on a créé), rattachement
/// d'un enfant via un code. Phase 4 : le trombinoscope affiche le
/// vrai profil de chaque enfant (fiche secours, "Ce qu'il faut
/// savoir", profil activités, Mode Urgence via
/// `ProfessionalChildRepository`), avec repli hors-ligne si Supabase
/// est injoignable. L'invitation d'autres membres du personnel arrive
/// dans une étape suivante.
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
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<void> _loadRoster() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ProfessionalChildRepository.instance.loadFromSupabase(
        widget.establishment.id,
      );
    } catch (error) {
      final gotCache = await ProfessionalChildRepository.instance
          .loadFromLocalCacheIfAvailable();

      if (!gotCache && mounted) {
        setState(() {
          _errorMessage =
              'Impossible de charger le trombinoscope. '
              'Vérifiez votre connexion, ou reconnectez-vous si '
              'cela fait plus de 7 jours que vous n’avez pas '
              'synchronisé cet appareil.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _displayName(dynamic child) {
    final firstName =
        child.essentialInformation.identity.firstName as String?;
    final trimmed = firstName?.trim();

    return (trimmed == null || trimmed.isEmpty) ? 'Enfant' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRoster,
      child: ListenableBuilder(
        listenable: ProfessionalChildRepository.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.establishment.nom,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (ProfessionalChildRepository.instance.isOffline) ...[
              const SizedBox(height: 8),
              const Text(
                'Hors connexion — dernières données synchronisées.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

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

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Text(_errorMessage!)
            else if (ProfessionalChildRepository
                .instance.children.isEmpty)
              const Text('Aucun enfant rattaché pour le moment.')
            else
              Column(
                children: [
                  for (final child
                      in ProfessionalChildRepository
                          .instance.children)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.child_care),
                        title: Text(_displayName(child)),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfessionalChildDetailPage(
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
