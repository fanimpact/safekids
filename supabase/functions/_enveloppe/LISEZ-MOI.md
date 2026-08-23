# `_enveloppe/` — ce qui est propre a l'hebergeur

Tout ce que les cinq Edge Functions font *autour* de leur logique :
importer le SDK, lire les variables injectees a l'execution, verifier
le jeton d'appel, repondre en JSON ou en HTML.

Le prefixe `_` fait que la CLI Supabase ne prend pas ce dossier pour
une fonction a deployer. Il est en revanche bien inclus dans le bundle
des fonctions qui l'importent.

| Fichier | Lie a Supabase ? |
|---|---|
| `http.mts` | non — HTTP standard, valable partout |
| `environnement.mts` | oui — noms des variables injectees automatiquement |
| `supabase.mts` | oui — import du SDK depuis esm.sh, clients, jeton |

Deplacer les fonctions ailleurs revient a reecrire `environnement.mts`
et `supabase.mts`, et rien d'autre dans ce dossier.

La logique metier, elle, vit dans `../_logique/` : aucun import Deno,
aucun SDK, aucun appel reseau direct. C'est ce qui la rend testable
par `node --test` (voir `../_tests/`).
