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
  // Trois, comme tout partage ordinaire depuis le 01/09/2026. Le
  // reglage 1 / 2 / 5 a disparu.
  appareils_max: 3,
  declenche_en_secours: false,
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
    places = [],
    accesSecoursAutorise = false,
    demandeExistante = { existe: false, autorisee: false },
    demandesEnAttente = 0,
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

    async placesDuPartage(partageId) {
      lectures.push({ nom: 'placesDuPartage', partageId });
      return { places, erreur: null };
    },

    async prendrePlace(partageId, empreinte, prisLe) {
      lectures.push({ nom: 'prendrePlace', partageId, empreinte, prisLe });
      return { erreur: null };
    },

    async confirmerPlace(placeId) {
      lectures.push({ nom: 'confirmerPlace', placeId });
      return { erreur: null };
    },

    async demandePourEmpreinte(partageId, empreinte) {
      lectures.push({ nom: 'demandePourEmpreinte', partageId, empreinte });
      return demandeExistante;
    },

    async nombreDemandesEnAttente(partageId) {
      lectures.push({ nom: 'nombreDemandesEnAttente', partageId });
      return demandesEnAttente;
    },

    async creerDemande(entree) {
      lectures.push({ nom: 'creerDemande', ...entree });
      return { erreur: null };
    },

    async journaliserTentative(entree) {
      lectures.push({ nom: 'journaliserTentative', ...entree });
    },

    async notifierDemandeAcces(partageId, enfantId) {
      lectures.push({ nom: 'notifierDemandeAcces', partageId, enfantId });
    },

    async accesSecoursAutorise(enfantId) {
      lectures.push({ nom: 'accesSecoursAutorise', enfantId });
      return { autorise: accesSecoursAutorise, erreur: null };
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

  // --- Les places d'un partage (27/08/2026) -------------------------
  //
  // Le parent choisit combien d'appareils peuvent consulter la fiche.
  // Ce qui compte ici : un appareil refuse ne charge AUCUNE donnee, et
  // la fenetre de tolerance ne glisse pas.

  const ANCIEN = '2026-08-23T09:00:00.000Z';

  // `confirme` vaut vrai par defaut : une place qui compte. Les tests
  // du comptage au retour la passent explicitement a faux.
  function place(
    empreinte,
    prisLe = ANCIEN,
    id = 'place-1',
    confirme = true,
  ) {
    return { id, empreinte, pris_le: prisLe, confirme };
  }

  test('La première ouverture prend une place et rend le secret', async () => {
    const depot = fauxDepot({ places: [] });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { genererSecret: () => 'secret-neuf' },
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.secret, 'secret-neuf');

    const prise = depot.lectures.find((l) => l.nom === 'prendrePlace');

    assert.ok(prise, 'une place doit être prise');
    assert.notEqual(
      prise.empreinte,
      'secret-neuf',
      'c’est l’empreinte qui est stockée, jamais le secret',
    );
  });

  test('Le même appareil repasse sans nouveau secret', async () => {
    const depot = fauxDepot({
      places: [place(await empreinteDuSecret('secret-connu'))],
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
      depot.lectures.some((l) => l.nom === 'prendrePlace'),
      false,
    );
  });

  test('Un secret inconnu entre tant qu’il reste de la place', async () => {
    // Une seule place prise sur trois : rien ne justifie de bloquer.
    const depot = fauxDepot({
      places: [place(await empreinteDuSecret('celui-du-premier'))],
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'un-autre' },
    );

    // Trois places, une seule prise : il entre. Le test porte
    // desormais sur un plafond atteint.
    assert.equal(resultat.statut, 'ok');
  });

  test('La tentative refusée est enregistrée, non tolérée', async () => {
    // Il faut les trois places prises pour qu'il y ait refus.
    const depot = fauxDepot({
      places: [
        place(await empreinteDuSecret('un'), ANCIEN, 'place-1'),
        place(await empreinteDuSecret('deux'), ANCIEN, 'place-2'),
        place(await empreinteDuSecret('trois'), ANCIEN, 'place-3'),
      ],
    });

    await consulterPartage(depot, 'token-1', MAINTENANT, {
      secretPresente: null,
    });

    const tentative = depot.lectures.find(
      (l) => l.nom === 'journaliserTentative',
    );

    assert.equal(tentative.toleree, false);
    assert.equal(tentative.partageId, 'partage-1');
  });

  test('Une place ne compte qu’au retour du navigateur', async () => {
    // Le cas de la fenetre integree d'un lecteur de QR : elle ouvre
    // la fiche une fois et ne revient jamais. Elle ne doit consommer
    // aucune des trois places.
    const depot = fauxDepot({
      places: [
        place(await empreinteDuSecret('un'), ANCIEN, 'place-1', false),
        place(await empreinteDuSecret('deux'), ANCIEN, 'place-2', false),
        place(await empreinteDuSecret('trois'), ANCIEN, 'place-3', false),
      ],
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: null, genererSecret: () => 'secret-neuf' },
    );

    assert.equal(resultat.statut, 'ok');
    assert.ok(depot.lectures.some((l) => l.nom === 'prendrePlace'));
  });

  test('Le retour du même navigateur confirme sa place', async () => {
    const depot = fauxDepot({
      places: [
        place(await empreinteDuSecret('le-mien'), ANCIEN, 'place-1', false),
      ],
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'le-mien' },
    );

    assert.equal(resultat.statut, 'ok');

    const confirmation = depot.lectures.find(
      (l) => l.nom === 'confirmerPlace',
    );

    assert.equal(confirmation.placeId, 'place-1');

    assert.equal(
      depot.lectures.some((l) => l.nom === 'prendrePlace'),
      false,
      'un navigateur connu ne consomme pas une seconde place',
    );
  });

  test('La grand-mère mardi, le grand-père jeudi', async () => {
    // Deux places, aucune contrainte de simultaneite : seule la duree
    // de validite du lien compte.
    const depot = fauxDepot({
      partage: { ...PARTAGE, appareils_max: 2 },
      places: [
        place(
          await empreinteDuSecret('celui-de-mardi'),
          '2026-08-21T09:00:00.000Z',
        ),
      ],
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: null, genererSecret: () => 'secret-jeudi' },
    );

    assert.equal(resultat.statut, 'ok');
    assert.equal(resultat.secret, 'secret-jeudi');
    assert.ok(depot.lectures.find((l) => l.nom === 'prendrePlace'));
  });

  test('Le quatrième appareil doit demander au parent',
    async () => {
      // Des la PREMIERE visite : sinon un inconnu lirait la fiche
      // une fois avant d'etre arrete, ce qui viderait la regle.
      const depot = fauxDepot({
        places: [
          place(await empreinteDuSecret('un'), ANCIEN, 'place-1'),
          place(await empreinteDuSecret('deux'), ANCIEN, 'place-2'),
          place(await empreinteDuSecret('trois'), ANCIEN, 'place-3'),
        ],
      });

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
        { secretPresente: null, genererSecret: () => 'secret-neuf' },
      );

      assert.equal(resultat.statut, 'demandeRequise');
      assert.equal(resultat.secret, 'secret-neuf');

      // Aucune donnee d'enfant n'est lue : le refus tombe avant.
      assert.equal(
        depot.lectures.some((l) => l.nom === 'enfant'),
        false,
      );
    });

  test('Un lien révoqué est refusé avant même les places', async () => {
    // L'ordre compte : inutile d'occuper une place sur un lien mort.
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

// La fenêtre d'un code à scanner (28/08/2026).
//
// Un code de partage est la même ligne `partages` qu'un lien : même
// jeton, même page, même verrou. Seule s'y ajoute une fenêtre de cinq
// minutes pendant laquelle le jeton peut être réclamé pour la première
// fois.
//
// Les deux durées ne se mélangent jamais, et c'est ce que ce bloc
// protège : si la fenêtre débordait sur l'accès, le destinataire
// perdrait sa fiche cinq minutes après l'avoir reçue.
describe('Le code à scanner et sa fenêtre de cinq minutes', () => {
  const codeDe = (utilisableJusquA) => ({
    ...PARTAGE,
    utilisable_jusqu_a: utilisableJusquA,
  });

  const OUVERTE = '2026-08-23T12:04:00.000Z';
  const FERMEE = '2026-08-23T11:55:00.000Z';

  test('Fenêtre ouverte et personne n’a scanné : la fiche s’ouvre',
    async () => {
      const depot = fauxDepot({ partage: codeDe(OUVERTE) });

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
      );

      assert.equal(resultat.statut, 'ok');
    });

  test('Fenêtre fermée et personne n’a scanné : refusé', async () => {
    const depot = fauxDepot({ partage: codeDe(FERMEE) });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'codeExpire' });
  });

  test('Le refus ne charge aucune donnée d’enfant', async () => {
    // Comme pour un lien expiré : rien ne se lit avant que le droit
    // d'entrer soit établi.
    const depot = fauxDepot({ partage: codeDe(FERMEE) });

    await consulterPartage(depot, 'token-1', MAINTENANT);

    assert.equal(
      depot.lectures.some((l) => l.nom === 'enfant'),
      false,
    );
  });

  test('Une fois scanné, la fenêtre ne compte plus', async () => {
    // LE test de ce chantier. Sans lui, le destinataire perdrait son
    // accès cinq minutes après l'avoir reçu, alors que le parent lui
    // a donné des jours.
    const secret = 'le-mien';

    const depot = fauxDepot({
      partage: codeDe(FERMEE),
      places: [
        {
          id: 'place-1',
          empreinte: await empreinteDuSecret(secret),
          pris_le: '2026-08-23T11:50:00.000Z',
        },
      ],
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: secret },
    );

    assert.equal(resultat.statut, 'ok');
  });

  test('Une fenêtre nulle vaut ouverte', async () => {
    // Un lien ordinaire n'en a pas, et les lignes créées avant le
    // 28/08/2026 non plus : les traiter comme fermées couperait tous
    // les partages existants.
    const depot = fauxDepot({ partage: codeDe(null) });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
  });

  test('Une date illisible ne coupe pas l’accès', async () => {
    // Une donnée abîmée ne doit pas fermer une porte que le parent a
    // ouverte. Le reste des contrôles tient toujours.
    const depot = fauxDepot({ partage: codeDe('pas-une-date') });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.equal(resultat.statut, 'ok');
  });

  test('La révocation passe avant la fenêtre', async () => {
    const depot = fauxDepot({
      partage: {
        ...codeDe(OUVERTE),
        revoque_le: '2026-08-23T11:00:00.000Z',
      },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
    );

    assert.deepEqual(resultat, { statut: 'lienRevoque' });
  });
});

