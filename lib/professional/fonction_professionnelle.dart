import 'package:flutter/material.dart';

import 'establishment_service.dart';

/// La fonction qu'un professionnel déclare, et que le parent lira sous
/// chaque note écrite sur son enfant.
///
/// **Pourquoi une liste plutôt qu'un champ libre seul.** Un champ libre
/// donne « prof », « moi », « CE1 » — et le parent lit ça sous une
/// observation sur son enfant. Une liste garde les libellés lisibles et
/// comparables d'un établissement à l'autre.
///
/// **Pourquoi « Autre » malgré tout.** Aucune liste ne couvrira école,
/// crèche, centre de loisirs, cantine, périscolaire et ALSH. Ce qui
/// serait exclu de la liste serait exclu de l'application.
///
/// **Ce qui est enregistré est ce qui sera lu.** Pas un code, pas une
/// clé : le libellé exact. L'application n'ajoute ni « une », ni
/// « (e) », ni féminin de circonstance — la personne écrit ce qu'elle
/// est, et c'est la seule manière que la ligne soit vraie pour tout le
/// monde.
///
/// La liste a été arrêtée par Fanny le 25/08/2026. La modifier change
/// ce que des parents liront pendant des années : ce n'est pas une
/// constante technique.
const List<String> fonctionsProposees = [
  'Enseignant·e',
  'ATSEM',
  'AESH / AVS',
  'Direction',
  'Animation',
  'Restauration',
  'Santé scolaire (infirmerie)',
  'Auxiliaire de puériculture',
];

/// Bornée en base aussi, dans `rpc_definir_ma_fonction` et
/// `rpc_creer_etablissement` : la fonction rentre par deux portes.
const int longueurMaxFonction = 60;

/// Sélecteur de fonction, utilisé partout où elle se saisit — création
/// d'établissement, « Ma fonction » dans l'équipe, et le filet avant
/// d'écrire une première note.
///
/// Rend `null` tant que le choix n'est pas exploitable : « Autre »
/// choisi sans texte saisi vaut « rien choisi ». C'est à l'appelant de
/// refuser, avec le message qui convient à son écran.
class SelecteurFonction extends StatefulWidget {
  final String? valeurInitiale;
  final ValueChanged<String?> onChanged;

  const SelecteurFonction({
    super.key,
    required this.onChanged,
    this.valeurInitiale,
  });

  @override
  State<SelecteurFonction> createState() => _SelecteurFonctionState();
}

class _SelecteurFonctionState extends State<SelecteurFonction> {
  static const _autre = '__autre__';

  late final TextEditingController _autreController;

  /// `null` = rien choisi, `_autre` = « Autre » choisi, sinon le
  /// libellé de la liste.
  String? _choix;

  @override
  void initState() {
    super.initState();

    final initiale = widget.valeurInitiale?.trim();

    // Une fonction déjà déclarée qui ne figure pas dans la liste vient
    // forcément d'« Autre » : on rouvre le champ libre avec son texte,
    // plutôt que de faire croire à la personne qu'elle n'avait rien
    // saisi.
    final dansLaListe =
        initiale != null && fonctionsProposees.contains(initiale);

    _choix = initiale == null || initiale.isEmpty
        ? null
        : (dansLaListe ? initiale : _autre);

    _autreController = TextEditingController(
      text: dansLaListe || initiale == null ? '' : initiale,
    );
  }

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  void _prevenir() {
    if (_choix == null) {
      widget.onChanged(null);
      return;
    }

    if (_choix != _autre) {
      widget.onChanged(_choix);
      return;
    }

    final saisie = _autreController.text.trim();

    widget.onChanged(saisie.isEmpty ? null : saisie);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _choix,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Votre fonction',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final fonction in fonctionsProposees)
              DropdownMenuItem(
                value: fonction,
                child: Text(fonction),
              ),
            const DropdownMenuItem(
              value: _autre,
              child: Text('Autre…'),
            ),
          ],
          onChanged: (choix) {
            setState(() {
              _choix = choix;
            });

            _prevenir();
          },
        ),

        if (_choix == _autre) ...[
          const SizedBox(height: 12),

          TextField(
            controller: _autreController,
            maxLength: longueurMaxFonction,
            decoration: const InputDecoration(
              labelText: 'Précisez votre fonction',
              helperText:
                  'C’est ce que le parent lira sous vos notes.',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _prevenir(),
          ),
        ],
      ],
    );
  }
}

/// Ce qu'une note portera comme signature, une fois le champ résolu.
///
/// [dejaEnregistree] évite une écriture inutile en base quand la
/// personne avait déjà déclaré sa fonction : la note n'a pas à
/// réécrire ce qui n'a pas changé.
class SignatureNote {
  final String? fonction;
  final bool dejaEnregistree;

  const SignatureNote(
    this.fonction, {
    required this.dejaEnregistree,
  });

  /// Faux tant que la fonction n'est pas exploitable — « Autre » choisi
  /// sans texte, ou rien de déclaré et rien de choisi.
  bool get utilisable => fonction != null;
}

/// Le filet, sur les deux écrans qui écrivent une note.
///
/// Décision du 25/08/2026 : **pas de note écrite tant que la fonction
/// n'est pas renseignée.** C'est le seul moyen que la promesse faite au
/// parent — savoir si l'observation vient de la maîtresse, de la
/// cantine ou de la direction — soit vraie pour toutes les notes
/// futures. Les notes antérieures, elles, afficheront « Fonction non
/// précisée » : le trou se referme à la première note de chacun au
/// lieu de rester un repli permanent.
///
/// Ne bloque rien tant que le chargement n'a pas abouti : c'est
/// l'écran qui refuse au moment d'enregistrer, avec son propre
/// message.
class ChampSignatureNote extends StatefulWidget {
  final String etablissementId;
  final ValueChanged<SignatureNote> onChanged;

  const ChampSignatureNote({
    super.key,
    required this.etablissementId,
    required this.onChanged,
  });

  @override
  State<ChampSignatureNote> createState() =>
      _ChampSignatureNoteState();
}

class _ChampSignatureNoteState extends State<ChampSignatureNote> {
  String? _enregistree;
  bool _chargee = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    String? fonction;

    try {
      fonction = await EstablishmentService.instance.myFonction(
        widget.etablissementId,
      );
    } catch (_) {
      // Hors connexion, ou lecture refusée : on se comporte comme si
      // rien n'était déclaré. La personne ressaisira, et la base
      // recevra la même valeur — jamais un blocage définitif.
      fonction = null;
    }

    if (!mounted) {
      return;
    }

    final propre = fonction?.trim();
    final connue = propre != null && propre.isNotEmpty;

    setState(() {
      _enregistree = connue ? propre : null;
      _chargee = true;
    });

    widget.onChanged(
      SignatureNote(
        connue ? propre : null,
        dejaEnregistree: connue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_chargee) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_enregistree != null) {
      // Déjà déclarée : on ne redemande pas, mais on montre ce que le
      // parent lira. Une signature qu'on n'a pas relue depuis des mois
      // se corrige dans « Gérer l'équipe ».
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(
          'Cette note sera signée : $_enregistree',
          style: const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Votre fonction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Le parent lira cette fonction sous votre note. Elle est '
          'demandée une fois, puis retenue.',
          style: TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 12),

        SelecteurFonction(
          onChanged: (fonction) => widget.onChanged(
            SignatureNote(fonction, dejaEnregistree: false),
          ),
        ),
      ],
    );
  }
}
