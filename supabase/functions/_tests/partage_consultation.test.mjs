import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  TYPE_RECOMMANDATIONS,
  consulterPartage,
  lienEncoreValide,
} from '../_logique/partage_consultation.mts';

// Le lien de partage est la seule porte ouverte sans authentification
// sur des données de santé d'enfant. Ce qui est vérifié ici : qu'un
// token ne donne accès qu'à SON enfant, qu'un lien périmé ne s'ouvre
// pas, et qu'on ne puisse pas deviner si un token a existé.

const MAINTENANT = new Date('2026-08-23T12:00:00.000Z');

const PARTAGE = {
  id: 'partage-1',
  enfant_id: 'enfant-1',
  type_fiche: 'secours',
  date_expiration: '2026-08-30T12:00:00.000Z',
  contenu_fige: null,
  destinataire: 'structure_accueil',
};

const ENFANT = {
  id: 'enfant-1',
  prenom: 'Noé',
  nom: 'Dupont',
  date_naissance: '2019-04-12',
  poids: 18,
  taille: 108,
  date_maj_poids: '2026-06-01',
};

/// Faux dépôt : décrit l'état de la base, enregistre les lectures.
function fauxDepot(etat = {}) {
  const {
    partage = PARTAGE,
    erreurPartage = null,
    enfant = ENFANT,
    erreurEnfant = null,
    profilSante = { pathologies: [] },
    profilActivites = { transport: {} },
  } = etat;

  const lectures = [];

  return {
    lectures,

    async partageParToken(token) {
      lectures.push({ nom: 'partageParToken', token });
      return { partage, erreur: erreurPartage };
    },

    async enfant(enfantId) {
      lectures.push({ nom: 'enfant', enfantId });
      return { enfant, erreur: erreurEnfant };
    },

    async profilSante(enfantId) {
      lectures.push({ nom: 'profilSante', enfantId });
      return profilSante;
    },

    async profilActivites(enfantId) {
      lectures.push({ nom: 'profilActivites', enfantId });
      return profilActivites;
    },

    async marquerConsulte(partageId, horodatage) {
      lectures.push({ nom: 'marquerConsulte', partageId, horodatage });
      return { erreur: null };
    },
  };
}

describe('Validité du lien', () => {
  test('Un lien dont la date est à venir est valable', () => {
    assert.equal(
      lienEncoreValide('2026-08-30T12:00:00.000Z', MAINTENANT),
      true,
    );
  });

  test('Un lien dont la date est passée ne l’est plus', () => {
    assert.equal(
      lienEncoreValide('2026-08-23T11:59:59.000Z', MAINTENANT),
      false,
    );
  });

  test('Une date illisible vaut expirée', () => {
    // Un lien dont on ne sait pas dire s'il est encore valable ne doit
    // pas s'ouvrir.
    assert.equal(lienEncoreValide('pas une date', MAINTENANT), false);
    assert.equal(lienEncoreValide('', MAINTENANT), false);
  });
});

describe('Refus', () => {
  test('Un token absent est refusé sans toucher à la base', async () => {
    const depot = fauxDepot();

    const resultat = await consulterPartage(depot, null, MAINTENANT);

    assert.deepEqual(resultat, { statut: 'tokenAbsent' });
    assert.equal(depot.lectures.length, 0);
  });

  test('Un token vide est refusé', async () => {
    const resultat = await consulterPartage(
      fauxDepot(),
      '',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'tokenAbsent' });
  });

  test('Un token inconnu ne charge aucune donnée d’enfant', async () => {
    const depot = fauxDepot({ partage: null });

    const resultat = await consulterPartage(
      depot,
      'token-inconnu',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'tokenInconnu' });
    assert.deepEqual(depot.lectures.map((l) => l.nom), [
      'partageParToken',
    ]);
  });

  test('Un lien expiré ne charge aucune donnée d’enfant', async () => {
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        date_expiration: '2026-08-22T12:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienExpire' });
    assert.deepEqual(depot.lectures.map((l) => l.nom), [
      'partageParToken',
    ]);
  });

  test('Une panne de base ne se fait pas passer pour un lien invalide', async () => {
    const depot = fauxDepot({ erreurPartage: new Error('base') });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'erreurBase' });
  });

  test('Un enfant introuvable est refusé', async () => {
    const depot = fauxDepot({ enfant: null });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'enfantIntrouvable' });
  });
});

