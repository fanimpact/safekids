# Minimisation des données d'un lien de partage — vérification

Vérification faite le **25/08/2026**, contre la base de production,
après exécution de `schema_journal_ouvertures_partage.sql` et
redéploiement des six fonctions.

Trois liens réels créés sur la fiche de Théo, un par type de fiche,
puis la réponse de `consulter-partage` lue directement. Les liens et
les traces de cette vérification ont été supprimés ensuite.

---

## Ce que la base contient sur Théo

| | |
|---|---|
| `profils_sante` complet | 3 024 octets |
| `profils_activites` complet | 1 837 octets |

Les 17 colonnes du profil de santé, dont `evenements_medicaux`,
`observations_medicales`, `traitements_arretes` et les six drapeaux
`a_*`. Chaque pathologie porte six champs, dont `pathologyId`,
`referringProfessional` et `hasReferringProfessional`. Chaque
traitement d'urgence en porte six, dont `relatedAllergyIds`,
`relatedPathologyIds`, `administrationMethod` et
`administrationCondition`.

**Tout cela partait au navigateur avant le 25/08/2026**, sur les deux
fiches de santé, plus le profil Activités entier — jamais affiché.

## Ce que le serveur envoie maintenant

| Fiche | Réponse | Profil Activités |
|---|---|---|
| Informations pour les secours | **1 266 octets** | `null` |
| Ce qu'il faut savoir | **983 octets** | `null` |
| Recommandations d'activité | **425 octets** | `null` |

À comparer aux 4 861 octets de profils bruts qui partaient
auparavant, identiques pour les deux premières fiches.

### Champs transmis, par fiche

**Fiche secours** — huit rubriques :
`pathologies`, `allergies`, `traitements_urgence`,
`traitements_reguliers`, `dispositifs_medicaux`, `contacts_urgence`,
`facteurs_declenchants`, `medecin_traitant`.

- pathologie : `name`, `approximateDiagnosisDate`,
  `emergencyInstructionSteps`
- traitement : `medicationName`, `dosage`
- médecin traitant : `name`, `workplace`

**Ce qu'il faut savoir** — sept rubriques, sans `medecin_traitant`.

- pathologie : `name`, `approximateDiagnosisDate` — **pas de
  `emergencyInstructionSteps`**
- traitement : identique

**Recommandations d'activité** — `profil_sante` à `null`, seul le
contenu figé au moment du partage.

### Champs vérifiés absents, sur les trois fiches

`pathologyId` · `referringProfessional` · `hasReferringProfessional` ·
`relatedAllergyIds` · `relatedPathologyIds` · `administrationMethod` ·
`administrationCondition` · `a_pathologies` · `a_allergies` ·
`evenements_medicaux` · `observations_medicales` ·
`traitements_arretes` · `enfant_id` · `created_at` · tout champ `id`.

**Aucune fuite détectée sur aucune des trois fiches.**

## Traçabilité des ouvertures

Sept ouvertures provoquées, sept lignes écrites. Chacune porte
`origine = 'lien_partage'`, un `partage_id`, aucun `user_id`, et une
date à la seconde. Deux ouvertures du même lien font bien deux lignes
— c'était le défaut corrigé.

Aucune ligne incohérente : la contrainte `journal_origine_coherente`
tient. Les quatre consultations d'établissement antérieures sont
intactes et gardent leur origine.

## Ce que cette vérification ne couvre pas

- **Le rendu de la page publique** avec les données réduites. La page
  est testée en isolation (19 tests), mais elle n'a pas été ouverte
  dans un navigateur sur ces trois liens.
- **La purge à 12 mois**, qui ne se voit pas avant douze mois.
- **L'affichage des deux origines** dans l'écran Traçabilité de
  l'application, qui reste dans
  [`a_verifier_sur_mobile.md`](../audits/a_verifier_sur_mobile.md).
