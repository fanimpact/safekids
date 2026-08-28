import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';

import {
  ADRESSE_API_PAR_DEFAUT,
  construirePage,
} from '../_logique/page_partage.mts';

// Page publique d'un lien de partage : ce que voit un accompagnant qui
// n'a pas l'application. C'est le seul rendu de données de santé
// d'enfant qui échappe complètement à Flutter, donc aux 309 tests.
//
// Les tests ci-dessous exécutent le script réel de la page dans un faux
// DOM, plutôt qu'une copie de sa logique : ce qui est vérifié est
// exactement ce qui sera servi.

const MAINTENANT = new Date('2026-08-23T12:00:00.000Z');

/// Élément minimal : juste ce que le script de la page manipule.
function element() {
  return {
    innerHTML: '',
    textContent: '',
    style: { display: '' },
  };
}

/// Exécute la page avec la fiche donnée et rend les éléments obtenus.
/// `fiche` à `null` simule une réponse en erreur de l'API.
async function rendre(fiche, options = {}) {
  const {
    token = 'token-1',
    reponseOk = true,
    statut = reponseOk ? 200 : 500,
  } = options;

  const elements = {
    'estado-chargement': element(),
    'estado-erreur': element(),
    'titre-erreur': element(),
    'texte-erreur': element(),
    'estado-verrouille': element(),
    contenu: element(),
    'bandeau-secours': element(),
    'titre-bandeau-secours': element(),
    'texte-bandeau-secours': element(),
    'bloc-secours': element(),
    'bouton-secours': element(),
    'confirmation-secours': element(),
    'annuler-secours': element(),
    'confirmer-secours': element(),
    'resultat-secours': element(),
    'fin-acces-secours': element(),
    'adresse-secours': element(),
    'nom-enfant': element(),
    'details-identite': element(),
    sections: element(),
  };

  const appelsFetch = [];

  // `new Date()` sans argument doit rendre une date fixe : le calcul de
  // l'âge en dépend, et un test ne doit pas changer de résultat avec le
  // temps.
  class DateFigee extends Date {
    constructor(...args) {
      super(...(args.length ? args : [MAINTENANT.getTime()]));
    }
  }

  const bacASable = {
    document: {
      getElementById(id) {
        return elements[id] ?? null;
      },
    },
    window: {
      location: {
        origin: 'https://exemple.test',
        // Le jeton vit dans le fragment : il n'est pas transmis au
        // serveur qui sert la page, donc pas dans ses journaux.
        hash: token ? `#jeton=${token}` : '',
        search: '',
      },
      localStorage: {
        getItem() {
          return null;
        },
        setItem() {},
      },
    },
    URLSearchParams,
    encodeURIComponent,
    Date: DateFigee,
    isNaN,
    Object,
    String,
    Error,
    console,
    fetch(url) {
      appelsFetch.push(url);

      return Promise.resolve({
        ok: reponseOk,
        status: statut,
        json: () => Promise.resolve(fiche ?? { error: 'Lien expiré ou invalide.' }),
      });
    },
  };

  const page = construirePage(options.cheminApi);
  const script = page.slice(
    page.indexOf('<script>') + '<script>'.length,
    page.indexOf('</script>'),
  );

  vm.runInNewContext(script, bacASable);

  // Laisse la chaîne de promesses du script se dérouler.
  await new Promise((resoudre) => setImmediate(resoudre));

  return { elements, appelsFetch };
}

const ENFANT = {
  prenom: 'Noé',
  nom: 'Dupont',
  date_naissance: '2019-04-12',
  poids: 18,
  taille: 108,
  date_maj_poids: '2026-06-01',
};

function ficheSecours(profilSante, surcharges = {}) {
  return {
    type_fiche: 'secours',
    destinataire: 'particulier',
    enfant: ENFANT,
    profil_sante: profilSante,
    profil_activites: {},
    contenu_fige: null,
    ...surcharges,
  };
}

