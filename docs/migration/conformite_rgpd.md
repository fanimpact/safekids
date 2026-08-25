# Conformité RGPD — ce qui est en place

État au 24/08/2026. Quatre décisions mises en œuvre, chacune avec ce
qu'elle garantit, ce qu'elle ne garantit pas, et ce qui reste à faire
de votre côté.

---

> ## ⚠️ Ce qui reste à faire
>
> **Un fichier SQL est à exécuter** :
> `supabase/schema_journal_ouvertures_partage.sql` (25/08/2026), qui
> ouvre le journal des consultations aux ouvertures de lien. Tant
> qu'il ne l'est pas, `consulter-partage` échouera à journaliser — et
> avalera l'erreur, donc la fiche restera servie, mais la traçabilité
> restera muette.
>
> `supabase/schema_conformite_rgpd.sql` a été appliqué le 24/08/2026,
> sans erreur, et ses quatre tâches planifiées vérifiées une à une.
>
> **Les fonctions serveur ne sont toujours pas redéployées**, et il
> y en a désormais **six**. La sixième,
> `confirmer-suppression-compte`, envoie l'email de demande de
> suppression : sans elle, la demande s'enregistre quand même et
> l'application affiche la date à l'écran, mais aucun email ne part.
>
> ```
> supabase functions deploy envoyer-code-verification
> supabase functions deploy verifier-code
> supabase functions deploy notifier-note-ajoutee
> supabase functions deploy confirmer-suppression-compte
> supabase functions deploy consulter-partage --no-verify-jwt
> supabase functions deploy voir-partage --no-verify-jwt
> ```
>
> Détail dans [`fonctions_serveur.md`](fonctions_serveur.md).

---

## 1. Délai de grâce à la suppression du compte

**Ce qui se passe.** Le parent demande la suppression depuis
Paramètres, après avoir saisi le mot `SUPPRIMER`. Le compte devient
inaccessible immédiatement ; les données sont effacées définitivement
7 jours plus tard. Un email rappelle la date et la façon d'annuler.
Pendant le délai, l'application n'affiche plus que l'écran
d'annulation.

**Comment le blocage tient.** À deux endroits, et il faut les deux :

- **en base**, par le RLS. C'est le seul qui protège vraiment : il vaut
  aussi pour qui contournerait l'application. Il passe par la fonction
  `enfant_du_parent()` et trois politiques qui testent `parent_id` en
  direct ;
- **dans l'application**, par `GardeSuppression`, qui enveloppe
  l'accueil aux quatre endroits qui l'ouvrent. Sans lui, le parent
  tomberait sur une application vide sans comprendre pourquoi.

**Ce qui n'est pas bloqué, volontairement** : `comptes_parents`. C'est
là que l'application lit l'état de la demande. Un parent bloqué doit
pouvoir revenir en arrière.

**Choix assumé** : si l'état ne peut pas être lu — hors ligne, ou
session expirée — la barrière de l'application laisse passer. Bloquer sur une incertitude enfermerait dehors un parent qui
n'a rien demandé, alors que sans réseau il n'y a de toute façon aucune
donnée à protéger côté application.

**L'effacement** est une tâche `pg_cron` quotidienne à 4h. Elle
supprime la ligne `auth.users` et rien d'autre : tout le reste est en
cascade. C'est ce qui garantit qu'aucune donnée ne survit parce qu'on
aurait oublié une table.

## 2. Consentement aux données de santé

**Ce qui se passe.** Un écran dédié, avant le questionnaire, sur les
deux chemins de création d'un enfant. Le bouton reste inerte tant que
la case n'est pas cochée. La date enregistrée est celle du geste, pas
celle de l'écriture en base.

**Jamais affiché en modification.** Redemander l'accord à chaque
correction de poids n'aurait aucun sens et finirait par être coché sans
être lu.

**Retirer le consentement** est le bouton « Supprimer » du profil de
l'enfant, dont la confirmation dit maintenant explicitement
l'équivalence. Pas de second chemin qui ferait exactement la même
chose.

