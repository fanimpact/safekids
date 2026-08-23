import 'package:flutter/material.dart';
import '../auth/supabase_auth_provider.dart';
import '../services/service_exception.dart';

import '../models/membre_etablissement_data.dart';
import 'establishment_service.dart';

String _roleLabel(RoleEtablissement role) {
  switch (role) {
    case RoleEtablissement.directeur:
      return 'Directeur/directrice';
    case RoleEtablissement.adjoint:
      return 'Adjoint(e)';
    case RoleEtablissement.membre:
      return 'Membre';
  }
}

String _statutLabel(MembreEtablissementData membre) {
  switch (membre.statut) {
    case StatutMembre.invite:
      return 'Invité(e) — pas encore connecté(e)';
    case StatutMembre.revoque:
      return 'Accès révoqué';
    case StatutMembre.actif:
      return 'Actif/active';
  }
}

/// Écran "Gérer l'équipe" (corrections de l'inventaire du 19/08/2026,
/// point 10) : inviter un collègue par email, changer un rôle,
/// révoquer un accès. Directeur et adjoint ont exactement les mêmes
/// pouvoirs ici — un membre simple voit l'équipe mais ne peut rien y
/// faire (voir le plan de l'espace professionnel, §2).
class TeamManagementPage extends StatefulWidget {
  final String etablissementId;
  final String etablissementNom;

  const TeamManagementPage({
    super.key,
    required this.etablissementId,
    required this.etablissementNom,
  });

  @override
  State<TeamManagementPage> createState() =>
      _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  Future<List<MembreEtablissementData>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _membersFuture = EstablishmentService.instance.teamMembers(
        widget.etablissementId,
      );
    });
  }

  String? get _myUserId =>
      SupabaseAuthProvider.instance.currentUserId;

  RoleEtablissement? _myRole(
    List<MembreEtablissementData> members,
  ) {
    for (final membre in members) {
      if (membre.userId == _myUserId &&
          membre.statut == StatutMembre.actif) {
        return membre.role;
      }
    }

    return null;
  }

  bool _canManage(List<MembreEtablissementData> members) {
    final role = _myRole(members);

    return role == RoleEtablissement.directeur ||
        role == RoleEtablissement.adjoint;
  }

  /// Affiche un message déjà rédigé pour la personne.
  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Affiche l'échec d'une opération serveur.
  ///
  /// Les services de l'espace professionnel remontent les refus de la
  /// base sous forme de `ServiceException`, dont le message est écrit
  /// pour être lu (ex. « Vous n'avez pas les droits pour inviter un
  /// membre »). Tout le reste — panne réseau, bogue — reste générique :
  /// on n'affiche jamais une exception brute.
  void _showError(Object error) {
    _showMessage(
      error is ServiceException
          ? error.message
          : 'Une erreur est survenue.',
    );
  }

  Future<void> _openInviteDialog() async {
    final emailController = TextEditingController();
    var selectedRole = RoleEtablissement.membre;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inviter un collègue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoleEtablissement>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: RoleEtablissement.membre,
                    child: Text('Membre'),
                  ),
                  DropdownMenuItem(
                    value: RoleEtablissement.adjoint,
                    child: Text('Adjoint(e)'),
                  ),
                ],
                onChanged: (role) {
                  if (role != null) {
                    setDialogState(() {
                      selectedRole = role;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    final email = emailController.text.trim();

    if (email.isEmpty) {
      // Message de validation de saisie, pas un échec serveur : il
      // était jusqu'ici enveloppé dans une fausse PostgrestException
      // pour emprunter le chemin d'affichage des erreurs (23/08/2026).
      _showMessage('Saisissez une adresse email.');
      return;
    }

    try {
      await EstablishmentService.instance.inviteMember(
        etablissementId: widget.etablissementId,
        email: email,
        role: selectedRole,
      );

      _reload();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _changeRole(
    MembreEtablissementData membre,
  ) async {
    final nouveauRole = await showDialog<RoleEtablissement>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Rôle de ${membre.email}'),
        children: [
          for (final role in RoleEtablissement.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Text(_roleLabel(role)),
            ),
        ],
      ),
    );

    if (nouveauRole == null || nouveauRole == membre.role) {
      return;
    }

    try {
      await EstablishmentService.instance.changeRole(
        membreId: membre.id,
        nouveauRole: nouveauRole,
      );

      _reload();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _revoke(MembreEtablissementData membre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer cet accès ?'),
        content: Text(
          '${membre.email} n’aura plus accès à '
          '${widget.etablissementNom}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await EstablishmentService.instance.revokeMember(membre.id);
      _reload();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer l’équipe'),
      ),
      body: FutureBuilder<List<MembreEtablissementData>>(
        future: _membersFuture,
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
                  'Impossible de charger l’équipe. '
                  'Vérifiez votre connexion.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final members = snapshot.data ?? [];
          final canManage = _canManage(members);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final membre in members)
                  Card(
                    child: ListTile(
                      title: Text(membre.email),
                      subtitle: Text(
                        '${_roleLabel(membre.role)} — '
                        '${_statutLabel(membre)}',
                      ),
                      trailing: (canManage &&
                              membre.userId != _myUserId &&
                              membre.statut == StatutMembre.actif)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.badge_outlined,
                                  ),
                                  tooltip: 'Changer de rôle',
                                  onPressed: () =>
                                      _changeRole(membre),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                  ),
                                  tooltip: 'Révoquer',
                                  onPressed: () => _revoke(membre),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                if (canManage) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openInviteDialog,
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text('Inviter un collègue'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
