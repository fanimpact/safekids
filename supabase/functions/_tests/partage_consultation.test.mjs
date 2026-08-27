import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  TYPE_RECOMMANDATIONS,
  consulterPartage,
  lienEncoreValide,
} from '../_logique/partage_consultation.mts';

import { empreinteDuSecret } from '../_logique/verrou_partage.mts';

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
  revoque_le: null,
  permanent: false,
  verrou_empreinte: null,
  verrou_pose_le: null,
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

    async journaliserOuverture(entree) {
      lectures.push({ nom: 'journaliserOuverture', ...entree });
    },

    async poserVerrou(partageId, empreinte, poseLe) {
      lectures.push({ nom: 'poserVerrou', partageId, empreinte, poseLe });
      return { erreur: null };
    },

    async journaliserTentative(entree) {
      lectures.push({ nom: 'journaliserTentative', ...entree });
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

  // Revocation par marquage (27/08/2026). Avant, revoquer supprimait la
  // ligne : le lien tombait en « tokenInconnu ». Desormais la ligne
  // reste, et c'est ce test qui garantit que l'acces est coupe quand
  // meme.
  test('Un lien révoqué ne s’ouvre pas, même avant son échéance', async () => {
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        date_expiration: '2026-08-30T12:00:00.000Z',
        revoque_le: '2026-08-24T09:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienRevoque' });
    assert.deepEqual(depot.lectures.map((l) => l.nom), [
      'partageParToken',
    ]);
  });

  test('Un lien permanent révoqué ne s’ouvre pas non plus', async () => {
    // La revocation passe avant tout : c'est le seul moyen d'arreter un
    // lien qui n'expire jamais.
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        date_expiration: null,
        permanent: true,
        revoque_le: '2026-08-24T09:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienRevoque' });
  });

  test('Un lien permanent s’ouvre malgré son absence de date', async () => {
    // Sans le cas « permanent », une date nulle serait lue comme
    // illisible et tous les liens permanents seraient refuses.
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        date_expiration: null,
        permanent: true,
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
  });

  test('Sans date et sans être permanent, le lien est refusé', async () => {
    // La contrainte en base l'interdit. Si cela arrive quand meme —
    // migration a moitie appliquee, ecriture directe — on refuse plutot
    // que d'ouvrir un lien dont personne ne sait dire s'il est valable.
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        date_expiration: null,
        permanent: false,
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienExpire' });
  });

  // --- Le verrou a la premiere ouverture (27/08/2026) ----------------
  //
  // C'est lui qui a permis de liberer les durees. Ce qui compte ici :
  // un appareil refuse ne doit charger AUCUNE donnee d'enfant.

  test('La première ouverture pose le verrou et rend le secret', async () => {
    const depot = fauxDepot({ partage: { ...PARTAGE } });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { genererSecret: () => 'secret-neuf' },
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.secret, 'secret-neuf');

    const pose = depot.lectures.find((l) => l.nom === 'poserVerrou');

    assert.ok(pose, 'le verrou doit être posé');
    assert.notEqual(
      pose.empreinte,
      'secret-neuf',
      'c’est l’empreinte qui est stockée, jamais le secret',
    );
  });

  test('Le même appareil repasse sans nouveau secret', async () => {
    const empreinte = await empreinteDuSecret('secret-connu');

    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        verrou_empreinte: empreinte,
        verrou_pose_le: '2026-08-23T09:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'secret-connu' },
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.secret, undefined);
    assert.equal(
      depot.lectures.some((l) => l.nom === 'poserVerrou'),
      false,
    );
  });

  test('Un autre appareil est refusé et ne charge aucune donnée', async () => {
    // Le point qui compte : le refus tombe AVANT la lecture de
    // l'enfant, du profil de santé et du profil d'activités.
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        verrou_empreinte: await empreinteDuSecret('celui-du-premier'),
        verrou_pose_le: '2026-08-23T09:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'un-autre' },
    );

    assert.deepEqual(resultat, { statut: 'lienVerrouille' });
    assert.deepEqual(depot.lectures.map((l) => l.nom), [
      'partageParToken',
      'journaliserTentative',
    ]);
  });

  test('La tentative refusée est enregistrée, non tolérée', async () => {
    const depot = fauxDepot({
      partage: {
        ...PARTAGE,
        verrou_empreinte: await empreinteDuSecret('celui-du-premier'),
        verrou_pose_le: '2026-08-23T09:00:00.000Z',
      },
    });

    await consulterPartage(depot, 'token-1', MAINTENANT, {
      secretPresente: null,
    });

    const tentative = depot.lectures.find(
      (l) => l.nom === 'journaliserTentative',
    );

    assert.equal(tentative.toleree, false);
    assert.equal(tentative.partageId, 'partage-1');
    assert.equal(tentative.tenteeLe, MAINTENANT.toISOString());
  });

  test('Dans la fenêtre, le second appareil reprend et le parent est prévenu',
    async () => {
      // Correction de Fanny : ne rien dire pendant quinze minutes
      // créerait un trou invisible. La ligne est écrite quand même,
      // marquée tolérée — information, pas refus.
      const depot = fauxDepot({
        partage: {
          ...PARTAGE,
          verrou_empreinte: await empreinteDuSecret('celui-du-premier'),
          verrou_pose_le: new Date(
            MAINTENANT.getTime() - 60000,
          ).toISOString(),
        },
      });

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
        { secretPresente: null, genererSecret: () => 'secret-repris' },
      );

      assert.equal(resultat.statut, 'ok');
      assert.equal(resultat.secret, 'secret-repris');

      const tentative = depot.lectures.find(
        (l) => l.nom === 'journaliserTentative',
      );

      assert.equal(tentative.toleree, true);
    });

  test('Un lien révoqué est refusé avant même le verrou', async () => {
    // L'ordre compte : inutile de poser un verrou sur un lien mort.
    const depot = fauxDepot({
      partage: { ...PARTAGE, revoque_le: '2026-08-24T09:00:00.000Z' },
    });

    const resultat = await consulterPartage(depot, 'token-1', MAINTENANT);

    assert.deepEqual(resultat, { statut: 'lienRevoque' });
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

    const lecture = depot.lectures.find(
      (l) => l.nom === 'profilSante',
    );

    assert.equal(lecture.enfantId, 'enfant-du-partage');

    // Le profil Activites n'est plus lu du tout : il n'etait affiche
    // sur aucune fiche.
    assert.ok(
      !depot.lectures.some((l) => l.nom === 'profilActivites'),
    );
  });

  test('La signature n’offre aucun moyen de désigner un autre enfant', () => {
    // consulterPartage(depot, token, maintenant) : trois paramètres,
    // dont aucun identifiant d'enfant. C'est structurel, pas une
    // convention.
    assert.equal(consulterPartage.length, 3);
  });
});

