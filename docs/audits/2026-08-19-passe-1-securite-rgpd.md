# Audit KidsRelay — Passe 1/4 : Sécurité et RGPD

**Date** : 19/08/2026
**Méthode** : tests réels contre la base Supabase de production, par usurpation d'identité au niveau base (`set_config('request.jwt.claims', ...)` + `SET ROLE authenticated`), pas par simple relecture des politiques RLS. Le rôle habituel des requêtes de diagnostic (`postgres`) contourne le RLS et ne prouve rien sur la sécurité réelle — chaque test marqué « conforme » ci-dessous a donc été exécuté sous une identité précise, exactement comme Postgres le ferait pour l'app en direct.
**Statut** : validée par Fanny le 19/08/2026, avec 1 point vérifié en complément (voir §8) et 5 corrections notées pour après l'audit complet (voir `docs/audits/corrections_a_faire.md`).

## Résumé

- 21/21 tests d'isolation par impersonation, tous conformes.
- 15/15 tables avec RLS actif, revues une par une.
- Expiration et révocation d'un rattachement établissement : testées en direct (bascule d'état → accès coupé, revérifié).
- Purge du journal des consultations à 12 mois : testée réellement (ligne à 13 mois insérée, commande du job exécutée, seule elle a disparu).
- Lien de partage (`partages`) : testé par vraies requêtes HTTP contre `consulter-partage` (token valide / expiré / inexistant).
- 2 observations non bloquantes, 1 point non testable depuis cette session (cache hors-ligne professionnel, limite de 7 jours).

## 1. Un parent ne peut pas accéder à un enfant qui ne lui est pas rattaché

**Conforme.** Un parent B fictif, sans aucun lien avec Théo, ne peut lire ni sa fiche identité ni son profil santé (0 ligne dans les deux cas). Test symétrique refait avec le compte réel de Fanny contre un enfant fictif appartenant à ce parent B : 0 ligne également.

## 2. Un membre d'établissement ne voit que les enfants réellement rattachés à cet établissement

**Conforme.** Un membre actif d'un établissement B fictif, sans lien avec l'établissement réel « nda », ne peut pas lire Théo (rattaché uniquement à « nda »). Testé aussi sur un enfant fictif rattaché à « nda » mais pas à B : 0 ligne — l'isolement est bien par établissement, pas par « n'importe quel membre du personnel quelque part ».

**Conforme — révocation testée en conditions réelles.** Sur un rattachement contrôlé (enfant fictif ↔ « nda »), en partant d'un accès actif confirmé (fiche + profil santé visibles), le passage du statut à `revoque` a coupé l'accès immédiatement — revérifié : 0 ligne sur la fiche identité et sur le profil santé.

**Observation, tranchée par Fanny : gardée telle quelle.** Une fois révoqué, le membre du personnel ne voit plus jamais les données de l'enfant, mais peut encore lire la ligne technique du rattachement (dates, statut « revoque », jeton). Décision de Fanny (19/08) : cette trace est utile, on la garde.

**Point complémentaire demandé par Fanny, vérifié le 19/08 : le jeton d'une ligne révoquée ne permet pas de se rattacher à nouveau.** `rpc_reclamer_rattachement` exige explicitement `statut = 'en_attente'` dans sa clause `where` — une ligne `revoque` ne peut jamais satisfaire cette condition, la fonction renvoie « Lien invalide ou expiré ». Aucune autre voie n'existe pour modifier cette ligne : le personnel n'a qu'un droit de lecture sur `enfants_etablissements`, jamais d'écriture directe. Le jeton d'une ligne révoquée est donc définitivement inerte. Vérifié par lecture du code de la fonction (`pg_get_functiondef`), preuve logique directe, sans nouveau compte de test.

## 3. Les liens de partage et les rattachements expirent réellement

**Conforme — rattachement établissement.** Sur le rattachement contrôlé, passer `date_expiration` dans le passé a coupé l'accès aussitôt (fiche et profil santé), avant même toute révocation — le mécanisme réagit bien à la date, pas seulement au statut.

**Conforme — lien de partage, testé en vraie requête HTTP publique, avec de vraies données.** Un lien généré pour Théo (fiche « secours ») a été appelé trois fois via la fonction publique `consulter-partage` :

```
GET consulter-partage?token=<valide>   → 200 + fiche complète
GET consulter-partage?token=<expiré>   → 410 "Lien expiré ou invalide."
GET consulter-partage?token=<inconnu>  → 404 "Lien expiré ou invalide."
```

Message générique identique dans les deux cas d'échec — pas d'indice permettant de deviner si un token a existé.

## 4. Le cache hors-ligne côté professionnel

**Conforme — purge sur révocation.** Le rechargement du trombinoscope remplace entièrement la liste locale à chaque synchronisation réussie (jamais une fusion). Un enfant devenu invisible côté base ressort de la requête sous forme de ligne « établissement » sans enfant rattaché, et le code l'ignore explicitement plutôt que d'afficher une donnée partielle.

**Correction de ma part (19/08) : la limite des 7 jours EST testable, contrairement à ce que j'avais écrit.** J'avais initialement classé ce point « non testable depuis ici » en pensant uniquement à un test sur appareil réel. Fanny a eu raison de relever que la logique elle-même (comparaison de dates) est testable en Dart exactement comme `offline_cache_test.dart` le fait déjà côté parent, sans appareil réel. Aucun test de ce type n'existe aujourd'hui côté professionnel — noté dans la liste des corrections post-audit.

## 5. Le journal des consultations se purge à 12 mois

