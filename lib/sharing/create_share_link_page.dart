import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../models/share_link_data.dart';
import '../recommendation_engine/recommendation_engine.dart';
import '../repositories/activity_session_repository.dart';
import '../repositories/child_repository.dart';
import '../utils/date_format_utils.dart';
import 'activity_recommendation_snapshot.dart';

const _selectableFicheTypes = [
  ShareFicheType.secours,
  ShareFicheType.ceQuIlFautSavoir,
  ShareFicheType.recommandationsActivite,
];

enum _ShareDuration {
  jour1('24 heures', Duration(hours: 24)),
  jours3('3 jours', Duration(days: 3)),
  jours7('7 jours', Duration(days: 7));

  const _ShareDuration(this.label, this.duration);

  final String label;
  final Duration duration;
}

class CreateShareLinkPage extends StatefulWidget {
  final CompleteChildProfileData? initialChild;

  const CreateShareLinkPage({super.key, this.initialChild});

  @override
  State<CreateShareLinkPage> createState() =>
      _CreateShareLinkPageState();
}

class _CreateShareLinkPageState
    extends State<CreateShareLinkPage> {
  CompleteChildProfileData? _selectedChild;
  ShareFicheType _selectedFicheType =
      ShareFicheType.secours;
  ShareDestinataire _selectedDestinataire =
      ShareDestinataire.particulier;
  _ShareDuration _selectedDuration = _ShareDuration.jour1;

  bool _isGenerating = false;
  String? _generatedLink;

  // Activités enregistrées pour le partage "recommandations d'activité"
  // (voir corrections_a_faire.md point 5) : chargées pour l'enfant
  // sélectionné, filtrées à celles où il figure.
  String? _activitiesLoadedForChildId;
  bool _loadingActivities = false;
  List<CompleteActivitySessionData> _activities = [];
  CompleteActivitySessionData? _selectedActivity;

  List<CompleteChildProfileData> get _children =>
      ChildRepository.instance.children;

  void _ensureActivitiesLoaded(
    CompleteChildProfileData child,
  ) {
    if (_loadingActivities ||
        _activitiesLoadedForChildId == child.childId) {
      return;
    }

    _loadingActivities = true;
    _activitiesLoadedForChildId = child.childId;

    ActivitySessionRepository.instance.listActivities().then((
      activities,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activities = activities
            .where(
              (activity) =>
                  activity.childIds.contains(child.childId),
            )
            .toList();
        _selectedActivity = null;
        _loadingActivities = false;
      });
    }).catchError((error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activities = [];
        _loadingActivities = false;
      });
    });
  }

  String _activityLabel(
    CompleteActivitySessionData activity,
  ) {
    final name = activity.activityName?.trim();
    final date = activity.date;

    if (name != null && name.isNotEmpty) {
      return date == null
          ? name
          : '$name — ${formatShortDate(date)}';
    }

    return date == null
        ? 'Activité sans nom'
        : 'Activité du ${formatShortDate(date)}';
  }

  String _childDisplayName(
    CompleteChildProfileData child,
  ) {
    final identity =
        child.essentialInformation.identity;

    final parts = [
      identity.firstName,
      identity.lastName,
    ].where(
      (value) =>
          value != null && value.trim().isNotEmpty,
    ).map(
      (value) => value!.trim(),
    );

    final name = parts.join(' ');

    return name.isEmpty ? 'Enfant' : name;
  }

  Future<void> _generateLink() async {
    final child = _selectedChild;

    if (child == null || child.childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez un enfant avant de générer le lien.',
          ),
        ),
      );

      return;
    }

    Map<String, dynamic>? contenuFige;

    if (_selectedFicheType ==
        ShareFicheType.recommandationsActivite) {
      final activity = _selectedActivity;

      if (activity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sélectionnez une activité avant de générer le lien.',
            ),
          ),
        );

        return;
      }

      final recommendationResult = RecommendationEngine()
          .generateRecommendations(activity);

      contenuFige = ActivityRecommendationSnapshot.build(
        activitySession: activity,
        recommendationResult: recommendationResult,
        child: child,
        destinataire: _selectedDestinataire,
      );
    }

    setState(() {
      _isGenerating = true;
      _generatedLink = null;
    });

    final dateExpiration = DateTime.now().toUtc().add(
      _selectedDuration.duration,
    );

    try {
      final response = await Supabase.instance.client
          .from('partages')
          .insert({
            'enfant_id': child.childId,
            'type_fiche': _selectedFicheType.value,
            'date_expiration':
                dateExpiration.toIso8601String(),
            'destinataire': _selectedDestinataire.value,
            'contenu_fige': contenuFige,
            'activite_id': _selectedActivity?.id,
          })
          .select('token')
          .single();

      final token = response['token'] as String;

      final link =
          '${SupabaseConfig.url}/functions/v1/voir-partage?token=$token';

      setState(() {
        _generatedLink = link;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de générer le lien pour le moment. '
            'Vérifiez la connexion Supabase. ($error)',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _copyLink() async {
    final link = _generatedLink;

    if (link == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié.'),
      ),
    );
  }

  Future<void> _sendBySms() async {
    final link = _generatedLink;

    if (link == null) {
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      queryParameters: {
        'body':
            'Voici le lien pour accéder aux informations de l’enfant : $link',
      },
    );

    await launchUrl(uri);
  }

  Future<void> _sendByEmail() async {
    final link = _generatedLink;

    if (link == null) {
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Informations pour l’accompagnement',
        'body':
            'Bonjour,\n\nVoici le lien pour accéder aux informations de l’enfant : $link\n\nCe lien expire automatiquement.',
      },
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    // Sans ça, cette page pourrait continuer d'afficher un enfant
    // supprimé/ajouté ailleurs entre-temps si elle reste en mémoire
    // sous une autre page au lieu d'être rouverte à neuf.
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildActivityPicker() {
    if (_loadingActivities) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activities.isEmpty) {
      return const Text(
        'Aucune activité enregistrée pour cet enfant. '
        'Préparez d’abord une activité pour pouvoir partager '
        'ses recommandations.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return DropdownButtonFormField<CompleteActivitySessionData>(
      initialValue: _selectedActivity,
      decoration: const InputDecoration(
        labelText: 'Activité à partager',
        border: OutlineInputBorder(),
      ),
      items: _activities
          .map(
            (activity) => DropdownMenuItem(
              value: activity,
              child: Text(_activityLabel(activity)),
            ),
          )
          .toList(),
      onChanged: (activity) {
        setState(() {
          _selectedActivity = activity;
          _generatedLink = null;
        });
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (_children.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Créer un lien de partage'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun enfant enregistré. Créez d’abord le profil d’un enfant depuis « Mes enfants ».',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    _selectedChild ??= widget.initialChild ?? _children.first;
    _ensureActivitiesLoaded(_selectedChild!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un lien de partage'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Enfant concerné',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                CompleteChildProfileData>(
              initialValue: _selectedChild,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _children
                  .map(
                    (child) => DropdownMenuItem(
                      value: child,
                      child: Text(
                        _childDisplayName(child),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (child) {
                setState(() {
                  _selectedChild = child;
                  _generatedLink = null;
                });
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Fiche à partager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<ShareFicheType>(
              groupValue: _selectedFicheType,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedFicheType = value;
                  _generatedLink = null;
                });
              },
              child: Column(
                children: [
                  for (final type in _selectableFicheTypes)
                    RadioListTile<ShareFicheType>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(type.label),
                      value: type,
                    ),
                ],
              ),
            ),

            if (_selectedFicheType ==
                ShareFicheType.recommandationsActivite) ...[
              const SizedBox(height: 12),
              _buildActivityPicker(),
            ],

            const SizedBox(height: 20),

            const Text(
              'À qui destinez-vous ce lien ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<ShareDestinataire>(
              groupValue: _selectedDestinataire,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedDestinataire = value;
                  _generatedLink = null;
                });
              },
              child: Column(
                children: [
                  for (final destinataire
                      in ShareDestinataire.values)
                    RadioListTile<ShareDestinataire>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(destinataire.label),
                      value: destinataire,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Durée de validité du lien',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<_ShareDuration>(
              groupValue: _selectedDuration,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedDuration = value;
                  _generatedLink = null;
                });
              },
              child: Column(
                children: [
                  for (final duration
                      in _ShareDuration.values)
                    RadioListTile<_ShareDuration>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(duration.label),
                      value: duration,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _isGenerating ? null : _generateLink,
                child: Text(
                  _isGenerating
                      ? 'Génération en cours...'
                      : 'Générer le lien',
                ),
              ),
            ),

            if (_generatedLink != null) ...[
              const SizedBox(height: 28),

              const Text(
                'Lien généré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SelectableText(_generatedLink!),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(
                      Icons.copy_outlined,
                    ),
                    label: const Text('Copier le lien'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sendBySms,
                    icon: const Icon(
                      Icons.sms_outlined,
                    ),
                    label: const Text('Envoyer par SMS'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sendByEmail,
                    icon: const Icon(
                      Icons.email_outlined,
                    ),
                    label: const Text('Envoyer par e-mail'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
