import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  enfantPourFiche,
  profilActivitesPourFiche,
  profilSantePourFiche,
} from '../_logique/fiche_partagee.mts';

// Minimisation des données envoyées au navigateur (25/08/2026).
//
// Avant : le serveur envoyait le profil de santé complet ET le profil
// Activités complet, quel que soit le type de fiche, et le profil
// Activités n'était affiché nulle part. « Ce qu'il faut savoir » ne
// transmettait pas moins que la fiche secours — seul l'affichage
// différait. Qui ouvrait la console du navigateur voyait tout.
//
// Ces tests décrivent la règle inverse : on n'envoie que ce qui est
// affiché. Ils sont écrits en regard de `page_partage.mts`.

/// Un profil de santé volontairement plus riche que ce que la page
/// affiche : colonnes jamais rendues, champs internes des objets,
/// consignes d'urgence.
const PROFIL_COMPLET = {
  id: 'profil-1',
  enfant_id: 'enfant-1',
  created_at: '2026-01-01T00:00:00.000Z',
  a_pathologies: true,
  a_allergies: true,
  evenements_medicaux: [
    { description: 'Crise en 2024', hospitalized: true },
  ],
  observations_medicales: [{ description: 'Fatigabilité' }],
  traitements_arretes: [{ medicationName: 'Ancien sirop' }],
  pathologies: [
    {
      id: 'patho-1',
      name: 'Épilepsie',
      approximateDiagnosisDate: '2024',
      hasReferringProfessional: true,
      referringProfessional: {
        name: 'Dr Martin',
        phoneNumber: '01 23 45 67 89',
      },
      emergencyInstructionSteps: [
        'Mettre en position latérale de sécurité',
      ],
    },
  ],
  allergies: [
    {
      id: 'allergie-1',
      allergen: 'Arachide',
      observedReaction: 'Urticaire',
      categories: ['alimentaire'],
      emergencyInstructionSteps: ['Donner l’auto-injecteur'],
    },
  ],
  traitements_urgence: [
    {
      id: 'trait-1',
      medicationName: 'Ventoline',
      dosage: '2 bouffées',
      administrationTimes: 'si besoin',
      condition: 'en cas de crise',
      storageLocation: 'sac à dos',
    },
  ],
  traitements_reguliers: [
    {
      medicationName: 'Keppra',
      dosage: '5 ml',
      administrationTimes: 'matin et soir',
      prescriber: 'Dr Martin',
    },
  ],
  dispositifs_medicaux: [
    {
      deviceName: 'Pompe à insuline',
      mainUse: 'diabète',
      serialNumber: 'XYZ-123',
    },
  ],
  medecin_traitant: {
    name: 'Dr Martin',
    workplace: 'Cabinet des Tilleuls',
    phoneNumber: '01 23 45 67 89',
    speciality: 'Pédiatrie',
  },
  facteurs_declenchants: {
    hasTriggerFactors: true,
    heat: true,
    noise: false,
    other: 'Lumière vive',
    notesInternes: 'à revoir',
  },
  contacts_urgence: [
    {
      fullName: 'Mamie',
      relationship: 'Grand-mère',
      phoneNumber: '06 00 00 00 00',
      isPrimary: true,
      email: 'mamie@exemple.fr',
    },
  ],
};

function texte(valeur) {
  return JSON.stringify(valeur);
}

describe('Ce qui ne sort jamais, quelle que soit la fiche', () => {
  for (const type of ['secours', 'ce_qu_il_faut_savoir']) {
    test(`Les colonnes jamais affichées — ${type}`, () => {
      const rendu = texte(profilSantePourFiche(PROFIL_COMPLET, type));

      assert.ok(!rendu.includes('Crise en 2024'));
      assert.ok(!rendu.includes('Fatigabilité'));
      assert.ok(!rendu.includes('Ancien sirop'));
      assert.ok(!rendu.includes('profil-1'));
      assert.ok(!rendu.includes('enfant-1'));
      assert.ok(!rendu.includes('a_pathologies'));
    });

    test(`Les champs internes jamais affichés — ${type}`, () => {
      const rendu = texte(profilSantePourFiche(PROFIL_COMPLET, type));

      assert.ok(!rendu.includes('XYZ-123'));
      assert.ok(!rendu.includes('storageLocation'));
      assert.ok(!rendu.includes('prescriber'));
      assert.ok(!rendu.includes('isPrimary'));
      assert.ok(!rendu.includes('mamie@exemple.fr'));
      assert.ok(!rendu.includes('notesInternes'));
      assert.ok(!rendu.includes('referringProfessional'));
    });
  }

  test('Le profil Activités ne sort sur aucune fiche', () => {
    assert.equal(profilActivitesPourFiche(), null);
  });

  test('L’identité se limite à ce que la page affiche', () => {
    const enfant = enfantPourFiche({
      id: 'enfant-1',
      parent_id: 'parent-1',
      prenom: 'Noé',
      nom: 'Dupont',
      date_naissance: '2019-04-12',
      poids: 18,
      taille: 108,
      date_maj_poids: '2026-06-01',
      created_at: '2026-01-01T00:00:00.000Z',
      consentement_sante_le: '2026-08-23T12:00:00.000Z',
    });

    assert.deepEqual(Object.keys(enfant), [
      'prenom',
      'nom',
      'date_naissance',
      'poids',
      'taille',
      'date_maj_poids',
    ]);
  });
});

