# Icone de l'application

**Les icones sont generees** (24/08/2026). Ce dossier contient les
sources ; les tailles produites vivent dans les dossiers de chaque
plateforme et sont versionnees.

Pour les regenerer apres avoir modifie une source :

```
dart run flutter_launcher_icons
```

> **Apres chaque generation**, verifier `ios/Runner.xcodeproj/project.pbxproj` :
> l'outil y ecrit `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon`
> a la place de `YES`. C'est un champ booleen, la valeur est invalide.
> Annuler cette modification (`git checkout -- ios/Runner.xcodeproj/project.pbxproj`) :
> l'icone iOS fonctionne sans elle, le catalogue d'assets suffit.
> L'outil retire aussi le saut de ligne final de `web/manifest.json`.

## Les sources

### `kidsrelay_1024.png`

L'icone complete, fond compris.

| Critere | Valeur exacte |
|---|---|
| Format | PNG |
| Dimensions | **1024 x 1024 pixels**, carre strict |
| Fond | **opaque** — pas de transparence |
| Couleur de fond | vert pin `#1F4A3F` (ou lin `#F5F3EF`) |
| Profil colorimetrique | sRGB |
| Coins | **carres** — chaque systeme applique son propre arrondi |

C'est ce fichier qui sert a l'icone iOS, a l'icone Android classique et
aux icones du web.

**Zone utile** : le motif doit tenir dans les **80 % centraux**, soit un
carre de 820 x 820 pixels centre. Les 10 % de marge de chaque cote
peuvent etre rognes par l'arrondi d'iOS ou le masque d'Android.

**Pas de texte** : ni « KidsRelay », ni un mot, ni une phrase. A la
taille reelle d'une icone sur un telephone (environ 60 pixels de cote),
un texte devient illisible. Une lettre seule ou un symbole, oui.

### `kidsrelay_premier_plan.png`

Le motif **seul**, sur fond **transparent**, pour les icones adaptatives
d'Android (celles que le systeme recadre en rond, en carre arrondi ou en
goutte selon le lanceur).

| Critere | Valeur exacte |
|---|---|
| Format | PNG |
| Dimensions | **1024 x 1024 pixels** |
| Fond | **transparent** |
| Zone utile | les **66 % centraux**, soit 676 x 676 pixels centres |

La zone utile est plus petite ici que sur l'icone complete : Android
zoome et recadre ce calque, et tout ce qui depasse du cercle inscrit
peut disparaitre.

Le fond de l'icone adaptative n'est pas un fichier : c'est la couleur
`ic_launcher_background` declaree dans
`android/app/src/main/res/values/colors.xml`, ecrite par le generateur
depuis `pubspec.yaml`. Elle vaut le lin `#F5F3EF`.

**Surtout pas le vert pin** : le K du motif est vert pin, il
disparaitrait sur un fond de la meme couleur.

Il sert aussi de logo a l'ecran sur la page de presentation
(`lib/concept_page.dart`) : c'est le seul fichier declare dans la
section `assets` de `pubspec.yaml`.

## Ce que la generation produit

| Plateforme | Ou |
|---|---|
| Android | `res/mipmap-*` et `res/drawable-*` (icone adaptative) |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Web | `web/icons` et `web/favicon.png` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset` |
| Windows | `windows/runner/resources/app_icon.ico` |

Tous ces fichiers sont versionnes.

## Zone sure Android : verifiee, et juste

Le motif occupe 674 x 682 pixels sur les 1024 du canevas, soit 66 %.
La zone garantie visible d'une icone adaptative fait exactement 66 % :
le sommet du triangle ambre depasse de 7 pixels.

Ce n'est pas un probleme parce que `flutter_launcher_icons` applique un
retrait de 16 % au premier plan (`android:inset="16%"` dans
`mipmap-anydpi-v26/ic_launcher.xml`). Le motif occupe alors 67 % du
cercle visible — dans la fourchette recommandee par Material, et rien
n'est rogne, y compris sur un lanceur rond.

**Ne pas reduire ce retrait** sans revoir le motif : a 8 %, le triangle
sort du cercle.

## L'ecran de lancement

Celui qui s'affiche entre le moment ou l'on touche l'icone et la
premiere image dessinee par Flutter est au lin `#F5F3EF` sur Android et
sur iOS. Il n'y a donc pas de saut de couleur au demarrage.
