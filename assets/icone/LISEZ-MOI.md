# Icone de l'application

Ce dossier attend **deux fichiers PNG** a fournir. Tant qu'ils ne sont
pas la, l'application garde l'icone Flutter par defaut : rien n'est
casse, l'icone n'est simplement pas encore la bonne.

## Fichiers attendus

### 1. `kidsrelay_1024.png` — obligatoire

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

### 2. `kidsrelay_premier_plan.png` — recommande

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
`kidsrelay_vert_pin` declaree dans
`android/app/src/main/res/values/colors.xml`.

Si ce second fichier n'est pas fourni, retirer le bloc
`adaptive_icon_foreground` de `pubspec.yaml` avant de lancer la
generation.

## Generer les icones

Une fois les fichiers deposes ici :

```
flutter pub run flutter_launcher_icons
```

La commande ecrit les icones dans `android/app/src/main/res/mipmap-*`,
`ios/Runner/Assets.xcassets/AppIcon.appiconset` et `web/icons`. Ces
fichiers generes sont a committer.

## Ce qui est deja fait

L'ecran de lancement — celui qui s'affiche entre le moment ou l'on
touche l'icone et la premiere image dessinee par Flutter — est deja au
lin `#F5F3EF` sur Android et sur iOS. Il n'y a donc pas de saut de
couleur au demarrage, quelle que soit l'icone choisie.