describe('Fiche secours', () => {
  const fiche = profilSantePourFiche(PROFIL_COMPLET, 'secours');

  test('Les consignes d’urgence en sortent', () => {
    assert.deepEqual(fiche.pathologies[0].emergencyInstructionSteps, [
      'Mettre en position latérale de sécurité',
    ]);
    assert.deepEqual(fiche.allergies[0].emergencyInstructionSteps, [
      'Donner l’auto-injecteur',
    ]);
  });

  test('Le médecin traitant en sort, réduit à trois champs', () => {
    assert.deepEqual(fiche.medecin_traitant, {
      name: 'Dr Martin',
      workplace: 'Cabinet des Tilleuls',
      phoneNumber: '01 23 45 67 89',
    });
  });

  test('Le contenu affiché est intact', () => {
    assert.equal(fiche.pathologies[0].name, 'Épilepsie');
    assert.equal(fiche.allergies[0].allergen, 'Arachide');
    assert.equal(fiche.traitements_urgence[0].medicationName, 'Ventoline');
    assert.equal(fiche.dispositifs_medicaux[0].deviceName, 'Pompe à insuline');
    assert.equal(fiche.contacts_urgence[0].fullName, 'Mamie');
    assert.equal(fiche.facteurs_declenchants.other, 'Lumière vive');
  });

  test('Une réponse « non » aux facteurs est conservée', () => {
    // « Bruit : non » est une information, pas une absence.
    assert.equal(fiche.facteurs_declenchants.noise, false);
  });
});

describe('Ce qu’il faut savoir', () => {
  const fiche = profilSantePourFiche(
    PROFIL_COMPLET,
    'ce_qu_il_faut_savoir',
  );

  test('Les consignes d’urgence n’en sortent pas', () => {
    // Elles voyageaient jusqu’ici sans jamais être affichées.
    assert.equal(
      fiche.pathologies[0].emergencyInstructionSteps,
      undefined,
    );
    assert.equal(
      fiche.allergies[0].emergencyInstructionSteps,
      undefined,
    );
    assert.ok(!texte(fiche).includes('position latérale'));
    assert.ok(!texte(fiche).includes('auto-injecteur'));
  });

  test('Le médecin traitant n’en sort pas', () => {
    assert.equal(fiche.medecin_traitant, undefined);
    assert.ok(!texte(fiche).includes('Tilleuls'));
  });

  test('Le reste du contenu affiché est intact', () => {
    assert.equal(fiche.pathologies[0].name, 'Épilepsie');
    assert.equal(fiche.allergies[0].observedReaction, 'Urticaire');
    assert.equal(fiche.traitements_urgence[0].dosage, '2 bouffées');
    assert.equal(fiche.contacts_urgence[0].phoneNumber, '06 00 00 00 00');
  });
});

describe('Recommandations d’activité', () => {
  test('Aucun profil de santé n’en sort', () => {
    assert.equal(
      profilSantePourFiche(PROFIL_COMPLET, 'recommandations_activite'),
      null,
    );
  });
});

describe('Cas limites', () => {
  test('Un profil absent ne fait pas échouer le filtrage', () => {
    assert.equal(profilSantePourFiche(null, 'secours'), null);
    assert.equal(profilSantePourFiche(undefined, 'secours'), null);
    assert.equal(profilSantePourFiche('pas un objet', 'secours'), null);
  });

  test('Un profil vide donne des listes vides, pas des absences', () => {
    const fiche = profilSantePourFiche({}, 'secours');

    assert.deepEqual(fiche.pathologies, []);
    assert.deepEqual(fiche.allergies, []);
    assert.deepEqual(fiche.contacts_urgence, []);
  });

  test('Une entrée sans aucun champ affichable est retirée', () => {
    const fiche = profilSantePourFiche(
      {
        pathologies: [
          { id: 'x', hasReferringProfessional: true },
          { name: 'Asthme' },
        ],
      },
      'secours',
    );

    assert.deepEqual(fiche.pathologies, [{ name: 'Asthme' }]);
  });

  test('Un champ nul est omis plutôt qu’envoyé vide', () => {
    // Une clé absente ne dit rien de ce que la base contient ; une clé
    // à null dit « ce champ existe et il est vide ».
    const fiche = profilSantePourFiche(
      { allergies: [{ allergen: 'Arachide', observedReaction: null }] },
      'secours',
    );

    assert.deepEqual(fiche.allergies, [{ allergen: 'Arachide' }]);
  });

  test('Un identifiant d’enfant absent ne casse rien', () => {
    assert.equal(enfantPourFiche(null), null);
    assert.equal(enfantPourFiche({}), null);
  });
});
