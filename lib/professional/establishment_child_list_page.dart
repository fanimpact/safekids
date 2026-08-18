import 'package:flutter/material.dart';

import 'professional_child_detail_page.dart';
import 'professional_child_repository.dart';

/// Trombinoscope de l'établissement — accès à la fiche secours, "Ce
/// qu'il faut savoir" et au profil activités de chaque enfant rattaché.
/// Le chargement/rafraîchissement du trombinoscope est fait une seule
/// fois au niveau de `EstablishmentHomePage`, partagé avec les deux
/// autres entrées (Préparer une activité, Mode Urgence) : cette page
/// se contente d'écouter `ProfessionalChildRepository`.
class EstablishmentChildListPage extends StatelessWidget {
  const EstablishmentChildListPage({super.key});

  String _displayName(dynamic child) {
    final firstName =
        child.essentialInformation.identity.firstName
            as String?;
    final trimmed = firstName?.trim();

    return (trimmed == null || trimmed.isEmpty)
        ? 'Enfant'
        : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enfants rattachés'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProfessionalChildRepository.instance,
          builder: (context, _) {
            final children =
                ProfessionalChildRepository.instance.children;

            if (children.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun enfant rattaché pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (ProfessionalChildRepository
                    .instance.isOffline) ...[
                  const Text(
                    'Hors connexion — dernières données synchronisées.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final child in children)
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
            );
          },
        ),
      ),
    );
  }
}
