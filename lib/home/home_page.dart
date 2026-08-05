import 'package:flutter/material.dart';

import '../children/children_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showComingSoon(
    BuildContext context,
    String featureName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$featureName sera créé à l’étape suivante.',
        ),
      ),
    );
  }

  void _openChildrenPage(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChildrenPage(),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
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
                  leading: const Icon(Icons.child_care),
                  title: const Text('Mes enfants'),
                  onTap: () {
                    _openChildrenPage(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Partages actifs'),
                  onTap: () {
                    Navigator.pop(context);

                    _showComingSoon(
                      context,
                      'Les partages actifs',
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Paramètres'),
                  onTap: () {
                    Navigator.pop(context);

                    _showComingSoon(
                      context,
                      'Les paramètres',
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

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),

              const Text(
                'Que souhaitez-vous faire ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 36),

              _buildMainButton(
                label: 'Préparer une activité',
                icon: Icons.event_available_outlined,
                onPressed: () {
                  _showComingSoon(
                    context,
                    'La préparation d’une activité',
                  );
                },
              ),

              const SizedBox(height: 18),

              _buildMainButton(
                label: 'Mode Urgence',
                icon: Icons.emergency_outlined,
                onPressed: () {
                  _showComingSoon(
                    context,
                    'Le mode Urgence',
                  );
                },
              ),

              const SizedBox(height: 18),

              _buildMainButton(
                label: 'Informations pour les secours',
                icon: Icons.medical_information_outlined,
                onPressed: () {
                  _showComingSoon(
                    context,
                    'Les informations pour les secours',
                  );
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