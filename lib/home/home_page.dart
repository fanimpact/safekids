import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';

import '../activity_pages/activity_session_start_page.dart';
import '../children/children_page.dart';
import '../emergency_info/emergency_info_child_picker_page.dart';
import '../emergency_info/emergency_info_sheet_page.dart';
import '../emergency_mode/emergency_mode_button_list_page.dart';
import '../emergency_mode/emergency_mode_child_picker_page.dart';
import '../repositories/child_repository.dart';
import '../usage/compteur_usage.dart';
import '../settings/settings_page.dart';
import '../sharing/create_establishment_link_page.dart';
import '../sharing/create_share_link_page.dart';
import '../sharing/establishment_attachments_page.dart';
import '../utils/date_format_utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _offlineMessage(DateTime? lastSyncAt) {
    if (lastSyncAt == null) {
      return 'Hors connexion — données non synchronisées.';
    }

    final hour = lastSyncAt.hour
        .toString()
        .padLeft(2, '0');
    final minute = lastSyncAt.minute
        .toString()
        .padLeft(2, '0');

    return 'Hors connexion — données du '
        '${formatShortDate(lastSyncAt)} à $hour:$minute.';
  }

  Widget _buildOfflineBanner() {
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) {
        if (!ChildRepository.instance.isOffline) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: KidsRelayColors.ambreFond,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KidsRelayColors.ambreBordure,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: KidsRelayColors.ambre,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _offlineMessage(
                      ChildRepository.instance.lastSyncAt,
                    ),
                    style: TextStyle(
                      color: KidsRelayColors.ardoise,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openActivityCreation(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ActivitySessionStartPage(),
      ),
    );
  }

  void _openEmergencyInfo(BuildContext context) {
    final children =
        ChildRepository.instance.children;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun enfant enregistré. Créez d’abord le profil d’un enfant depuis « Mes enfants ».',
          ),
        ),
      );

      return;
    }

    compteurUsage.marquer(FonctionnaliteUsage.ficheSecoursGeneree);

    if (children.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmergencyInfoSheetPage(
            child: children.first,
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyInfoChildPickerPage(),
      ),
    );
  }

  void _openEmergencyMode(BuildContext context) {
    // Marque avant tout le reste, et sans attendre : le Mode Urgence
    // ne doit jamais dependre d'un aller-retour reseau statistique.
    compteurUsage.marquer(FonctionnaliteUsage.modeUrgenceOuvert);

    final children =
        ChildRepository.instance.children;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun enfant enregistré. Créez d’abord le profil d’un enfant depuis « Mes enfants ».',
          ),
        ),
      );

      return;
    }

    if (children.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmergencyModeButtonListPage(
            child: children.first,
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyModeChildPickerPage(),
      ),
    );
  }

  void _openChildrenPage(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ChildrenPage(),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.child_care,
                  ),
                  title: const Text(
                    'Mes enfants',
                  ),
                  onTap: () {
                    _openChildrenPage(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                  ),
                  title: const Text(
                    'Créer un lien de partage',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CreateShareLinkPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.school_outlined,
                  ),
                  title: const Text(
                    'Rattacher à un établissement',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CreateEstablishmentLinkPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fact_check_outlined,
                  ),
                  title: const Text(
                    'Mes rattachements établissement',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const EstablishmentAttachmentsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                  ),
                  title: const Text(
                    'Paramètres',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: KidsRelayColors.urgence,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final child = Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              _buildOfflineBanner(),

              const SizedBox(height: 16),

              const Text(
                'Que souhaitez-vous faire ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 36),

              _buildEmergencyButton(
                label: 'Mode Urgence',
                icon: Icons.emergency,
                onPressed: () {
                  _openEmergencyMode(context);
                },
              ),

              const SizedBox(height: 32),

              _buildMainButton(
                label: 'Préparer une activité',
                icon:
                    Icons.event_available_outlined,
                onPressed: () {
                  _openActivityCreation(context);
                },
              ),

              const SizedBox(height: 18),

              _buildMainButton(
                label:
                    'Informations pour les secours',
                icon:
                    Icons.medical_information_outlined,
                onPressed: () {
                  _openEmergencyInfo(context);
                },
              ),

              const SizedBox(height: 18),

              _buildMainButton(
                label: 'Menu',
                icon: Icons.menu,
                outlined: true,
                onPressed: () {
                  _openMenu(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}