# Les notes d'établissement visibles du parent — vérification en production

**Vérifié le 25/08/2026**, projet `xcugfdjaifdibwowlrpi`, sur des
données réelles. Aucune donnée fictive n'a été laissée en base.

## Ce qui a été constaté avant toute manipulation

Une note existait déjà, écrite le **18/08/2026** par la direction de
l'établissement « nda » sur la fiche de Théo, rattachée à l'activité
« ze ».

**Son parent n'a jamais pu la lire.** Pendant une semaine, une
observation écrite sur un enfant est restée invisible de la seule
personne à qui elle était destinée. Ce n'est pas un cas de figure
construit pour le test : c'est l'état réel de la base au moment où le
défaut a été corrigé.

## Les six vérifications

Chacune passe par `notes_enfant_pour_parent`, en simulant l'identité de
l'appelant avec `set_config('request.jwt.claims', …)` — c'est ce que
lit `auth.uid()`.

| # | Appelant | Enfant demandé | Attendu | Constaté |
|---|---|---|---|---|
| 1 | le parent | Théo | la note, avec son contexte | **1 ligne** |
| 2 | le professionnel **auteur de la note** | Théo | rien | **0 ligne** |
| 3 | aucune identité (`auth.uid()` nul) | Théo | rien | **0 ligne** |
| 4 | le parent | Noé, sans note | rien | **0 ligne** |
| 5 | le parent | Théo, une note générale au groupe ajoutée | la note de Théo seule | **1 ligne** |
| 6 | le parent | Théo, une note sur Noé ajoutée | la note de Théo seule | **1 ligne** |

Le contenu rendu au test 1 :

| colonne | valeur |
|---|---|
| `nom_activite` | `ze` |
| `nom_etablissement` | `nda` |
| `role_auteur` | `directeur` |
| `date_activite` | **nul** — l'écran retombe alors sur la date de la note |

**Aucune adresse email n'apparaît dans la réponse.** C'était l'objet de
la décision du 25/08/2026 : le parent voit la qualité de l'auteur, pas
son identité.

Le test 2 est le plus important des six. Le professionnel qui a écrit
la note, membre actif de l'établissement propriétaire de l'activité,
**ne peut pas la relire par cette fonction** — elle ne sert qu'au
parent. `security definer` contourne le RLS ; sans
`enfant_du_parent(p_enfant_id)`, il aurait obtenu la ligne.

## Comment les tests 5 et 6 ont été faits sans rien laisser

Les deux notes temporaires ont été insérées **à l'intérieur d'une
transaction terminée par `rollback`**. Elles n'ont jamais été
committées : il n'y a rien eu à nettoyer, et rien n'a pu être oublié.

Contrôle après coup : `notes_activite` contient **1 ligne**, celle du
18/08. Zéro ligne portant un libellé de test.

## Un constat annexe, qui compte pour la suite

`evenements_notification_parent` est **vide**.

Cette table est le registre de ce qui a été déclenché : la fonction
serveur y écrit une ligne *avant* toute tentative d'envoi, précisément
pour qu'une notification perdue laisse une trace. Elle ne contient
rien.

Deux explications possibles, et rien en base ne permet de trancher :
soit la note du 18/08 est antérieure à la mise en place de la
notification, soit l'appel n'a jamais abouti. Dans les deux cas le
résultat pour le parent est le même — **il n'a rien reçu, et n'avait
nulle part où lire.**

C'est l'argument des corrections a, b et c :

- **a** — `saveNote` avale l'exception et ignore `{notifie: false}` :
  l'écran affiche un succès identique que le parent ait été prévenu ou
  non ;
- **b** — l'email disait « connectez-vous pour la consulter » alors
  qu'aucun écran n'affichait les notes. **Réglé par ce chantier**, sans
  qu'aucune donnée n'ait à sortir vers une boîte mail ;
- **c** — personne ne relit cette table. Elle est faite pour ça.

## À refaire le jour où la fonction change

Les six requêtes tiennent en une commande `supabase db query --linked`
chacune. Le test 2 est celui à ne jamais retirer.