// La demande d'accès au parent (01/09/2026).
//
// Au quatrième appareil, la personne est arrêtée. Elle dit qui elle
// est en soixante caractères, et le parent décide. Un seul bouton
// « autoriser cet appareil » — pas de « ne plus me demander » :
// l'application ne sait pas distinguer les appareils d'une personne de
// ceux de plusieurs, et cette option ouvrirait exactement la porte
// qu'on cherche à fermer.
describe('La demande d’accès au parent', () => {
  const ANCIEN = '2026-08-22T09:00:00.000Z';

  function troisPlacesPrises(un, deux, trois) {
    return [
      { id: 'place-1', empreinte: un, pris_le: ANCIEN, confirme: true },
      { id: 'place-2', empreinte: deux, pris_le: ANCIEN, confirme: true },
      { id: 'place-3', empreinte: trois, pris_le: ANCIEN, confirme: true },
    ];
  }

  async function depotPlein(etat = {}) {
    return fauxDepot({
      places: troisPlacesPrises(
        await empreinteDuSecret('un'),
        await empreinteDuSecret('deux'),
        await empreinteDuSecret('trois'),
      ),
      ...etat,
    });
  }

  test('Sans raison, on demande à la personne de se présenter',
    async () => {
      const depot = await depotPlein();

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
        { genererSecret: () => 'secret-du-quatrieme' },
      );

      assert.equal(resultat.statut, 'demandeRequise');

      // Le secret lui est remis alors qu'elle n'a aucune place : sans
      // lui, elle reviendrait en inconnue et sa demande serait
      // orpheline.
      assert.equal(resultat.secret, 'secret-du-quatrieme');

      assert.equal(
        depot.lectures.some((l) => l.nom === 'creerDemande'),
        false,
      );
    });

  test('Aucune donnée d’enfant n’est lue avant la décision', async () => {
    const depot = await depotPlein();

    await consulterPartage(depot, 'token-1', MAINTENANT, {});

    for (const interdit of ['enfant', 'profilSante', 'profilActivites']) {
      assert.equal(
        depot.lectures.some((l) => l.nom === interdit),
        false,
        `${interdit} ne doit pas être lu`,
      );
    }
  });

  test('Avec une raison, la demande est enregistrée', async () => {
    const depot = await depotPlein();

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'le-quatrieme', raisonDemande: 'Mamie Denise' },
    );

    assert.deepEqual(resultat, { statut: 'demandeEnregistree' });

    const creation = depot.lectures.find((l) => l.nom === 'creerDemande');

    assert.equal(creation.raison, 'Mamie Denise');
    assert.equal(creation.partageId, 'partage-1');

    // L'empreinte, jamais le secret : une fuite de la table ne
    // donnerait à personne de quoi ouvrir un lien.
    assert.equal(
      creation.empreinte,
      await empreinteDuSecret('le-quatrieme'),
    );
    assert.ok(!creation.empreinte.includes('le-quatrieme'));
  });

  test('Le parent est prévenu, après l’enregistrement', async () => {
    // Jamais avant : un parent prévenu d'une demande qui n'existe pas
    // chercherait dans sa liste quelque chose d'introuvable.
    const depot = await depotPlein();

    await consulterPartage(depot, 'token-1', MAINTENANT, {
      secretPresente: 'le-quatrieme',
      raisonDemande: 'Mamie Denise',
    });

    const noms = depot.lectures.map((l) => l.nom);

    assert.ok(
      noms.indexOf('creerDemande') < noms.indexOf('notifierDemandeAcces'),
    );
  });

  test('Une raison vide ne vaut pas une raison', async () => {
    // Elle est obligatoire : le parent doit savoir à qui il ouvre.
    const depot = await depotPlein();

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'le-quatrieme', raisonDemande: '   ' },
    );

    assert.equal(resultat.statut, 'demandeRequise');
  });

  test('Une deuxième demande du même appareil ne se duplique pas',
    async () => {
      const depot = await depotPlein({
        demandeExistante: { existe: true, autorisee: false },
      });

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
        { secretPresente: 'le-quatrieme', raisonDemande: 'encore moi' },
      );

      assert.deepEqual(resultat, { statut: 'demandeEnAttente' });

      assert.equal(
        depot.lectures.some((l) => l.nom === 'creerDemande'),
        false,
      );
    });

  test('Trois demandes en attente, et la porte se ferme', async () => {
    // Règle de Fanny du 25/08/2026, reprise telle quelle : au-delà, le
    // parent doit trancher celles qu'il a.
    const depot = await depotPlein({ demandesEnAttente: 3 });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'le-quatrieme', raisonDemande: 'Mamie Denise' },
    );

    assert.deepEqual(resultat, { statut: 'tropDeDemandes' });

    assert.equal(
      depot.lectures.some((l) => l.nom === 'creerDemande'),
      false,
    );
  });

  test('Le plafond relevé par le parent laisse entrer l’appareil',
    async () => {
      // « Autoriser cet appareil » monte le plafond d'une unité. Le
      // cinquième redemandera.
      const depot = await depotPlein({
        partage: { ...PARTAGE, appareils_max: 4 },
      });

      const resultat = await consulterPartage(
        depot,
        'token-1',
        MAINTENANT,
        { secretPresente: 'le-quatrieme', genererSecret: () => 'neuf' },
      );

      assert.equal(resultat.statut, 'ok');
      assert.ok(depot.lectures.some((l) => l.nom === 'prendrePlace'));
    });

  test('Un lien révoqué ne se demande pas', async () => {
    // La révocation passe avant tout : c'est le seul geste par lequel
    // le parent coupe, et il ne se contourne pas.
    const depot = await depotPlein({
      partage: { ...PARTAGE, revoque_le: '2026-08-24T09:00:00.000Z' },
    });

    const resultat = await consulterPartage(
      depot,
      'token-1',
      MAINTENANT,
      { secretPresente: 'le-quatrieme', raisonDemande: 'Mamie' },
    );

    assert.deepEqual(resultat, { statut: 'lienRevoque' });
  });
});
