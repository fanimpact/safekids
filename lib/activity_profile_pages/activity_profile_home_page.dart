import 'package:flutter/material.dart';

import '../controllers/activity_profile_controller.dart';
import 'aquatic_activity_page.dart';
import 'clothing_page.dart';
import 'communication_page.dart';
import 'overnight_stay_page.dart';
import 'safety_page.dart';
import 'toilets_page.dart';
import 'transitions_page.dart';
import 'transport_page.dart';
import 'walking_effort_page.dart';

class ActivityProfileHomePage extends StatelessWidget {
  final ActivityProfileController activityProfileController;

  const ActivityProfileHomePage({
    super.key,
    required this.activityProfileController,
  });

  Future<void> _openPage(
    BuildContext context,
    Widget page,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  Widget _buildSectionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () => _openPage(
          context,
          page,
        ),
      ),
    );
  }

  void _saveProfile(BuildContext context) {
    activityProfileController.validateDraft();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profil Activités enregistré.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Activités',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Complétez uniquement les rubriques qui concernent votre enfant.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTile(
              context: context,
              title: 'Activité aquatique',
              icon: Icons.pool,
              page: AquaticActivityPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Transport',
              icon: Icons.directions_bus,
              page: TransportPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Marche prolongée / effort physique',
              icon: Icons.directions_walk,
              page: WalkingEffortPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Séjour avec nuitée',
              icon: Icons.bed,
              page: OvernightStayPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Changement de tenue',
              icon: Icons.checkroom,
              page: ClothingPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Toilettes',
              icon: Icons.wc,
              page: ToiletsPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Communication',
              icon: Icons.chat_bubble_outline,
              page: CommunicationPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Transitions / changements d’activité',
              icon: Icons.sync_alt,
              page: TransitionsPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            _buildSectionTile(
              context: context,
              title: 'Sécurité',
              icon: Icons.health_and_safety,
              page: SafetyPage(
                activityProfileController:
                    activityProfileController,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () => _saveProfile(context),
              child: const Text(
                'Enregistrer le profil Activités',
              ),
            ),
          ],
        ),
      ),
    );
  }
}