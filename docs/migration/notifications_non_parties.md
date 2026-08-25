# Les notifications qui ne sont pas parties — où les lire

**Écrit le 26/08/2026.** Répond au point **c** relevé le 25/08 : la
table qui enregistre les notifications déclenchées existait, était bien
alimentée par la fonction serveur, et **personne ne la relisait
jamais.**

## La table

`public.evenements_notification_parent`.

`notifier-note-ajoutee` y crée une ligne **avant** toute tentative
d'envoi, qu'un email exploitable existe ou non — c'est délibéré, et
c'est écrit dans
[`_logique/notification_note.mts`](../../supabase/functions/_logique/notification_note.mts) :
la ligne fait foi de « cette notification a été déclenchée »,
indépendamment du canal. Puis elle est marquée `envoye` ou `echoue`.

| colonne | ce qu'elle dit |
|---|---|
| `statut_email` | `envoye` si Brevo a accepté, `echoue` sinon — y compris quand le parent n'a aucune adresse exploitable |
| `email_envoye_le` | l'horodatage, nul en cas d'échec |
| `statut_push` / `push_envoye_le` | réservés au canal push, pas encore branché |
| `donnees` | `activiteId` et `etablissementId`, de quoi retrouver la note |

## La requête de contrôle

À exécuter dans le SQL Editor, ou par
`supabase db query --linked` :

```sql
select
  e.cree_le,
  e.type_evenement,
  e.statut_email,
  e.donnees ->> 'activiteId' as activite
from public.evenements_notification_parent e
where e.statut_email = 'echoue'
order by e.cree_le desc
limit 50;
```

**État au 26/08/2026** : la table contient **zéro ligne**. Aucune
notification n'a donc jamais été déclenchée — la seule note existante,
du 18/08, est antérieure à la mise en place du mécanisme.

## Pourquoi il n'y a pas de reprise automatique

C'était l'option envisagée. Elle a été écartée, et il vaut mieux dire
pourquoi que la laisser en suspens.

**Depuis le 25/08/2026, l'email n'est plus le seul canal.** La note
s'affiche dans la fiche de l'enfant, côté parent, section
« Traçabilité ». Un email en échec ne fait donc plus disparaître
l'information : il retarde seulement le moment où le parent la
découvre.

**Et depuis le 26/08/2026, le professionnel l'apprend sur-le-champ.**
`saveNote` rend ce qu'il est advenu du parent au lieu de le taire, et
l'écran affiche l'une des trois issues — dont « L'email n'a pas pu être
envoyé au parent, mais la note est visible dans son espace ». La
personne qui vient d'écrire l'observation sait immédiatement si elle
doit prévenir autrement.

Une reprise automatique ajouterait une tâche `pg_cron`, un appel
sortant depuis la base, et une logique de nouvelle tentative — pour un
gain devenu marginal. **À reconsidérer** si le registre commence à
accumuler des `echoue`, ce que la requête ci-dessus permet de
constater.

## Ce qui reste vrai et qu'il faut savoir

- **Une note générale au groupe ne déclenche rien**, et n'apparaît
  jamais chez un parent : le RLS lui refuse les notes sans enfant
  rattaché. Ce n'est pas un défaut, c'est ce que « note générale au
  groupe » veut dire — et le professionnel le lit maintenant en clair
  après avoir enregistré.
- **L'email ne contient pas le texte de la note**, seulement le prénom
  de l'enfant et le nom de l'établissement. Décision tenue : aucune
  observation sur un enfant ne sort vers une boîte mail tant qu'on peut
  l'éviter.
