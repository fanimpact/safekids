import 'package:flutter/material.dart';

import '../models/complete_child_profile_data.dart';
import '../models/activity_session/complete_activity_session_data.dart';
import '../professional/establishment_activity_service.dart';
import '../professional/establishment_home_page.dart';
import '../professional/professional_child_repository.dart';
import '../recommendation_engine/recommendation_engine.dart';
import '../repositories/activity_session_repository.dart';
import '../repositories/child_repository.dart';
import 'activity_recommendations_page.dart';

class SavedActivitiesPage extends StatefulWidget {
  /// Renseigné uniquement côté espace professionnel : liste les
  /// activités de cet établissement au lieu de celles du parent.
  final String? etablissementId;

  const SavedActivitiesPage({
    super.key,
    this.etablissementId,
  });

  @override
  State<SavedActivitiesPage> createState() =>
      _SavedActivitiesPageState();
}

class _SavedActivitiesPageState
    extends State<SavedActivitiesPage> {
  late Future<List<CompleteActivitySessionData>>
      _activitiesFuture;

  bool get _isProfessional =>
      widget.etablissementId != null;

  @override
  void initState() {
    super.initState();

    _activitiesFuture = _isProfessional
        ? EstablishmentActivityService.instance
            .listActivities(widget.etablissementId!)
        : ActivitySessionRepository.instance
            .listActivities();
  }

  Future<void> _openActivity(
    CompleteActivitySessionData activity,
  ) async {
    final CompleteChildProfileData? Function(String)
        findChild = _isProfessional
            ? ProfessionalChildRepository.instance
                .findByChildId
            : ChildRepository.instance.findByChildId;

    Set<String> maskedKeys = const {};

    if (_isProfessional && activity.id != null) {
      maskedKeys = await EstablishmentActivityService
          .instance
          .loadMaskedKeys(activity.id!);
    }

    // Les recommandations ne sont jamais stockées : recalculées ici à
    // partir du profil le plus à jour de chaque enfant, pour ne
    // jamais afficher une information périmée.
    final recommendationResult = RecommendationEngine(
      findChild: findChild,
    ).generateRecommendations(
      activity,
    );

    if (!mounted) {
      return;
    }

    final activiteId = activity.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityRecommendationsPage(
          activitySession: activity,
          recommendationResult: recommendationResult,
          findChild: findChild,
          etablissementId: widget.etablissementId,
          initialMaskedKeys:
              _isProfessional ? maskedKeys : null,
          onToggleMask: (_isProfessional &&
                  activiteId != null)
              ? (cle, masquer) =>
                  EstablishmentActivityService.instance
                      .toggleMask(
                    activiteId: activiteId,
                    cle: cle,
                    masquer: masquer,
                  )
              : null,
          onFinish: _isProfessional
              ? () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EstablishmentHomePage(),
                    ),
                    (route) => route.isFirst,
                  )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activités enregistrées',
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<
            List<CompleteActivitySessionData>>(
          future: _activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState !=
                ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Impossible de charger les activités : '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final activities = snapshot.data ?? [];

            if (activities.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune activité enregistrée.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.event,
                    ),
                    title: Text(
                      activity.activityName ??
                          'Sans nom',
                    ),
                    subtitle: Text(
                      activity.location ??
                          'Lieu non renseigné',
                    ),
                    onTap: () =>
                        _openActivity(activity),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
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
