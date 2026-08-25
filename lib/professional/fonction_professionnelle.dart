import 'package:flutter/material.dart';

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