**Les fiches créées avant le 23/08/2026** n'ont pas de date et restent
valables : le consentement n'était alors pas demandé, rien ne justifie
de les bloquer.

## 3. Compteurs d'usage

**Ce qui est compté.** Par mois et par fonctionnalité, le nombre de
familles distinctes. Quatre fonctionnalités : activité préparée, fiche
secours générée, Mode Urgence ouvert, lien de partage créé.

**Ce qui n'est jamais enregistré** : quelle activité, pour quel enfant,
à quel moment, ni combien de fois. L'application ne transmet que le nom
d'une fonctionnalité ; il n'existe aucun paramètre où glisser autre
chose. L'identité vient de `auth.uid()` côté base, dans une fonction
que le client ne voit pas.

**Le mois en cours est pseudonyme, pas anonyme.** Il faut le dire
clairement. Compter des familles *distinctes* impose de garder un
marqueur par famille au moins le temps du mois : sinon on ne saurait
pas si un deuxième usage vient de la même famille. Ce marqueur est une
empreinte `hash(identifiant + sel du mois)`, et le sel est stocké dans
une table qu'aucun compte applicatif ne peut lire — mais quelqu'un qui
aurait à la fois le sel et l'identifiant d'un parent pourrait
recalculer son empreinte.

**Ce qui rend l'historique anonyme, c'est la consolidation.** Le 1er de
chaque mois, une tâche automatique réduit le mois écoulé à un entier
par `(mois, fonctionnalité)`, puis détruit les empreintes **et le
sel**. Sans le sel, une empreinte n'est plus rattachable à personne. Le
mois en cours est donc la seule fenêtre pseudonyme, et elle se referme
d'elle-même.

**Règle tenue côté application** : un compteur ne doit jamais retarder
ni faire échouer une action. Le Mode Urgence en particulier — personne
ne doit attendre un aller-retour réseau statistique pendant qu'un
enfant fait un malaise. L'appel n'est pas attendu, et ses erreurs sont
avalées.

## 4. Adresse de secours

**Ce qui se passe.** Un champ facultatif dans Paramètres. Aucun envoi
automatique n'y est fait ; elle sert uniquement à recontacter le parent
s'il perd l'accès à son compte.

**Ce qui manque, et qu'il faut savoir** : il n'existe aujourd'hui
**aucune procédure écrite** décrivant comment cette adresse est
utilisée le jour où quelqu'un l'invoque. Le champ est un prérequis, pas
une fonctionnalité complète. Tant que la procédure n'existe pas,
l'adresse est une donnée collectée dont l'usage n'est pas documenté —
ce qui est précisément ce que le RGPD demande d'éviter.

---

## L'export RGPD suit

L'export « Mes données » a été étendu à `comptes_parents` le
23/08/2026. Sans cela, il aurait cessé d'être complet le jour même où
les colonnes `email_secours`, `suppression_demandee_le` et
`consentement_sante_le` ont été ajoutées.

**Règle à retenir pour la suite** : toute colonne nouvelle contenant
une donnée personnelle doit ressortir dans l'export. Le rendu du PDF
est générique, donc une colonne nouvelle y apparaît toute seule — mais
une **table** nouvelle, elle, doit être ajoutée à `SourceExport`.

## Ce qui n'est pas traité

- **Le droit d'accès d'une personne de confiance** sur ses propres
  données. Elle est elle aussi une personne concernée, et l'application
  détient son email, la date de son invitation, son niveau d'accès.
  Décision du 23/08/2026 : reporté, noté dans
  [`corrections_a_faire.md`](../audits/corrections_a_faire.md).
- **La durée de conservation** des comptes inactifs. Rien n'expire
  aujourd'hui hors des partages et du journal de consultations.
- **La procédure d'usage de l'adresse de secours**, ci-dessus.
- **SPF / DKIM / DMARC sur `kidsrelay.fr`**, toujours à faire. Sans
  cela, l'email de demande de suppression peut tomber en indésirables —
  et c'est le seul endroit où la date d'effacement sort de
  l'application.
