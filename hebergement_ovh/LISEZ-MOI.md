# La tâche planifiée chez OVH

Ce dossier contient ce qui tourne sur l'hébergement OVH, en dehors de
la page publique (`web_partage/`).

## À quoi ça sert

`envoyer-notifications-parent` envoie les notifications qui attendent
dans `evenements_notification_parent`. Il faut quelqu'un pour
l'appeler régulièrement : c'est ce fichier PHP, lancé par le
planificateur d'OVH.

**Ce n'est pas le canal normal.** Les fonctions qui créent un
événement envoient dans la foulée, et le parent est prévenu en
quelques secondes. Ce passage rattrape ce qui serait tombé — Brevo
indisponible, une coupure réseau au mauvais moment.

## Pourquoi OVH

Décision de Fanny, le 28/08/2026, après avoir pesé trois options :

| | Écartée parce que |
|---|---|
| Planificateur Supabase | deux extensions Postgres et une clé dans le coffre de la base — ce qui pèse sur le dossier d'hébergement de données de santé |
| Service de cron gratuit | un sous-traitant de plus à déclarer au RGPD, détenant l'adresse et la clé |

Chez OVH, rien ne sort de chez elle et rien n'entre dans la base.

## Une fois par heure — c'est une limite d'OVH

Les tâches planifiées du mutualisé **ne descendent pas en dessous de
l'heure**. On ne peut même pas régler les minutes, y compris en mode
expert. Le rythme de cinq minutes envisagé au départ n'était pas
tenable.

C'est acceptable ici, et seulement ici : ce passage ne sert qu'au
rattrapage d'un échec. Si un jour il devenait le canal principal, il
faudrait revoir ce choix.

## Les deux fichiers

| | |
|---|---|
| `tache_notifications.php.exemple` | versionné, avec une clé factice |
| `tache_notifications.php` | **ignoré par git**, porte la vraie clé |

La clé du planificateur n'est **pas** la clé de service de la base. Si
le serveur OVH était compromis, ce qui fuiterait ne donnerait accès à
aucune donnée — seulement le droit de faire partir des messages déjà
préparés.

## Où le déposer

**`/home/izfeflh/taches/`**, et surtout **pas** dans un dossier servi
par un site. Dans `www/` ou dans `fiche/`, l'adresse deviendrait
publique et n'importe qui pourrait déclencher un passage.

SFTP (FileZilla, port 22), identifiants de l'onglet **FTP-SSH**.

## Configurer la tâche

Espace client OVH → **Hébergements** → l'hébergement de
`kidsrelay.fr` → onglet **Tâches planifiées** → **Ajouter une tâche**.

| Champ | Valeur |
|---|---|
| Langage | PHP (la version proposée par défaut) |
| Chemin | `taches/tache_notifications.php` |
| Fréquence | toutes les heures |

## Vérifier qu'elle tourne

Le fichier `dernier_passage.txt`, à côté du script, porte une ligne
réécrite à chaque passage : la date, le code de réponse, et les
compteurs rendus par la fonction.

Il ne grossit jamais, et il ne contient **aucune donnée d'enfant** —
la fonction serveur ne rend que des compteurs.

Une ligne saine ressemble à :

```
2026-08-28 20:00:03 | code 200 | {"traites":0,"envoyes":0,"echoues":0,"ignores":0}
```
