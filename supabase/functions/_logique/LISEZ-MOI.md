# `_logique/` — le metier, sans l'hebergeur

Ce que font vraiment les cinq Edge Functions, ecrit de facon a pouvoir
tourner n'importe ou.

Regle tenue par tous les fichiers de ce dossier :

- aucun `import` depuis `esm.sh` ni ailleurs sur le reseau ;
- aucun appel a `Deno.*` ;
- aucun acces base : la logique recoit une interface (`DepotCodes`,
  `DepotNotifications`, `DepotPartages`) dont l'implementation Supabase
  vit dans `../_enveloppe/` ;
- aucun `fetch` direct : il est passe en parametre ;
- aucune lecture de l'horloge : la date courante est passee en
  parametre, pour que les tests decrivent une expiration precise.

C'est ce qui rend ces modules executables par Node sans base ni
reseau, et deplacables tels quels sous un autre hebergeur.

## Lancer les tests

```
node --test supabase/functions/_tests/*.test.mjs
```

Ou, depuis `supabase/functions/_tests/` : `npm test`.

Les fichiers portent l'extension `.mts` : Node 24 en retire les types
sans configuration, et Deno l'accepte. Un `.ts` aurait demande un
`package.json` supplementaire pour etre lu comme un module.

## Le prefixe `_`

La CLI Supabase ne prend pas les dossiers commencant par `_` pour des
fonctions a deployer, mais les inclut dans le bundle de celles qui les
importent. C'est la convention documentee pour le code partage.
