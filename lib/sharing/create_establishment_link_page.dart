import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/complete_child_profile_data.dart';
import '../repositories/child_repository.dart';
import '../utils/date_format_utils.dart';
import 'establishment_attachment_service.dart';

enum _DurationChoice {
  semaine1('1 semaine', Duration(days: 7)),
  mois1('1 mois', Duration(days: 30)),
  mois3('3 mois', Duration(days: 90)),
  mois6('6 mois', Duration(days: 182)),
  an1('1 an', Duration(days: 365)),
  dateLibre('Choisir une date précise', null);

  const _DurationChoice(this.label, this.duration);

  final String label;
  final Duration? duration;
}

/// Génère un lien de rattachement vers un établissement (école,
/// périscolaire...) pour un enfant. La durée est toujours choisie par
/// le parent — jamais de valeur par défaut, jamais indéfinie : c'est le
/// principe non négociable de l'espace professionnel, le parent décide
/// en toutes circonstances si et où les données de son enfant sont
/// partagées.
class CreateEstablishmentLinkPage extends StatefulWidget {
  const CreateEstablishmentLinkPage({super.key});

  @override
  State<CreateEstablishmentLinkPage> createState() =>
      _CreateEstablishmentLinkPageState();
}

class _CreateEstablishmentLinkPageState
    extends State<CreateEstablishmentLinkPage> {
  CompleteChildProfileData? _selectedChild;
  _DurationChoice _selectedDuration = _DurationChoice.mois3;
  DateTime? _customDate;

  bool _isGenerating = false;
  String? _generatedToken;

  List<CompleteChildProfileData> get _children =>
      ChildRepository.instance.children;

  String _childDisplayName(CompleteChildProfileData child) {
    final identity = child.essentialInformation.identity;

    final parts = [identity.firstName, identity.lastName]
        .where(
          (value) => value != null && value.trim().isNotEmpty,
        )
        .map((value) => value!.trim());

    final name = parts.join(' ');

    return name.isEmpty ? 'Enfant' : name;
  }

  DateTime? get _resolvedExpiration {
    if (_selectedDuration == _DurationChoice.dateLibre) {
      return _customDate;
    }

    return DateTime.now().toUtc().add(
      _selectedDuration.duration!,
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() {
        _customDate = picked;
        _generatedToken = null;
      });
    }
  }

  Future<void> _generateToken() async {
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

    final expiration = _resolvedExpiration;

    if (expiration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez une date d’échéance avant de continuer.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedToken = null;
    });

    try {
      final token = await EstablishmentAttachmentService
          .instance
          .generateAttachmentToken(
        childId: child.childId!,
        dateExpiration: expiration,
      );

      setState(() {
        _generatedToken = token;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de générer le lien pour le moment. '
            'Vérifiez votre connexion et réessayez.',
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

  Future<void> _copyToken() async {
    final token = _generatedToken;

    if (token == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié.')),
    );
  }

  Future<void> _sendBySms() async {
    final token = _generatedToken;

    if (token == null) {
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      queryParameters: {
        'body':
            'Voici le code à saisir dans l’espace professionnel '
            'KidsRelay pour accéder au profil de votre élève : $token',
      },
    );

    await launchUrl(uri);
  }

  Future<void> _sendByEmail() async {
    final token = _generatedToken;

    if (token == null) {
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Accès KidsRelay',
        'body':
            'Bonjour,\n\nVoici le code à saisir dans l’espace '
            'professionnel KidsRelay (« Rattacher un enfant ») : '
            '$token\n\nCe code expire automatiquement.',
      },
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChildRepository.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (_children.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rattacher à un établissement'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun enfant enregistré. Créez d’abord le profil '
              'd’un enfant depuis « Mes enfants ».',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    _selectedChild ??= _children.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rattacher à un établissement'),
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

            DropdownButtonFormField<CompleteChildProfileData>(
              initialValue: _selectedChild,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _children
                  .map(
                    (child) => DropdownMenuItem(
                      value: child,
                      child: Text(_childDisplayName(child)),
                    ),
                  )
                  .toList(),
              onChanged: (child) {
                setState(() {
                  _selectedChild = child;
                  _generatedToken = null;
                });
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Durée du rattachement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Obligatoire : l’accès n’est jamais accordé sans '
              'échéance.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 8),

            RadioGroup<_DurationChoice>(
              groupValue: _selectedDuration,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedDuration = value;
                  _generatedToken = null;
                });
              },
              child: Column(
                children: [
                  for (final choice in _DurationChoice.values)
                    RadioListTile<_DurationChoice>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(choice.label),
                      value: choice,
                    ),
                ],
              ),
            ),

            if (_selectedDuration == _DurationChoice.dateLibre) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _customDate == null
                      ? 'Choisir la date d’échéance'
                      : 'Échéance : ${formatShortDate(_customDate!)}',
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isGenerating ? null : _generateToken,
                child: Text(
                  _isGenerating
                      ? 'Génération en cours...'
                      : 'Générer le code',
                ),
              ),
            ),

            if (_generatedToken != null) ...[
              const SizedBox(height: 28),

              const Text(
                'Code généré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Transmettez ce code à l’établissement : il le '
                'saisira dans son espace professionnel KidsRelay, '
                'section « Rattacher un enfant ».',
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 12),

              SelectableText(_generatedToken!),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyToken,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copier le code'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sendBySms,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Envoyer par SMS'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sendByEmail,
                    icon: const Icon(Icons.email_outlined),
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
