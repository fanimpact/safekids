import 'package:flutter/material.dart';

import '../theme/kidsrelay_theme.dart';

import '../activity_pages/activities_home_page.dart';
import '../activity_profile_pages/activity_profile_entry_page.dart';
import '../auth/supabase_auth_provider.dart';
import '../care_info/care_info_sheet_page.dart';
import '../controllers/activity_profile_controller.dart';
import '../controllers/transmission_controller.dart';
import '../emergency_info/emergency_info_sheet_page.dart';
import '../emergency_mode/emergency_mode_button_list_page.dart';
import '../models/activity_profile_draft.dart';
import '../models/child_profile_draft.dart';
import '../models/complete_child_profile_data.dart';
import '../models/enfant_confiance_data.dart';
import '../models/enfant_etablissement_data.dart';
import '../models/share_link_data.dart';
import '../questionnaire_recap/activity_questionnaire_recap_page.dart';
import '../questionnaire_recap/medical_questionnaire_recap_page.dart';
import '../repositories/child_repository.dart';
import '../sharing/consultation_journal_page.dart';
import '../sharing/create_share_link_page.dart';
import '../sharing/enfant_confiance_service.dart';
import '../sharing/establishment_attachment_service.dart';
import '../sharing/share_link_service.dart';
import '../transmission_pages/identity_page.dart';
import '../utils/age_utils.dart';
import '../utils/child_name_utils.dart';
import '../utils/date_format_utils.dart';
import '../utils/treatment_audience.dart';

class ChildProfilePage extends StatefulWidget {
  final CompleteChildProfileData child;

  const ChildProfilePage({
    super.key,
    required this.child,
  });

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  CompleteChildProfileData get child => widget.child;

  Future<List<ShareLinkData>>? _shareLinksFuture;
  Future<List<EnfantEtablissementData>>? _attachmentsFuture;
  Future<List<EnfantConfianceData>>? _trustedPeopleFuture;

  // Copie résolue de _trustedPeopleFuture, utilisée pour savoir tout
  // de suite (sans reconstruire tout un FutureBuilder) si la personne
  // connectée peut modifier cette fiche — voir _canWrite. `null` tant
  // que le chargement n'est pas terminé : dans ce cas, _canWrite se
  // comporte comme avant (accès complet), le temps que ça se résolve.
  List<EnfantConfianceData>? _trustedPeople;

  @override
  void initState() {
    super.initState();
    _loadPartages();
  }

  /// Le fournisseur lève une AssertionError synchrone quand
  /// l'initialisation n'a pas eu lieu (cas des tests de widgets) — voir
  /// le même garde-fou dans _loadPartages.
  String? get _currentUserId {
    try {
      return SupabaseAuthProvider.instance.currentUserId;
    } catch (_) {
      return null;
    }
  }

  /// Vrai si la personne connectée est le parent propriétaire de cet
  /// enfant (par opposition à une personne de confiance invitée —
  /// corrections de l'inventaire du 19/08/2026, point 9). `userId` est
  /// `null` pour les profils construits sans Supabase (tests, données
  /// historiques) : dans ce cas, on se comporte comme avant (accès
  /// complet), pour ne rien changer au comportement déjà couvert par
  /// les tests existants.
  bool get _isOwner {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      // Session inconnue (ex. tests de widgets sans Supabase
      // initialisé) : comportement par défaut, comme avant cette
      // fonctionnalité.
      return true;
    }

