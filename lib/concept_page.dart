import 'package:flutter/material.dart';
import 'profile_choice_page.dart';

class ConceptPage extends StatelessWidget {
  const ConceptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Le logo plutot qu'un pictogramme generique : c'est le
                // premier ecran que voit quelqu'un qui ne connait pas
                // encore l'application.
                Image.asset(
                  'assets/icone/kidsrelay_premier_plan.png',
                  width: 140,
                  height: 140,
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
                  "Certains enfants vivent avec une pathologie, un trouble du neurodéveloppement (TSA, TDAH, troubles Dys…), un handicap, un appareillage ou toute autre situation nécessitant une attention particulière.\n\n"
                  "KidsRelay permet de rassembler les informations essentielles concernant l’enfant et de les transmettre aux personnes qui l’accueillent : ses besoins au quotidien, et les conduites à tenir en cas de difficulté.\n\n"
                  "Un mode Urgence a été conçu pour faciliter la prise en charge de l’enfant lorsqu’une intervention est nécessaire.\n\n"
                  "Notre objectif : réduire la charge mentale des accompagnants et rassurer les familles en facilitant l’accès aux bonnes informations, au bon moment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProfileChoicePage(),
                        ),
                      );
                    },
                    child: const Text("Continuer"),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
