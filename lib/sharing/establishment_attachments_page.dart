import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../models/enfant_etablissement_data.dart';
import '../repositories/child_repository.dart';
import '../utils/date_format_utils.dart';
import 'establishment_attachment_service.dart';

/// Vue parent : pour chaque enfant, la liste des établissements
/// auxquels il est (ou a été) rattaché, avec la possibilité de révoquer
/// n'importe quel rattachement à tout moment — le parent garde le
/// contrôle en toutes circonstances, indépendamment pour chaque
/// établissement.
class EstablishmentAttachmentsPage extends StatefulWidget {
  const EstablishmentAttachmentsPage({super.key});

  @override
  State<EstablishmentAttachmentsPage> createState() =>
      _EstablishmentAttachmentsPageState();
}

class _EstablishmentAttachmentsPageState
    extends State<EstablishmentAttachmentsPage> {
  CompleteChildProfileData? _selectedChild;

  Future<List<EnfantEtablissementData>>? _attachmentsFuture;

  List<CompleteChildProfileData> get _children =>
      ChildRepository.instance.children;

  String _childDisplayName(CompleteChildProfileData child) {
    final identity = child.essentialInformation.identity;

    final parts = [identity.firstName, identity.lastName]
        .where(
          (value) => value != null && value.trim().isNotEmpty,
        )
        .map((value) => value!.trim());

    final name = parts.join(' ');

    return name.isEmpty ? 'Enfant' : name;
  }

  void _selectChild(CompleteChildProfileData child) {
    setState(() {
      _selectedChild = child;
      _attachmentsFuture = EstablishmentAttachmentService.instance
          .attachmentsForChild(child.childId!);
    });
  }

  Future<void> _revoke(EnfantEtablissementData attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer ce rattachement ?'),
        content: Text(
          attachment.etablissementNom != null
              ? 'L’établissement « ${attachment.etablissementNom} » '
                  'n’aura plus accès aux informations de cet enfant.'
              : 'Ce code ne pourra plus être utilisé pour rattacher '
                  'l’enfant.',
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
      await EstablishmentAttachmentService.instance.revokeAttachment(
        attachment.id,
      );

      if (!mounted) {
        return;
      }

      _selectChild(_selectedChild!);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de révoquer pour le moment.'),
        ),
      );
    }
  }

  String _statutLabel(EnfantEtablissementData attachment) {
    if (attachment.statut == RattachementStatut.revoque) {
      return 'Révoqué';
    }

    if (attachment.estExpire) {
      return 'Expiré';
    }

    if (attachment.statut == RattachementStatut.enAttente) {
      return 'En attente (code non encore utilisé)';
    }

    return 'Actif — expire le '
        '${formatShortDate(attachment.dateExpiration)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (_children.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes rattachements'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun enfant enregistré.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_selectedChild == null) {
      // On ne peut pas appeler setState() (via _selectChild) pendant
      // le build lui-même : ce widget est reconstruit à chaque
      // notification de ChildRepository (ListenableBuilder), et cette
      // sélection initiale doit attendre la fin du build en cours.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _selectedChild == null &&
            _children.isNotEmpty) {
          _selectChild(_children.first);
        }
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rattachements'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: DropdownButtonFormField<
                  CompleteChildProfileData>(
                initialValue: _selectedChild,
                decoration: const InputDecoration(
                  labelText: 'Enfant',
                  border: OutlineInputBorder(),
                ),
                items: _children
                    .map(
                      (child) => DropdownMenuItem(
                        value: child,
                        child: Text(_childDisplayName(child)),
                      ),
                    )
                    .toList(),
                onChanged: (child) {
                  if (child != null) {
                    _selectChild(child);
                  }
                },
              ),
            ),

            Expanded(
              child: FutureBuilder<List<EnfantEtablissementData>>(
                future: _attachmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Impossible de charger les rattachements.',
                      ),
                    );
                  }

                  final attachments = snapshot.data ?? [];

                  if (attachments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun rattachement pour cet enfant.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];

                      final canRevoke = attachment.statut !=
                          RattachementStatut.revoque;

                      return Card(
                        child: ListTile(
                          title: Text(
                            attachment.etablissementNom ??
                                'Établissement non encore rattaché',
                          ),
                          subtitle: Text(_statutLabel(attachment)),
                          trailing: canRevoke
                              ? TextButton(
                                  onPressed: () =>
                                      _revoke(attachment),
                                  child: const Text('Révoquer'),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
