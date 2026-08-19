import 'package:flutter/material.dart';

import '../care_info/care_info_sheet_page.dart';
import '../emergency_info/emergency_info_sheet_page.dart';
import '../models/complete_child_profile_data.dart';
import '../questionnaire_recap/activity_questionnaire_recap_page.dart';
import '../utils/treatment_audience.dart';
import 'professional_child_repository.dart';
import 'revocation_guard.dart';

/// Les 3 fiches accessibles au personnel pour un enfant rattaché à son
/// établissement — chaque ouverture est journalisée (traçabilité RGPD,
/// voir `journal_consultations_fiche`). Réutilise telles quelles les
/// pages déjà construites côté parent : elles n'ont besoin que d'un
/// `CompleteChildProfileData` et ne font aucun appel réseau propre.
///
/// Le Mode Urgence n'est plus accessible d'ici : promu au niveau
/// supérieur (accueil de l'espace professionnel), avec son propre
/// sélecteur d'enfant, pour éviter le doublon.
class ProfessionalChildDetailPage extends StatelessWidget {
  final CompleteChildProfileData child;

  const ProfessionalChildDetailPage({
    super.key,
    required this.child,
  });

  String get _displayName {
    final firstName =
        child.essentialInformation.identity.firstName?.trim();

    return (firstName == null || firstName.isEmpty)
        ? 'Enfant'
        : firstName;
  }

  void _openFiche(
    BuildContext context, {
    required String typeFiche,
    required WidgetBuilder builder,
  }) {
    final childId = child.childId;

    if (childId != null) {
      ProfessionalChildRepository.instance.logConsultation(
        enfantId: childId,
        typeFiche: typeFiche,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => childId == null
            ? builder(context)
            : RevocationGuard(
                childId: childId,
                child: builder(context),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.medical_information_outlined),
                title: const Text('Fiche secours'),
                subtitle: const Text(
                  'Informations essentielles pour les secours.',
                ),
                onTap: () => _openFiche(
                  context,
                  typeFiche: 'secours',
                  builder: (context) => EmergencyInfoSheetPage(
                    child: child,
                    audience: TreatmentAudience.professionnel,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Ce qu’il faut savoir sur…'),
                subtitle: const Text(
                  'Vigilance au quotidien, hors urgence.',
                ),
                onTap: () => _openFiche(
                  context,
                  typeFiche: 'ce_qu_il_faut_savoir',
                  builder: (context) => CareInfoSheetPage(
                    child: child,
                    audience: TreatmentAudience.professionnel,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist_outlined),
                title: const Text('Profil activités'),
                subtitle: const Text(
                  'Besoins et contraintes pour organiser une activité.',
                ),
                onTap: () => _openFiche(
                  context,
                  typeFiche: 'profil_activites',
                  builder: (context) =>
                      ActivityQuestionnaireRecapPage(child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
