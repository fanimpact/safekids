import 'package:flutter/material.dart';

import 'particulier_home_page.dart';
import 'professional/professional_entry_page.dart';

class ProfileChoicePage extends StatelessWidget {
  const ProfileChoicePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choisissez votre profil',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 80,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProfessionalEntryPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.school,
                ),
                label: const Text(
                  'Professionnel',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 80,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ParticulierHomePage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.family_restroom,
                ),
                label: const Text(
                  'Particulier',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}