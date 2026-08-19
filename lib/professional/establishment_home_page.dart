import 'package:flutter/material.dart';

import '../activity_pages/activities_home_page.dart';
import '../models/etablissement_data.dart';
import 'claim_attachment_page.dart';
import 'establishment_child_list_page.dart';
import 'establishment_onboarding_page.dart';
import 'establishment_service.dart';
import 'professional_child_repository.dart';
import 'professional_emergency_mode_child_picker_page.dart';
import 'team_management_page.dart';

/// Accueil de l'espace professionnel une fois connecté, organisé
/// selon l'usage réel d'un membre du personnel qui a plusieurs enfants
/// rattachés : il raisonne d'abord par sortie, pas par enfant.
/// 1. Préparer une activité (le plus fréquent)
/// 2. Mode Urgence (sélecteur d'enfant, comme côté particulier)
/// 3. Fiche secours et données de l'enfant (trombinoscope)
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

  Future<void> _reload() async {
    // Active toute invitation d'équipe en attente pour ce compte
    // avant de charger la liste, pour qu'une invitation tout juste
    // acceptée apparaisse immédiatement (voir
    // rpc_activer_invitations_en_attente).
    try {
      await EstablishmentService.instance
          .activatePendingInvitations();
    } catch (_) {
      // Non bloquant : au pire, l'invitation s'activera à la
      // prochaine connexion.
    }

    if (!mounted) {
      return;
    }

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

          return _EstablishmentMenu(
            establishment: establishment,
            onClaimPressed: () => _openClaimPage(establishment),
          );
        },
      ),
    );
  }
}

class _EstablishmentMenu extends StatefulWidget {
  final EtablissementData establishment;
  final VoidCallback onClaimPressed;

  const _EstablishmentMenu({
    required this.establishment,
    required this.onClaimPressed,
  });

  @override
  State<_EstablishmentMenu> createState() =>
      _EstablishmentMenuState();
}

class _EstablishmentMenuState extends State<_EstablishmentMenu> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void didUpdateWidget(covariant _EstablishmentMenu oldWidget) {
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

  Widget _buildMenuTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: color == null
            ? null
            : FilledButton.styleFrom(
                backgroundColor: color,
              ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.establishment.nom,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClaimPressed,
                  icon: const Icon(Icons.add_link),
                  tooltip: 'Rattacher un enfant',
                ),
              ],
            ),

            if (ProfessionalChildRepository.instance.isOffline) ...[
              const SizedBox(height: 4),
              const Text(
                'Hors connexion — dernières données synchronisées.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!),
            ],

            const SizedBox(height: 24),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildMenuTile(
                context: context,
                label: 'Préparer une activité',
                icon: Icons.event_available,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivitiesHomePage(
                        etablissementId: widget.establishment.id,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildMenuTile(
                context: context,
                label: 'Mode Urgence',
                icon: Icons.emergency_outlined,
                color: Colors.red.shade700,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProfessionalEmergencyModeChildPickerPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildMenuTile(
                context: context,
                label: 'Fiche secours et données de l’enfant',
                icon: Icons.folder_shared_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EstablishmentChildListPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildMenuTile(
                context: context,
                label: 'Gérer l’équipe',
                icon: Icons.groups_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamManagementPage(
                        etablissementId: widget.establishment.id,
                        etablissementNom: widget.establishment.nom,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