describe('Adresse interrogée', () => {
  test('Par défaut, l’adresse absolue de la fonction', async () => {
    // Absolue et non un chemin : la page est servie par
    // fiche.kidsrelay.fr, la fonction par Supabase.
    const { appelsFetch } = await rendre(ficheSecours({}));

    assert.equal(
      appelsFetch[0],
      ADRESSE_API_PAR_DEFAUT + '?token=token-1',
    );
    assert.match(ADRESSE_API_PAR_DEFAUT, /^https:\/\//);
  });

  test('Le jeton est lu dans le fragment, jamais dans la requête',
    async () => {
      // Le fragment n'est pas transmis au serveur : le jeton
      // n'apparait dans aucun journal d'acces de l'hebergeur.
      const page = construirePage();

      assert.match(page, /window.location.hash/);
      assert.equal(
        page.includes('window.location.search'),
        false,
      );
    });

  test('Une autre adresse suffit à servir la page ailleurs', async () => {
    // L'adresse est desormais absolue : la page ne prefixe plus rien
    // avec l'origine du navigateur, puisqu'elle n'est plus servie par
    // le meme domaine que la fonction.
    const { appelsFetch } = await rendre(ficheSecours({}), {
      cheminApi: 'https://ailleurs.test/api/partage',
    });

    assert.equal(
      appelsFetch[0],
      'https://ailleurs.test/api/partage?token=token-1',
    );
  });

  test('Sans jeton, aucun appel n’est fait et l’adresse est mise en cause',
    async () => {
      // Le cas rencontre le 27/08/2026 : une adresse ouverte depuis
      // l'historique, sans le fragment. Dire « ce lien a expire »
      // envoyait reclamer un nouveau lien pour rien.
      const { elements, appelsFetch } = await rendre(null, {
        token: '',
      });

      assert.equal(appelsFetch.length, 0);
      assert.equal(elements['estado-erreur'].style.display, 'block');
      assert.equal(elements['estado-chargement'].style.display, 'none');
      assert.match(
        elements['titre-erreur'].textContent,
        /Il manque quelque chose dans cette adresse/,
      );
    });

  test('Un lien expiré et un lien révoqué disent la même chose',
    async () => {
      // Decision de Fanny : rien ne doit laisser deviner que le parent
      // a coupe l'acces. Le serveur repond 410 dans les deux cas.
      const expire = await rendre(null, { reponseOk: false, statut: 410 });
      const inconnu = await rendre(null, { reponseOk: false, statut: 404 });

      assert.equal(
        expire.elements['titre-erreur'].textContent,
        'Ce lien ne fonctionne plus',
      );
      assert.equal(
        inconnu.elements['titre-erreur'].textContent,
        expire.elements['titre-erreur'].textContent,
      );
      assert.match(
        expire.elements['texte-erreur'].textContent,
        /ou le parent y a mis un terme/,
      );
    });

  test('Un refus du verrou n’envoie pas réclamer un nouveau lien',
    async () => {
      // C'est le message qui porte tout le mecanisme de demande
      // d'acces : le professionnel doit comprendre qu'un nouveau lien
      // ne changerait rien.
      const { elements } = await rendre(null, {
        reponseOk: false,
        statut: 423,
      });

      assert.equal(elements['estado-verrouille'].style.display, 'block');
      assert.equal(elements['estado-erreur'].style.display, '');

      const page = construirePage();

      assert.match(page, /pas la peine de demander qu’on vous le/);
      assert.match(page, /Rapprochez-vous du parent/);
    });

  test('Une panne de réseau ne se fait pas passer pour un lien mort',
    async () => {
      const { elements } = await rendre(null, {
        reponseOk: false,
        statut: 500,
      });

      assert.equal(
        elements['titre-erreur'].textContent,
        'Impossible d’afficher cette fiche',
      );
      assert.equal(elements.contenu.style.display, '');
    });
});

describe('Identité', () => {
  test('Le nom complet et les mesures sont affichés', async () => {
    const { elements } = await rendre(ficheSecours({}));

    assert.equal(elements['nom-enfant'].textContent, 'Noé Dupont');
    assert.equal(
      elements['details-identite'].textContent,
      '7 ans · 18 kg · 108 cm · mesurés le 01/06/2026',
    );
  });

  test('Une date de mesure absente est dite, pas masquée', async () => {
    const { elements } = await rendre(
      ficheSecours({}, {
        enfant: { ...ENFANT, date_maj_poids: null },
      }),
    );

    assert.ok(
      elements['details-identite'].textContent.includes(
        'date de mesure non renseignée',
      ),
    );
  });

  test('Un enfant sans nom renseigné garde un titre lisible', async () => {
    const { elements } = await rendre(
      ficheSecours({}, { enfant: {} }),
    );

    assert.equal(elements['nom-enfant'].textContent, 'Enfant');
  });
});

describe('Consignes d’urgence', () => {
  const PROFIL = {
    pathologies: [
      {
        name: 'Épilepsie',
        emergencyInstructionSteps: [
          'Mettre en position latérale de sécurité',
          'Déclencher un chronomètre',
        ],
      },
    ],
    allergies: [
      {
        allergen: 'Arachide',
        emergencyInstructionSteps: ['Donner l’auto-injecteur'],
      },
    ],
  };

  test('Elles apparaissent sur la fiche secours, numérotées', async () => {
    const { elements } = await rendre(ficheSecours(PROFIL));

    const html = elements.sections.innerHTML;

    assert.ok(html.includes('Consignes d’urgence'));
    assert.ok(
      html.includes('<li>1. Mettre en position latérale de sécurité</li>'),
    );
    assert.ok(html.includes('<li>2. Déclencher un chronomètre</li>'));
    assert.ok(html.includes('<li>1. Donner l’auto-injecteur</li>'));
  });

  test('Elles sont mises en avant visuellement', async () => {
    const { elements } = await rendre(ficheSecours(PROFIL));

    assert.ok(
      elements.sections.innerHTML.includes(
        '<div class="section highlight"><h2>Consignes d’urgence</h2>',
      ),
    );
  });

  test('Elles n’apparaissent pas sur une fiche "ce qu’il faut savoir"', async () => {
    const { elements } = await rendre(
      ficheSecours(PROFIL, { type_fiche: 'ce_qu_il_faut_savoir' }),
    );

    assert.ok(
      !elements.sections.innerHTML.includes('Consignes d’urgence'),
    );
  });

  test('Une consigne sans étape renseignée n’ouvre pas un bloc vide', async () => {
    const { elements } = await rendre(
      ficheSecours({
        pathologies: [
          { name: 'Asthme', emergencyInstructionSteps: ['  ', ''] },
        ],
      }),
    );

    assert.ok(
      !elements.sections.innerHTML.includes('Consignes d’urgence'),
    );
  });
});

describe('Mention accolée aux traitements', () => {
  const PROFIL = {
    traitements_urgence: [
      { medicationName: 'Ventoline', dosage: '2 bouffées' },
    ],
  };

  test('Structure d’accueil : selon le PAI', async () => {
    const { elements } = await rendre(
      ficheSecours(PROFIL, { destinataire: 'structure_accueil' }),
    );

    assert.ok(
      elements.sections.innerHTML.includes(
        'Ventoline — 2 bouffées — posologie et administration selon le PAI',
      ),
    );
  });

  test('Particulier : selon les indications du parent', async () => {
    const { elements } = await rendre(
      ficheSecours(PROFIL, { destinataire: 'particulier' }),
    );

    assert.ok(
      elements.sections.innerHTML.includes(
        'selon les indications du parent',
      ),
    );
    assert.ok(!elements.sections.innerHTML.includes('PAI'));
  });
});

describe('Échappement', () => {
  // Un prénom, un nom de traitement ou une réaction allergique sont
  // saisis par un parent : ils ne doivent jamais pouvoir devenir du
  // HTML sur une page publique.

  test('Une allergie contenant du balisage est neutralisée', async () => {
    const { elements } = await rendre(
      ficheSecours({
        allergies: [
          {
            allergen: '<script>alert(1)</script>',
            observedReaction: 'urticaire',
          },
        ],
      }),
    );

    const html = elements.sections.innerHTML;

    assert.ok(html.includes('&lt;script&gt;alert(1)&lt;/script&gt;'));
    assert.ok(!html.includes('<script>alert(1)'));
  });

  test('Le prénom passe par textContent, jamais par innerHTML', async () => {
    const { elements } = await rendre(
      ficheSecours({}, {
        enfant: { ...ENFANT, prenom: '<b>Noé</b>' },
      }),
    );

    assert.equal(
      elements['nom-enfant'].textContent,
      '<b>Noé</b> Dupont',
    );
    assert.equal(elements['nom-enfant'].innerHTML, '');
  });
});

describe('Fiche de recommandations d’activité', () => {
  test('Le contenu figé est rendu tel quel, jamais recalculé', async () => {
    const { elements } = await rendre({
      type_fiche: 'recommandations_activite',
      destinataire: 'particulier',
      enfant: ENFANT,
      profil_sante: null,
      profil_activites: null,
      contenu_fige: {
        activite_nom: 'Sortie piscine',
        activite_date: '2026-09-10T09:00:00.000Z',
        activite_lieu: 'Piscine municipale',
        sections: [
          { titre: 'Eau', lignes: ['Ne sait pas nager'] },
        ],
      },
    });

    const html = elements.sections.innerHTML;

    assert.ok(
      html.includes(
        'Sortie piscine · 10/09/2026 · Piscine municipale',
      ),
    );
    assert.ok(html.includes('<h2>Eau</h2>'));
    assert.ok(html.includes('<li>Ne sait pas nager</li>'));
  });

  test('Un contenu figé absent n’empêche pas la page de s’afficher', async () => {
    const { elements } = await rendre({
      type_fiche: 'recommandations_activite',
      destinataire: 'particulier',
      enfant: ENFANT,
      profil_sante: null,
      profil_activites: null,
      contenu_fige: null,
    });

    assert.equal(elements.contenu.style.display, 'block');
    assert.equal(elements['estado-erreur'].style.display, '');
  });
});

describe('Sections vides', () => {
  test('Une section sans ligne n’est pas affichée', async () => {
    const { elements } = await rendre(
      ficheSecours({ pathologies: [], allergies: [] }),
    );

    const html = elements.sections.innerHTML;

    assert.ok(!html.includes('Pathologies'));
    assert.ok(!html.includes('Allergies'));
  });

  test('Une entrée sans nom est ignorée, pas rendue à moitié', async () => {
    const { elements } = await rendre(
      ficheSecours({
        pathologies: [{ approximateDiagnosisDate: '2024' }],
      }),
    );

    assert.ok(!elements.sections.innerHTML.includes('Pathologies'));
  });
});

describe('Accès secours, sur la page publique', () => {
  test('Le bouton n’apparaît pas si le parent n’a rien autorisé', () => {
    // Afficher un geste qui sera refusé ne sert personne, et en
    // situation d'urgence c'est pire qu'inutile.
    const page = construirePage();

    assert.match(page, /L’enfant part avec les secours/);
    assert.match(page, /if \(!data\.acces_secours_disponible\)/);
  });

  test('Le bouton est en bas de la fiche, pas dans un menu', () => {
    // Tout le dispositif repose sur un geste a faire en dix secondes
    // sous stress : le bouton doit etre visible sans defilement ni
    // menu, dans le bloc de la fiche elle-meme.
    const page = construirePage();
    const contenu = page.indexOf('id="contenu"');
    const bloc = page.indexOf('id="bloc-secours"');
    const finContenu = page.indexOf('id="confirmation-secours"');

    assert.ok(bloc > contenu);
    assert.ok(bloc < finContenu);
  });

  test('La confirmation met « Annuler » avant la validation', () => {
    // Le geste sur devant le geste irreversible, comme partout
    // ailleurs dans l'application.
    const page = construirePage();

    assert.ok(
      page.indexOf('id="annuler-secours"') <
        page.indexOf('id="confirmer-secours"'),
    );
  });

  test('La confirmation annonce que le parent sera informé', () => {
    const page = construirePage();

    assert.match(page, /Le parent en sera informé immédiatement/);
  });

  test('Le résultat dit à qui l’accès est destiné', () => {
    // Le cadre est pose par le texte : on ne demandera jamais son
    // diplome a un pompier.
    const page = construirePage();

    assert.match(
      page,
      /destiné aux soignants qui prennent l’enfant en\s+charge/,
    );
  });

  test('Le résultat dit de le faire scanner à chaque personne', () => {
    // Aux urgences, les informations ne se transmettent pas d'un
    // soignant a l'autre : la fiche doit etre remontree a chacun.
    const page = construirePage();

    assert.match(page, /à chaque nouvelle personne/);
  });

  test('Un accès secours n’affiche pas le bouton, mais son bandeau',
    () => {
      // Un acces secours n'en ouvre pas un autre.
      const page = construirePage();

      assert.match(page, /if \(data\.est_acces_secours\)/);
      assert.match(page, /titre-bandeau-secours/);
    });

  test('Le message du serveur est affiché tel quel', () => {
    // Il distingue « le parent n'a pas active » de « ce lien ne le
    // permet pas », et cette difference dit quoi faire.
    const page = construirePage();

    assert.match(page, /erreur && erreur\.message/);
  });

  test('L’adresse est composée avec le jeton rendu par le serveur',
    () => {
      const page = construirePage();

      assert.match(page, /#jeton=' \+ data\.token/);
    });

  test('Les deux adresses sont des paramètres', () => {
    // Servir la page ailleurs ne doit pas demander de la reecrire.
    const page = construirePage(
      'https://ailleurs.test/api',
      'https://ailleurs.test/declencher',
      'https://ailleurs.test',
    );

    assert.match(page, /https:\/\/ailleurs\.test\/declencher/);
    assert.match(page, /https:\/\/ailleurs\.test\/#jeton=/);
  });
});
