// Ce qu'une fiche partagée a le droit de transmettre.
//
// Avant le 25/08/2026, la fonction envoyait au navigateur le profil de
// santé **complet** et le profil Activités **complet**, quel que soit
// le type de fiche — et le profil Activités n'était affiché nulle
// part. « Ce qu'il faut savoir » ne transmettait pas moins que la
// fiche secours : seul l'affichage différait. Qui ouvrait la console
// du navigateur voyait tout.
//
// Ce fichier renverse la règle : **on part de ce qui est affiché, et
// on n'envoie que cela.** Chaque liste ci-dessous est une liste
// blanche, tenue en regard de `page_partage.mts` — si un champ n'y est
// pas lu, il ne sort pas de la base.
//
// La conséquence à connaître : ajouter un champ à la page publique
// sans l'ajouter ici le laissera vide. C'est le sens du compromis —
// un affichage incomplet se voit, une donnée transmise en trop ne se
// voit pas.

export const TYPE_SECOURS = 'secours';
export const TYPE_CE_QU_IL_FAUT_SAVOIR = 'ce_qu_il_faut_savoir';
export const TYPE_RECOMMANDATIONS = 'recommandations_activite';

type Ligne = Record<string, unknown>;

/// Ne garde d'un objet que les clés demandées, et seulement si elles
/// portent quelque chose. Une clé absente est préférable à une clé à
/// `null` : elle ne dit rien de ce que la base contient.
function garder(
  valeur: unknown,
  cles: readonly string[],
): Ligne | null {
  if (!valeur || typeof valeur !== 'object') {
    return null;
  }

  const source = valeur as Ligne;
  const resultat: Ligne = {};

  for (const cle of cles) {
    const contenu = source[cle];

    if (contenu === undefined || contenu === null) {
      continue;
    }

    resultat[cle] = contenu;
  }

  return Object.keys(resultat).length > 0 ? resultat : null;
}

function garderListe(
  valeur: unknown,
  cles: readonly string[],
): Ligne[] {
  if (!Array.isArray(valeur)) {
    return [];
  }

  return valeur
    .map((element) => garder(element, cles))
    .filter((element): element is Ligne => element !== null);
}

// --- Listes blanches, en regard de page_partage.mts -------------------

const CHAMPS_PATHOLOGIE = ['name', 'approximateDiagnosisDate'] as const;
const CHAMPS_ALLERGIE = ['allergen', 'observedReaction'] as const;
const CONSIGNES = 'emergencyInstructionSteps';

const CHAMPS_TRAITEMENT = [
  'medicationName',
  'dosage',
  'administrationTimes',
] as const;

const CHAMPS_DISPOSITIF = ['deviceName', 'mainUse'] as const;
const CHAMPS_MEDECIN = ['name', 'workplace', 'phoneNumber'] as const;
const CHAMPS_CONTACT = [
  'fullName',
  'relationship',
  'phoneNumber',
] as const;

/// Les huit cases à cocher, plus les quatre vigilances libres, plus
/// l'interrupteur qui commande l'affichage de la section.
const CHAMPS_FACTEURS = [
  'hasTriggerFactors',
  'flashingLights',
  'heat',
  'fatigueOrLackOfSleep',
  'stressOrStrongEmotions',
  'physicalEffort',
  'noise',
  'crowd',
  'confinedSpaces',
  'waterContact',
  'animals',
  'height',
  'other',
] as const;

/// L'identité affichée en tête de fiche. L'identifiant de l'enfant n'y
/// est pas : la page ne l'affiche pas, et le navigateur n'a aucune
/// raison de le connaître.
export const CHAMPS_ENFANT = [
  'prenom',
  'nom',
  'date_naissance',
  'poids',
  'taille',
  'date_maj_poids',
] as const;

/// Le profil de santé réduit à ce que la fiche demandée affiche.
///
/// Les consignes d'urgence et le médecin traitant ne sortent que sur
/// la fiche secours. Sur « Ce qu'il faut savoir », les consignes sont
/// retirées **de l'intérieur** de chaque pathologie et de chaque
/// allergie : elles y voyageaient sans jamais être affichées.
export function profilSantePourFiche(
  profil: unknown,
  typeFiche: string,
): Ligne | null {
  if (!profil || typeof profil !== 'object') {
    return null;
  }

  if (typeFiche === TYPE_RECOMMANDATIONS) {
    return null;
  }

  const source = profil as Ligne;
  const secours = typeFiche === TYPE_SECOURS;

  const champsPathologie = secours
    ? [...CHAMPS_PATHOLOGIE, CONSIGNES]
    : CHAMPS_PATHOLOGIE;

  const champsAllergie = secours
    ? [...CHAMPS_ALLERGIE, CONSIGNES]
    : CHAMPS_ALLERGIE;

  const resultat: Ligne = {
    pathologies: garderListe(source.pathologies, champsPathologie),
    allergies: garderListe(source.allergies, champsAllergie),
    traitements_urgence: garderListe(
      source.traitements_urgence,
      CHAMPS_TRAITEMENT,
    ),
    traitements_reguliers: garderListe(
      source.traitements_reguliers,
      CHAMPS_TRAITEMENT,
    ),
    dispositifs_medicaux: garderListe(
      source.dispositifs_medicaux,
      CHAMPS_DISPOSITIF,
    ),
    contacts_urgence: garderListe(
      source.contacts_urgence,
      CHAMPS_CONTACT,
    ),
  };

  const facteurs = garder(source.facteurs_declenchants, CHAMPS_FACTEURS);

  if (facteurs) {
    resultat.facteurs_declenchants = facteurs;
  }

  if (secours) {
    const medecin = garder(source.medecin_traitant, CHAMPS_MEDECIN);

    if (medecin) {
      resultat.medecin_traitant = medecin;
    }
  }

  return resultat;
}

/// Le profil Activités n'est affiché sur aucune des trois fiches. Il
/// n'est donc plus lu ni transmis — cette fonction existe pour que la
/// règle soit écrite quelque part plutôt que d'être un oubli.
export function profilActivitesPourFiche(): null {
  return null;
}

/// L'identité, réduite à ce que la page affiche.
export function enfantPourFiche(enfant: unknown): Ligne | null {
  return garder(enfant, CHAMPS_ENFANT);
}
