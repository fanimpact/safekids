import 'package:flutter/material.dart';

import '../models/journal_consultation_data.dart';
import '../utils/date_format_utils.dart';
import 'consultation_journal_service.dart';

/// Journal des consultations d'un enfant — traçabilité RGPD :
/// corrections de l'audit passe 1, "le parent doit pouvoir voir qui a
/// consulté la fiche de son enfant et quand". Lecture seule.
///
/// L'identité affichée est l'établissement, pas la personne précise
/// du personnel : c'est l'établissement qui est responsable de
/// l'accès accordé à ses membres, et exposer l'identité individuelle
/// d'un membre du personnel à un parent n'apporte rien de plus pour
/// la traçabilité recherchée ici.
class ConsultationJournalPage extends StatefulWidget {
  final String childId;
  final String childDisplayName;

  const ConsultationJournalPage({
    super.key,
    required this.childId,
    required this.childDisplayName,
  });

  @override
  State<ConsultationJournalPage> createState() =>
      _ConsultationJournalPageState();
}

class _ConsultationJournalPageState
    extends State<ConsultationJournalPage> {
  late Future<List<JournalConsultationData>> _consultationsFuture;

  @override
  void initState() {
    super.initState();
    _consultationsFuture = ConsultationJournalService.instance
        .consultationsForChild(widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Journal — ${widget.childDisplayName}',
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<JournalConsultationData>>(
          future: _consultationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState !=
                ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Impossible de charger le journal des '
                    'consultations. Vérifiez votre connexion.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final consultations = snapshot.data ?? [];

            if (consultations.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucune consultation enregistrée pour le '
                    'moment. Chaque fois qu’un établissement '
                    'rattaché ouvre une fiche de cet enfant, '
                    'elle apparaîtra ici.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: consultations.length,
              itemBuilder: (context, index) {
                final consultation = consultations[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.visibility_outlined),
                    ),
                    title: Text(
                      consultation.etablissementNom ??
                          'Établissement',
                    ),
                    subtitle: Text(
                      '${typeFicheConsulteeLabel(consultation.typeFiche)} — '
                      '${formatShortDateTime(consultation.consulteLe)}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
