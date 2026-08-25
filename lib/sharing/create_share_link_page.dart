import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/activity_session/complete_activity_session_data.dart';
import '../models/complete_child_profile_data.dart';
import '../models/share_link_data.dart';
import '../recommendation_engine/recommendation_engine.dart';
import '../repositories/activity_session_repository.dart';
import '../repositories/child_repository.dart';
import '../theme/kidsrelay_theme.dart';
import '../utils/date_format_utils.dart';
import 'activity_recommendation_snapshot.dart';
import 'share_link_service.dart';

const _selectableFicheTypes = [
  ShareFicheType.secours,
  ShareFicheType.ceQuIlFautSavoir,
  ShareFicheType.recommandationsActivite,
];

/// Ce que chaque fiche contient vraiment, dit sous son intitule.
///
/// Les intitules seuls ne permettent pas de choisir : "secours" et "ce
/// qu'il faut savoir" sonnent proches alors que leur contenu differe
/// sur deux rubriques precises. Sans repere, on coche la premiere — et
/// la premiere est la plus complete.
///
/// Ces descriptions vivent ici plutot que sur `ShareFicheType` : elles
/// servent au moment du choix, pas ailleurs. La fiche de l'enfant, qui
/// liste les partages en cours, n'en a pas besoin.
const Map<ShareFicheType, String> _descriptionsFiche = {
  ShareFicheType.secours:
      'Pathologies, allergies, traitements, dispositifs, médecin '
      'traitant, contacts à prévenir — et les gestes d’urgence que '
      'vous avez écrits. C’est la fiche la plus complète.',
  ShareFicheType.ceQuIlFautSavoir:
      'La même chose, sans les gestes d’urgence ni le médecin '
      'traitant. Pour qui accompagne au quotidien.',
  ShareFicheType.recommandationsActivite:
      'Ce qu’il faut prévoir pour une activité précise : vigilance, '
      'médicaments d’urgence, adaptations, matériel. Figée au moment '
      'du partage — vos modifications ultérieures n’y apparaîtront '
      'pas.',
};

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
  // Volontairement nul au depart : aucune fiche n'est pre-cochee.
  // La fiche secours l'etait, et c'est la plus sensible — un parent
  // qui appuyait sur "Generer" sans rien lire partageait l'ensemble
  // des donnees de sante de son enfant, consignes d'urgence comprises.
  ShareFicheType? _selectedFicheType;
  ShareDestinataire _selectedDestinataire =
      ShareDestinataire.particulier;
  _ShareDuration _selectedDuration = _ShareDuration.jour1;

  bool _isGenerating = false;
  String? _generatedLink;
  DateTime? _expirationGeneree;

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

    final typeFiche = _selectedFicheType;

    if (typeFiche == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez la fiche a partager avant de generer le lien.',
          ),
        ),
      );

      return;
    }

    if (typeFiche ==
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
      _expirationGeneree = null;
    });

    final dateExpiration = DateTime.now().toUtc().add(
      _selectedDuration.duration,
    );

    try {
      final link = await ShareLinkService.instance.createLink(
        // Non nul : garanti par le garde en tête de cette méthode.
        childId: child.childId!,
        typeFiche: typeFiche.value,
        destinataire: _selectedDestinataire.value,
        dateExpiration: dateExpiration,
        contenuFige: contenuFige,
        activiteId: _selectedActivity?.id,
      );

      setState(() {
        _generatedLink = link;
        _expirationGeneree = dateExpiration.toLocal();
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
          _expirationGeneree = null;
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
                  _expirationGeneree = null;
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

            RadioGroup<ShareFicheType?>(
              groupValue: _selectedFicheType,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedFicheType = value;
                  _generatedLink = null;
                  _expirationGeneree = null;
                });
              },
              child: Column(
                children: [
                  for (final type in _selectableFicheTypes)
                    RadioListTile<ShareFicheType?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(type.label),
                      subtitle: Text(
                        _descriptionsFiche[type] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: KidsRelayColors.ardoiseDouce,
                        ),
                      ),
                      isThreeLine: true,
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

            const SizedBox(height: 6),

            // La question laissait croire qu'elle determinait un niveau
            // d'acces. Elle ne change qu'une phrase sur la fiche : la
            // mention accolee aux traitements.
            const Text(
              'Seule la mention accolée aux traitements change : '
              '« selon vos indications » ou « selon le PAI ». '
              'Le contenu est le même.',
              style: TextStyle(
                fontSize: 14,
                color: KidsRelayColors.ardoiseDouce,
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
                  _expirationGeneree = null;
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
                  _expirationGeneree = null;
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

            // La duree ne dit rien tant qu'elle n'est pas rapportee a une
            // date : "24 heures" a partir de quand ? Le parent doit
            // pouvoir la lire, et la redire a la personne qui recoit le
            // lien.
            const SizedBox(height: 8),

            Text(
              'Le lien cessera de fonctionner le '
              '${formatShortDateTime(DateTime.now().add(_selectedDuration.duration))}. '
              'Il ne peut pas être prolongé : il faudra en créer un '
              'nouveau.',
              style: const TextStyle(
                fontSize: 14,
                color: KidsRelayColors.ardoiseDouce,
              ),
            ),

            const SizedBox(height: 24),

            // En ambre et non en gris : c'est la seule chose de cet
            // ecran qui demande quelque chose au parent, et la seule
            // qu'il ne peut pas deviner. Un lien de partage n'est pas
            // un acces nominatif — il vaut pour qui l'a.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KidsRelayColors.ambreFond,
                border: Border.all(
                  color: KidsRelayColors.ambreBordure,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ce lien s’ouvre sans compte et sans mot de passe. '
                'Toute personne qui le reçoit voit la fiche, et peut '
                'le transmettre à quelqu’un d’autre. Ne l’envoyez '
                'qu’aux personnes concernées.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: KidsRelayColors.ardoise,
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Inactif tant qu'aucune fiche n'est choisie : le geste
                // doit etre delibere, pas un appui par defaut.
                onPressed: _isGenerating || _selectedFicheType == null
                    ? null
                    : _generateLink,
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

              const SizedBox(height: 12),

              if (_expirationGeneree != null)
                Text(
                  'Valable jusqu’au ${formatShortDateTime(_expirationGeneree!)}. '
                  'Passé cette date, le lien n’affiche plus rien.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: KidsRelayColors.ardoiseDouce,
                  ),
                ),

              const SizedBox(height: 8),

              // L'ecran de creation ne disait pas ou couper un lien
              // deja envoye. C'est sur la fiche de l'enfant, et il n'y a
              // aucune raison que le parent le devine.
              const Text(
                'Pour couper ce lien avant cette date, ouvrez la fiche '
                'de l’enfant, section « Partages ». La coupure est '
                'immédiate, y compris pour quelqu’un qui a déjà le '
                'lien — mais ce qui a déjà été lu ou copié reste chez '
                'la personne.',
                style: TextStyle(
                  fontSize: 14,
                  color: KidsRelayColors.ardoiseDouce,
                ),
              ),

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