**Conforme — purge testée pour de vrai, pas juste « la tâche existe ».** Une ligne de journal a été insérée avec une date artificielle de 13 mois, puis la commande exacte de la tâche planifiée a été exécutée manuellement : la ligne de 13 mois a disparu, les 4 lignes récentes (dont de vraies consultations de Théo) sont restées intactes.

```
purge-journal-consultations-fiche   actif, quotidien 03:00
supprimer-partages-expires          actif, quotidien 03:00
```

**Conforme — personne ne peut relire le journal, pas même son auteur.** Confirmé en écrivant une ligne en tant que membre du personnel puis en tentant de la relire avec la même identité : 0 résultat (aucune politique de lecture n'existe, volontairement). Vérifié aussi que le code de l'app ne tente jamais de relire la ligne après l'avoir écrite — un échec silencieux est intercepté, la consultation elle-même ne plante jamais.

**Décision de Fanny (19/08) : le parent doit pouvoir voir qui a consulté la fiche de son enfant et quand.** Aujourd'hui personne ne peut le lire, y compris le parent. À corriger après l'audit complet (politique de lecture pour le parent concerné + écran côté parent) — noté dans la liste des corrections.

## 6. Autres frontières testées en conditions réelles

**Conforme — activité d'établissement partagée entre collègues, masquage strictement individuel.** Une activité créée par un membre est visible et modifiable par un second membre du même établissement, invisible à un membre d'un autre établissement. Une note ajoutée par l'un des deux membres reste invisible de l'autre. Une recommandation masquée par un membre n'est pas masquée pour son collègue.

**Conforme — note liée à un enfant.** Visible du parent de l'enfant concerné, pas d'un parent sans lien avec cet enfant.

**Conforme — comptes et appareils.** `comptes_parents` : un parent ne peut pas lire la fiche compte d'un autre parent. `codes_verification` : aucune politique cliente du tout, table accessible uniquement par les fonctions serveur — comportement voulu.

## 7. Politiques RLS, table par table

RLS est activé sur les 15 tables de l'app, sans exception.

| Table | Ce que les politiques autorisent | Lecture |
|---|---|---|
| `enfants` | Le parent propriétaire (tout) + un enfant visible par un établissement (lecture seule) | Conforme |
| `profils_sante` / `profils_activites` | Idem, via `enfant_visible_par_etablissement()` | Conforme |
| `enfants_etablissements` | Le parent gère librement les siens ; un membre actif lit toutes les lignes de son établissement, y compris passées | Conforme (voir §2) |
| `etablissements` | Visible par ses membres actifs et par le parent d'un enfant qui y est rattaché | Conforme |
| `membres_etablissement` | Chacun voit sa propre ligne + tout membre actif voit le trombinoscope du personnel ; écriture uniquement via fonctions serveur | Conforme |
| `activites_preparees` | Le parent gère les siennes ; côté établissement, lecture/écriture/suppression ouvertes à tout membre actif (partage voulu) | Conforme |
| `activites_recommandations_masquees` | Strictement `user_id = auth.uid()` en lecture/écriture | Voir note ci-dessous |
| `notes_activite` | L'auteur lit/modifie les siennes ; le parent lit celles liées à son enfant ; jamais les collègues | Conforme |
| `journal_consultations_fiche` | Écriture seule par le membre concerné ; aucune lecture, pour personne | Conforme (évolution décidée, §5) |
| `evenements_notification_parent` | Le parent lit ses propres événements ; écriture uniquement via fonctions serveur | Conforme |
| `comptes_parents` | Chacun lit/modifie sa propre ligne ; interdiction de s'auto-attribuer un abonnement actif | Conforme |
| `appareils_reconnus` | Strictement `user_id = auth.uid()` | Conforme |
| `codes_verification` | Aucune politique cliente — accès uniquement via les fonctions serveur (clé service_role) | Conforme |
| `partages` | Le parent gère les siens ; lien public géré hors RLS, par la fonction serveur qui revérifie l'expiration en code | Voir note ci-dessous |

### Deux notes techniques

- **`activites_recommandations_masquees`** : la lecture ne revérifie pas que l'activité est toujours accessible à l'utilisateur au moment de la lecture (seule l'écriture le fait). Concrètement : quelqu'un qui perd l'accès à un établissement garde la liste de ses propres préférences de masquage sur d'anciennes activités — jamais les préférences de quelqu'un d'autre, jamais de donnée d'enfant. Pas une fuite, un résidu inutile. **Décision de Fanny : à nettoyer après l'audit.**
- **`partages`** : la politique du parent utilise une sous-requête directe sur `enfants` plutôt qu'une fonction SECURITY DEFINER comme partout ailleurs dans le code récent. Pas un bug aujourd'hui (`enfants` ne référence jamais `partages` en retour, donc pas de risque de récursion), mais une incohérence héritée du fichier `schema.sql` d'origine. **Décision de Fanny : à aligner après l'audit.**

## 8. Ce qui n'a pas pu être testé, et pourquoi

- **Comportement de l'app en direct** (écrans, boutons) — cette passe a testé la base de données et les fonctions serveur directement, pas l'interface. Les parcours à l'écran sont prévus en passe 3.
- ~~Cache hors-ligne, limite exacte des 7 jours~~ — voir correction au §4 : c'est testable, noté dans la liste des corrections post-audit plutôt que classé « non testable ».

## Méthode détaillée

Comptes de test créés pour l'occasion : deux identités `auth.users` fictives (jamais de vraie connexion), un établissement fictif, un enfant fictif, deux tokens `partages` de test. Tous supprimés à la fin de la passe — vérifié après coup, aucune trace résiduelle, données réelles de Théo/Noé et de l'établissement « nda » intactes. **Fanny a demandé (19/08) de ne plus créer de comptes fictifs dans la base réelle pour les passes suivantes sans lui demander d'abord.**