describe('Cloisonnement', () => {
  test('L’enfant chargé est celui du partage, jamais un autre', async () => {
    const depot = fauxDepot({
      partage: { ...PARTAGE, enfant_id: 'enfant-du-partage' },
    });

    await consulterPartage(depot, 'token-1', MAINTENANT);

    const lectureEnfant = depot.lectures.find(
      (l) => l.nom === 'enfant',
    );

    assert.equal(lectureEnfant.enfantId, 'enfant-du-partage');
  });

  test('Les profils sont chargés pour le même enfant que la fiche', async () => {
    const depot = fauxDepot({
      partage: { ...PARTAGE, enfant_id: 'enfant-du-partage' },
    });

    await consulterPartage(depot, 'token-1', MAINTENANT);

    for (const nom of ['profilSante', 'profilActivites']) {
      const lecture = depot.lectures.find((l) => l.nom === nom);
      assert.equal(lecture.enfantId, 'enfant-du-partage');
    }
  });

  test('La signature n’offre aucun moyen de désigner un autre enfant', () => {
    // consulterPartage(depot, token, maintenant) : trois paramètres,
    // dont aucun identifiant d'enfant. C'est structurel, pas une
    // convention.
    assert.equal(consulterPartage.length, 3);
  });
});

describe('Fiche renvoyée', () => {
  test('Le chemin nominal renvoie la fiche complète', async () => {
    const depot = fauxDepot();

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
    assert.deepEqual(resultat.fiche, {
      type_fiche: 'secours',
      destinataire: 'structure_accueil',
      enfant: ENFANT,
      profil_sante: { pathologies: [] },
      profil_activites: { transport: {} },
      contenu_fige: null,
    });
  });

  test('Un partage sans destinataire est traité comme un particulier', async () => {
    // Cas le plus restrictif pour la mention accolée aux traitements :
    // « selon les indications du parent » plutôt que « selon le PAI ».
    const depot = fauxDepot({
      partage: { ...PARTAGE, destinataire: null },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.fiche.destinataire, 'particulier');
  });

  test('Une fiche de recommandations ne charge aucun profil de santé', async () => {
    // Photo figée au moment du partage : les profils ne sont pas
    // nécessaires, donc ils ne quittent pas la base.
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        type_fiche: TYPE_RECOMMANDATIONS,
        contenu_fige: { sections: [{ titre: 'Eau', lignes: ['Ne sait pas nager'] }] },
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.fiche.profil_sante, null);
    assert.equal(resultat.fiche.profil_activites, null);

    assert.ok(!depot.lectures.some((l) => l.nom === 'profilSante'));
    assert.ok(!depot.lectures.some((l) => l.nom === 'profilActivites'));

    assert.deepEqual(resultat.fiche.contenu_fige, {
      sections: [{ titre: 'Eau', lignes: ['Ne sait pas nager'] }],
    });
  });

  test('Des profils absents deviennent null, pas undefined', async () => {
    // Depot ecrit a la main : passer `undefined` a fauxDepot
    // declencherait sa valeur par defaut au lieu du cas teste.
    const depot = {
      ...fauxDepot(),
      async profilSante() {
        return null;
      },
      async profilActivites() {
        return undefined;
      },
    };

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.fiche.profil_sante, null);
    assert.equal(resultat.fiche.profil_activites, null);
  });

  test('La consultation est datée', async () => {
    const depot = fauxDepot();

    await consulterPartage(depot, 'token-1', MAINTENANT);

    assert.deepEqual(depot.lectures.at(-1), {
      nom: 'marquerConsulte',
      partageId: 'partage-1',
      horodatage: '2026-08-23T12:00:00.000Z',
    });
  });
});