    final ownerId = child.userId;
    return ownerId == null || ownerId == currentUserId;
  }

  bool get _canWrite {
    if (_isOwner) {
      return true;
    }

    final people = _trustedPeople;

    if (people == null) {
      return true;
    }

    final mine = people.where(
      (person) => person.userId == _currentUserId,
    );

    if (mine.isEmpty) {
      return true;
    }

    return mine.first.niveauAcces ==
        NiveauAccesConfiance.lectureEcriture;
  }

  void _loadPartages() {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    final shareLinksFuture =
        ShareLinkService.instance.linksForChild(childId);
    final attachmentsFuture = EstablishmentAttachmentService.instance
        .attachmentsForChild(childId);
    final trustedPeopleFuture = EnfantConfianceService.instance
        .trustedPeopleForChild(childId);

    // `.ignore()` marque immédiatement ces futures comme "gérées" pour
    // Dart, en plus du traitement normal fait juste après par les
    // FutureBuilder de _buildPartagesSection : sans ça, un rejet (ex.
    // pas de connexion Supabase) remonte comme erreur non interceptée
    // au niveau de la zone du test au lieu de rester local à l'écran.
    shareLinksFuture.ignore();
    attachmentsFuture.ignore();
    trustedPeopleFuture.ignore();

    trustedPeopleFuture.then((people) {
      if (mounted) {
        setState(() {
          _trustedPeople = people;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _trustedPeople = [];
        });
      }
    });

    setState(() {
      _shareLinksFuture = shareLinksFuture;
      _attachmentsFuture = attachmentsFuture;
      _trustedPeopleFuture = trustedPeopleFuture;
    });
  }

  String get _displayName {
    return childFullName(
      child.essentialInformation.identity,
    );
  }

  String get _age {
    return formatAge(
          child
              .essentialInformation
              .identity
              .dateOfBirth,
        ) ??
        '';
  }

  List<String> get _pathologies {
    final values = child
        .essentialInformation
        .pathologies
        .map(
          (pathology) => pathology.name?.trim(),
        )
        .where(
          (name) => name != null && name.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ['Aucune'];
    }

    return values;
  }

  List<String> get _allergies {
    final values = child
        .essentialInformation
        .allergies
        .map(
          (allergy) => allergy.label?.trim(),
        )
        .where(
          (allergen) =>
              allergen != null && allergen.isNotEmpty,
        )
        .cast<String>()
        .toList();

    if (values.isEmpty) {
      return ['Aucune'];
    }

    return values;
  }

  void _openActivities(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesHomePage(
          selectedChild: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bulletList(
    List<String> values,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.only(
                bottom: 6,
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _statusLine({
    required bool completed,
    required String completedText,
    required String incompleteText,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          completed
              ? Icons.check_circle
              : Icons.hourglass_top,
          color: completed
              ? KidsRelayColors.vertPin
              : KidsRelayColors.ambre,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            completed
                ? completedText
                : incompleteText,
            style: const TextStyle(
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(alpha: 0.15),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onPressed,
      ),
    );
  }

  void _openActivityProfile(BuildContext context) {
    final existingProfile = child.activityProfile;

    final activityProfileController = ActivityProfileController(
      initialDraft: existingProfile == null
          ? ActivityProfileDraft(
              userId: child.userId,
              childId: child.childId,
            )
          : ActivityProfileDraft.fromActivityProfileData(
              existingProfile,
              userId: child.userId,
              childId: child.childId,
            ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProfileEntryPage(
          activityProfileController: activityProfileController,
        ),
      ),
    );
  }

  void _showTemporaryMessage({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Future<void> _openCreateShareLink(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateShareLinkPage(
          initialChild: child,
        ),
      ),
    );

    _loadPartages();
  }

  Future<void> _revokeShareLink(
    BuildContext context,
    ShareLinkData link,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer ce lien de partage ?'),
        content: Text(
          'Le lien « ${link.ficheType.label} » cessera de '
          'fonctionner immédiatement pour toute personne qui '
          'l’aurait reçu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ShareLinkService.instance.revokeLink(link.id);
      _loadPartages();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showTemporaryMessage(
        context: context,
        message: 'Impossible de révoquer ce lien pour le moment.',
      );
    }
  }

  Future<void> _revokeAttachment(
    BuildContext context,
    EnfantEtablissementData attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer ce rattachement ?'),
        content: Text(
          attachment.etablissementNom != null
              ? 'L’établissement « ${attachment.etablissementNom} » '
                  'n’aura plus accès aux informations de cet enfant.'
              : 'Ce code ne pourra plus être utilisé pour rattacher '
                  'l’enfant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await EstablishmentAttachmentService.instance.revokeAttachment(
        attachment.id,
      );
      _loadPartages();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showTemporaryMessage(
        context: context,
        message:
            'Impossible de révoquer ce rattachement pour le moment.',
      );
    }
  }

  String _shareLinkStatusLabel(ShareLinkData link) {
    final expiration =
        'Expire le ${formatShortDate(link.dateExpiration)}';

    if (link.dateDerniereConsultation == null) {
      return '$expiration — jamais consulté';
    }

    return '$expiration — consulté le '
        '${formatShortDate(link.dateDerniereConsultation!)}';
  }

  String _attachmentStatusLabel(EnfantEtablissementData attachment) {
    if (attachment.statut == RattachementStatut.enAttente) {
      return 'En attente (code non encore utilisé)';
    }

    return 'Rattaché — expire le '
        '${formatShortDate(attachment.dateExpiration)}';
  }

  Widget _partageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRevoke,
    VoidCallback? onSecondaryAction,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSecondaryAction != null)
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Changer le niveau d’accès',
                onPressed: onSecondaryAction,
              ),
            TextButton(
              onPressed: onRevoke,
              child: const Text('Révoquer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartagesSection(BuildContext context) {
    if (child.childId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<ShareLinkData>>(
      future: _shareLinksFuture,
      builder: (context, shareLinksSnapshot) {
        return FutureBuilder<List<EnfantEtablissementData>>(
          future: _attachmentsFuture,
          builder: (context, attachmentsSnapshot) {
            final stillLoading = shareLinksSnapshot.connectionState !=
                    ConnectionState.done ||
                attachmentsSnapshot.connectionState !=
                    ConnectionState.done;

            if (stillLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (shareLinksSnapshot.hasError ||
                attachmentsSnapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Impossible de charger les partages en cours.',
                ),
              );
            }

            final activeLinks = (shareLinksSnapshot.data ?? [])
                .where((link) => !link.estExpire)
                .toList();

            final activeAttachments = (attachmentsSnapshot.data ?? [])
                .where(
                  (attachment) =>
                      attachment.statut != RattachementStatut.revoque &&
                      !attachment.estExpire,
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activeLinks.isEmpty && activeAttachments.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.people),
                      ),
                      title: Text(
                        'Aucun accès en cours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Personne d’autre que vous n’a accès aux '
                        'informations de cet enfant pour le moment.',
                      ),
                    ),
                  ),

                for (final link in activeLinks) ...[
                  _partageCard(
                    icon: Icons.link,
                    title: link.ficheType.label,
                    subtitle: _shareLinkStatusLabel(link),
                    onRevoke: () => _revokeShareLink(context, link),
                  ),
                  const SizedBox(height: 8),
                ],

                for (final attachment in activeAttachments) ...[
                  _partageCard(
                    icon: Icons.school,
                    title: attachment.etablissementNom ??
                        'Établissement non encore rattaché',
                    subtitle: _attachmentStatusLabel(attachment),
                    onRevoke: () =>
                        _revokeAttachment(context, attachment),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () => _openCreateShareLink(context),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Créer un lien de partage'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _accessLevelLabel(NiveauAccesConfiance niveau) {
    switch (niveau) {
      case NiveauAccesConfiance.lecture:
        return 'Consultation seule';
      case NiveauAccesConfiance.lectureEcriture:
        return 'Consultation et modification';
    }
  }

  String _confianceStatusLabel(EnfantConfianceData confiance) {
    switch (confiance.statut) {
      case StatutConfiance.invite:
        return '${_accessLevelLabel(confiance.niveauAcces)} — '
            'invitation en attente';
      case StatutConfiance.revoque:
        return 'Accès révoqué';
      case StatutConfiance.actif:
        return _accessLevelLabel(confiance.niveauAcces);
    }
  }

  Future<void> _openInviteTrustedPersonDialog(
    BuildContext context,
  ) async {
    final childId = child.childId;

    if (childId == null) {
      return;
    }

    final emailController = TextEditingController();
    var selectedLevel = NiveauAccesConfiance.lecture;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inviter une personne de confiance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NiveauAccesConfiance>(
                initialValue: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau d’accès',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: NiveauAccesConfiance.lecture,
                    child: Text(
                      _accessLevelLabel(
                        NiveauAccesConfiance.lecture,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: NiveauAccesConfiance.lectureEcriture,
                    child: Text(
                      _accessLevelLabel(
                        NiveauAccesConfiance.lectureEcriture,
                      ),
                    ),
                  ),
                ],
                onChanged: (level) {
                  if (level != null) {
                    setDialogState(() {
                      selectedLevel = level;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showTemporaryMessage(
        context: context,
        message: 'Saisissez une adresse email.',
      );
      return;
    }

    try {
      await EnfantConfianceService.instance.invite(
        childId: childId,
        email: email,
        niveauAcces: selectedLevel,
      );

      _loadPartages();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showTemporaryMessage(
        context: context,
        message: 'Impossible d’envoyer l’invitation pour le moment.',
      );
    }
  }

  Future<void> _changeTrustedPersonAccessLevel(
    BuildContext context,
    EnfantConfianceData confiance,
  ) async {
    final nouveauNiveau = await showDialog<NiveauAccesConfiance>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Niveau d’accès de ${confiance.email}'),
        children: [
          for (final niveau in NiveauAccesConfiance.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, niveau),
              child: Text(_accessLevelLabel(niveau)),
            ),
        ],
      ),
    );

    if (nouveauNiveau == null ||
        nouveauNiveau == confiance.niveauAcces) {
      return;
    }

    try {
      await EnfantConfianceService.instance.changeAccessLevel(
        confianceId: confiance.id,
        niveauAcces: nouveauNiveau,
      );

      _loadPartages();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showTemporaryMessage(
        context: context,
        message: 'Impossible de modifier ce niveau pour le moment.',
      );
    }
  }

  Future<void> _revokeTrustedPerson(
    BuildContext context,
    EnfantConfianceData confiance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer cet accès ?'),
        content: Text(
          '${confiance.email} n’aura plus accès à la fiche de '
          '$_displayName.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await EnfantConfianceService.instance.revoke(confiance.id);
      _loadPartages();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showTemporaryMessage(
        context: context,
        message: 'Impossible de révoquer cet accès pour le moment.',
      );
    }
  }

  Widget _buildTrustedPeopleSection(BuildContext context) {
    if (!_isOwner || child.childId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<EnfantConfianceData>>(
      future: _trustedPeopleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Impossible de charger les personnes de confiance.',
            ),
          );
        }

        final people = (snapshot.data ?? [])
            .where(
              (person) => person.statut != StatutConfiance.revoque,
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (people.isEmpty)
              const Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.diversity_3_outlined),
                  ),
                  title: Text(
                    'Aucune personne de confiance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Vous pouvez partager cette fiche avec un '
                    'co-parent ou un tuteur (jusqu’à 2 personnes).',
                  ),
                ),
              ),

            for (final confiance in people) ...[
              _partageCard(
                icon: Icons.diversity_3_outlined,
                title: confiance.email,
                subtitle: _confianceStatusLabel(confiance),
                onRevoke: () =>
                    _revokeTrustedPerson(context, confiance),
                onSecondaryAction: () =>
                    _changeTrustedPersonAccessLevel(
                  context,
                  confiance,
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (people.length < 2) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _openInviteTrustedPersonDialog(context),
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text(
                  'Inviter une personne de confiance',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteProfile(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Supprimer ce profil ?',
        ),
        content: Text(
          'Le profil de $_displayName sera définitivement supprimé, ainsi que toutes les informations enregistrées (profil santé, profil activités, fiche secours). Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            // Ardoise et non rouge : supprimer un profil est une action
            // destructrice, pas une urgence vitale. Le poids vient du
            // libelle et de la confirmation demandee juste avant.
            style: TextButton.styleFrom(
              foregroundColor: KidsRelayColors.ardoise,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final childId = child.childId;

    if (childId == null) {
      return;
    }

    // Indicateur bloquant pendant la suppression : sans ça, une requête
    // un peu lente donne l'impression que le bouton n'a rien fait.
    // `barrierDismissible: false` empêche seulement de fermer la
    // fenêtre en cliquant à côté — un raccourci "retour" (Échap, etc.)
    // pouvait quand même la faire disparaître pendant que la
    // suppression continuait en arrière-plan sans plus jamais donner
    // de nouvelles : `PopScope(canPop: false)` bloque aussi ça.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      await ChildRepository.instance.deleteChild(
        childId,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      // Referme l'indicateur de chargement.
      Navigator.pop(context);

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Suppression impossible',
          ),
          content: Text(
            'Le profil n\'a pas pu être supprimé. Vérifiez la '
            'connexion et réessayez.\n\nDétail : $error',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      return;
    }

    if (!context.mounted) {
      return;
    }

    // Referme l'indicateur de chargement.
    Navigator.pop(context);

    Navigator.pop(context);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayName,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.child_care,
              size: 72,
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_age.isNotEmpty) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _age,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            _sectionTitle(
              'Pathologies',
            ),

            _bulletList(
              _pathologies,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              'Allergies',
            ),

            _bulletList(
              _allergies,
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'Utiliser ce profil',
            ),

            _actionButton(
              icon: Icons.event,
              color: KidsRelayColors.vertPin,
              title: 'Préparer une activité',
              subtitle:
                  'Créer une préparation adaptée à cet enfant.',
              onPressed: () =>
                  _openActivities(context),
            ),

            _actionButton(
              icon: Icons.warning,
              color: KidsRelayColors.urgence,
              title: 'Mode Urgence',
              subtitle:
                  'Accéder immédiatement au protocole d’urgence.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyModeButtonListPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.description,
              color: KidsRelayColors.vertPin,
              title:
                  'Informations pour les secours',
              subtitle:
                  'Afficher la fiche destinée aux services de secours.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyInfoSheetPage(
                      child: child,
                      audience: _isOwner
                          ? TreatmentAudience.owner
                          : TreatmentAudience.particulier,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.fact_check_outlined,
              color: KidsRelayColors.vertPin,
              title:
                  'Questionnaire santé (récapitulatif)',
              subtitle:
                  'Voir et imprimer toutes les questions et réponses du questionnaire santé.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MedicalQuestionnaireRecapPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.checklist_rtl,
              color: KidsRelayColors.vertPin,
              title:
                  'Questionnaire activité (récapitulatif)',
              subtitle:
                  'Voir et imprimer toutes les questions et réponses du profil Activités.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ActivityQuestionnaireRecapPage(
                      child: child,
                    ),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.family_restroom,
              color: KidsRelayColors.vertPin,
              title: "Ce qu'il faut savoir sur $_displayName",
              subtitle:
                  'Informations à connaître pour un accompagnement de plusieurs jours (ex. grands-parents).',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CareInfoSheetPage(
                      child: child,
                      audience: _isOwner
                          ? TreatmentAudience.owner
                          : TreatmentAudience.particulier,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            _sectionTitle(
              'État du profil',
            ),

            _statusLine(
              completed:
                  child.essentialInformationCompleted,
              completedText:
                  'Informations essentielles : complétées',
              incompleteText:
                  'Informations essentielles : à compléter',
            ),

            const SizedBox(height: 12),

            _statusLine(
              completed:
                  child.activityProfileCompleted,
              completedText:
                  'Profil Activités : complété',
              incompleteText:
                  'Profil Activités : à compléter',
            ),

            if (_isOwner) ...[
              const SizedBox(height: 36),

              _sectionTitle(
                'Partages',
              ),

              _buildPartagesSection(context),

              const SizedBox(height: 36),

              _sectionTitle(
                'Personnes de confiance',
              ),

              _buildTrustedPeopleSection(context),

              const SizedBox(height: 36),

              _sectionTitle(
                'Traçabilité',
              ),

              _actionButton(
                icon: Icons.history,
                color: KidsRelayColors.vertPin,
                title: 'Journal des consultations',
                subtitle:
                    'Voir quel établissement a consulté la fiche '
                    'de cet enfant, et quand.',
                onPressed: () {
                  final childId = child.childId;

                  if (childId == null) {
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConsultationJournalPage(
                        childId: childId,
                        childDisplayName: _displayName,
                      ),
                    ),
                  );
                },
              ),
            ],

            if (_canWrite) ...[
              const SizedBox(height: 36),

              _sectionTitle(
                'Modifier le profil',
              ),

              _actionButton(
                icon: Icons.edit_document,
                color: KidsRelayColors.ambre,
                title:
                    'Informations essentielles',
                subtitle:
                    'Modifier les informations destinées aux secours.',
                onPressed: () {
                  final transmissionController =
                      TransmissionController(
                    initialDraft:
                        ChildProfileDraft.fromChildProfileData(
                      child.essentialInformation,
                    ),
                    isEditing: true,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IdentityPage(
                        transmissionController:
                            transmissionController,
                      ),
                    ),
                  );
                },
              ),

              _actionButton(
                icon: Icons.edit,
                color: KidsRelayColors.vertPin,
                title: 'Profil Activités',
                subtitle:
                    'Modifier les informations utilisées pour préparer les activités.',
                onPressed: () => _openActivityProfile(context),
              ),
            ],

            if (_isOwner) ...[
              const SizedBox(height: 36),

              _sectionTitle(
                'Gestion',
              ),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.delete,
                    ),
                  ),
                  title: const Text(
                    'Supprimer le profil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Cette action supprimera définitivement le profil de cet enfant.',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () =>
                      _confirmAndDeleteProfile(context),
                ),
              ),
            ] else if (!_canWrite) ...[
              const SizedBox(height: 36),

              const Text(
                'Vous avez un accès en consultation seule à cette '
                'fiche : seul le parent peut la modifier ou la '
                'supprimer.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
