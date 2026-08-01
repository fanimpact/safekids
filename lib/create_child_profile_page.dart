import 'package:flutter/material.dart';

class CreateChildProfilePage extends StatefulWidget {
  const CreateChildProfilePage({super.key});

  @override
  State<CreateChildProfilePage> createState() =>
      _CreateChildProfilePageState();
}

class _CreateChildProfilePageState extends State<CreateChildProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une fiche enfant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commençons par les informations principales.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom de l’enfant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _birthDateController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  hintText: 'JJ/MM/AAAA',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lien avec l’enfant',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'parent',
                    child: Text('Parent'),
                  ),
                  DropdownMenuItem(
                    value: 'responsable',
                    child: Text('Responsable légal'),
                  ),
                  DropdownMenuItem(
                    value: 'autre',
                    child: Text('Autre'),
                  ),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}