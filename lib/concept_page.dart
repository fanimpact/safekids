import 'package:flutter/material.dart';
import 'profile_choice_page.dart';

class ConceptPage extends StatelessWidget {
  const ConceptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const Icon(
                Icons.child_care,
                size: 80,
              ),

              const SizedBox(height: 30),

              const Text(
                "Parce que chaque enfant est unique, son accompagnement devrait l’être aussi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Votre enfant a des besoins spécifiques ou une pathologie nécessitant une attention particulière.\n\n"
                "Cette application a été conçue pour que chaque personne qui l’accompagne — famille, école, centre de loisirs, club sportif ou professionnel — puisse accéder facilement aux informations importantes le concernant.\n\n"
                "Notre objectif est de faciliter l’accès de votre enfant aux activités du quotidien, tout en aidant les adultes à l’accompagner avec confiance et en rassurant les parents.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProfileChoicePage(),
    ),
  );
},
                  child: const Text("Continuer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}