describe('Fiche renvoyée', () => {
  test('Le chemin nominal renvoie la fiche demandee', async () => {
    const depot = fauxDepot();

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.fiche.type_fiche, 'secours');
    assert.equal(resultat.fiche.destinataire, 'structure_accueil');
    assert.equal(resultat.fiche.contenu_fige, null);

    // L2019identifiant de l2019enfant ne sort pas : la page ne l2019affiche pas,
    // le navigateur n2019a aucune raison de le connaitre.
    assert.deepEqual(Object.keys(resultat.fiche.enfant), [
      'prenom',
      'nom',
      'date_naissance',
      'poids',
      'taille',
      'date_maj_poids',
    ]);

    // Le profil Activites n2019est affiche sur aucune fiche : il ne quitte
    // plus la base.
    assert.equal(resultat.fiche.profil_activites, null);
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

    assert.deepEqual(
      depot.lectures.find((l) => l.nom === 'marquerConsulte'),
      {
        nom: 'marquerConsulte',
        partageId: 'partage-1',
        horodatage: '2026-08-23T12:00:00.000Z',
      },
    );
  });

  test('Chaque ouverture est journalisee, sans rien de plus', async () => {
    // `marquerConsulte` n'ecrase qu'une date. C'est cette ligne-la que
    // le parent lira dans la tracabilite de son enfant.
    const depot = fauxDepot();

    await consulterPartage(depot, 'token-1', MAINTENANT);

    const journal = depot.lectures.find(
      (l) => l.nom === 'journaliserOuverture',
    );

    assert.deepEqual(journal, {
      nom: 'journaliserOuverture',
      enfantId: 'enfant-1',
      partageId: 'partage-1',
      typeFiche: 'secours',
      ouvertLe: '2026-08-23T12:00:00.000Z',
    });

    // Ni adresse IP, ni empreinte de navigateur : la signature ne
    // permet meme pas d'en passer une.
    assert.deepEqual(Object.keys(journal).sort(), [
      'enfantId',
      'nom',
      'ouvertLe',
      'partageId',
      'typeFiche',
    ]);
  });

  test(
    'Une journalisation qui echoue ne prive pas l2019accompagnant de la fiche',
    async () => {
      // Une trace perdue est regrettable ; une fiche non rendue peut
      // mettre un enfant en danger.
      const depot = {
        ...fauxDepot(),
        async journaliserOuverture() {
          throw new Error('base injoignable');
        },
      };

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
      );

      assert.equal(resultat.statut, 'ok');
    },
  );
});
