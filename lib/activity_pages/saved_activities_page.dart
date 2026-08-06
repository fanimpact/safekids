import 'package:flutter/material.dart';

class SavedActivitiesPage extends StatelessWidget {
  const SavedActivitiesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activités enregistrées',
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucune activité enregistrée pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Préparer une activité',
        ),
      ),
    );
  }
}