import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// La vraie bibliotheque, celle qui sera inlinee dans la page.
// Les tests du QR l'executent telle quelle : ce qui est verifie est
// exactement ce qui sera servi.
const BIBLIOTHEQUE_QR = readFileSync(
  join(
    dirname(fileURLToPath(import.meta.url)),
    '..',
    '..',
    '..',
    'web_partage',
    'vendor',
    'qrcode.js',
  ),
  'utf8',
);

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
    'qr-secours': element(),
    'bloc-transmission': element(),
    'qr-transmission': element(),
    'adresse-transmission': element(),
    'nom-enfant': element(),
    'details-identite': element(),
    sections: element(),
  };

  const appelsFetch = [];
  const stockage = { ...(options.stockage ?? {}) };

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
        getItem(cle) {
          return Object.prototype.hasOwnProperty.call(stockage, cle)
            ? stockage[cle]
            : null;
        },
        setItem(cle, valeur) {
          stockage[cle] = String(valeur);
        },
        removeItem(cle) {
          delete stockage[cle];
        },
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

      // Le declenchement de l'acces secours ne rend pas une fiche
      // mais le jeton du nouvel acces : deux reponses differentes,
      // sur deux adresses differentes.
      const estDeclenchement = String(url).includes('declencher');

      const corps = estDeclenchement
        ? (options.reponseDeclenchement ?? { error: 'Refusé' })
        : (fiche ?? { error: 'Lien expiré ou invalide.' });

      return Promise.resolve({
        ok: estDeclenchement ? !corps.error : reponseOk,
        status: statut,
        json: () => Promise.resolve(corps),
      });
    },
  };

  // La page porte deux scripts depuis le QR : la bibliotheque, puis
  // le script de la page. On prend le dernier — celui qu'on teste.
  const page = construirePage(
    options.cheminApi,
    undefined,
    undefined,
    options.avecQr ? BIBLIOTHEQUE_QR : '',
  );

  const script = page.slice(
    page.lastIndexOf('<script>') + '<script>'.length,
    page.lastIndexOf('</script>'),
  );

  // Le meme contexte pour les deux, comme dans un navigateur : le
  // script de la page doit voir le `qrcode` global du premier.
  const contexte = vm.createContext(bacASable);

  if (options.avecQr) {
    vm.runInContext(BIBLIOTHEQUE_QR, contexte);
  }

  vm.runInContext(script, contexte);

  // Laisse la chaîne de promesses du script se dérouler.
  await new Promise((resoudre) => setImmediate(resoudre));

  return { elements, appelsFetch, stockage };
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

      assert.match(page, /#jeton=' \+ jeton/);
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

// Le QR de l'accès secours (28/08/2026).
//
// Ce que ces tests protègent tient en une phrase : le code doit se
// calculer sur le téléphone, sans réseau et sans tiers. Un QR qui
// dépendrait d'un CDN serait inutilisable dans un couloir d'école mal
// couvert — au moment précis où il sert.
describe('Le QR de l’accès secours', () => {
  const FICHE_SECOURS_OUVERT = ficheSecours(
    {},
    {
      est_acces_secours: true,
      expire_le: '2026-08-24T12:00:00.000Z',
    },
  );

  const FICHE_AVEC_BOUTON = ficheSecours(
    {},
    { acces_secours_disponible: true },
  );

  test('Aucun CDN, aucune requête vers un tiers', () => {
    // La règle de la page publique, qui ne bouge pas : rien n'est
    // chargé depuis l'extérieur.
    const page = construirePage(undefined, undefined, undefined, 'FAUX');

    assert.ok(!page.includes('<script src='));
    assert.ok(!page.includes('cdn'));
    assert.ok(page.includes('FAUX'));
  });

  test('Sans la bibliothèque, la page reste servable', () => {
    // `voir-partage` la construit sans QR : son HTML est de toute
    // façon réécrit par la passerelle Supabase.
    const page = construirePage();

    assert.ok(page.includes('id="qr-secours"'));
    assert.ok(page.includes('typeof qrcode !== '));
  });

  test('Le code est calculé sur place, jamais demandé au serveur',
    async () => {
      const { elements, appelsFetch } = await rendre(FICHE_SECOURS_OUVERT, {
        avecQr: true,
      });

      assert.ok(elements['qr-transmission'].innerHTML.includes('<svg'));

      // Un seul appel : celui qui a servi la fiche.
      assert.equal(appelsFetch.length, 1);
    });

  test('La fiche du soignant porte le code, pour passer le relais',
    async () => {
      // Décision du 28/08/2026 : sans lui, chaque nouveau soignant
      // devrait rappeler la personne restée à l'école.
      const { elements } = await rendre(FICHE_SECOURS_OUVERT, {
        avecQr: true,
      });

      assert.equal(elements['bloc-transmission'].style.display, 'block');

      assert.equal(
        elements['adresse-transmission'].textContent,
        'https://fiche.kidsrelay.fr/#jeton=token-1',
      );
    });

  test('L’adresse en clair reste sous le code', async () => {
    // Tout le monde ne sait pas scanner, et c'est le repli quand le
    // QR ne prend pas.
    const page = construirePage();

    assert.ok(
      page.indexOf('id="qr-secours"') <
        page.indexOf('id="adresse-secours"'),
    );

    assert.ok(
      page.indexOf('id="qr-transmission"') <
        page.indexOf('id="adresse-transmission"'),
    );
  });

  test('Sans la bibliothèque, l’adresse s’affiche quand même',
    async () => {
      const { elements } = await rendre(FICHE_SECOURS_OUVERT);

      assert.equal(elements['qr-transmission'].innerHTML, '');

      assert.equal(
        elements['adresse-transmission'].textContent,
        'https://fiche.kidsrelay.fr/#jeton=token-1',
      );
    });

  test('Niveau de correction M', () => {
    // Pour notre adresse de 82 caractères, M donne exactement la même
    // grille que L (37x37) en tolérant deux fois plus de reflets. Q et
    // H la densifieraient (45x45 et 49x49), ce qui nuit plus qu'il
    // n'aide sur un écran tenu à bout de bras.
    const page = construirePage();

    assert.match(page, /qrcode\(0, 'M'\)/);
  });

  test('Un accès déjà ouvert se réaffiche sans rien redemander',
    async () => {
      // Quelqu'un qui ferme l'écran ou dont le téléphone se verrouille
      // doit retrouver son code. La validité se contrôle au scan, par
      // le serveur : un aller-retour ici échouerait hors couverture.
      const { elements, appelsFetch } = await rendre(FICHE_AVEC_BOUTON, {
        avecQr: true,
        stockage: {
          'kidsrelay_secours_token-1': JSON.stringify({
            jeton: 'jeton-secours',
            expire: '2026-08-24T12:00:00.000Z',
          }),
        },
      });

      assert.equal(
        elements['bouton-secours'].textContent,
        'Revoir le code de l’accès secours',
      );

      elements['bouton-secours'].onclick();

      assert.equal(
        elements['adresse-secours'].textContent,
        'https://fiche.kidsrelay.fr/#jeton=jeton-secours',
      );

      assert.ok(elements['qr-secours'].innerHTML.includes('<svg'));

      // Toujours un seul appel : celui de la fiche.
      assert.equal(appelsFetch.length, 1);
    });

  test('Un accès mémorisé mais expiré ne se propose plus', async () => {
    const { elements } = await rendre(FICHE_AVEC_BOUTON, {
      stockage: {
        'kidsrelay_secours_token-1': JSON.stringify({
          jeton: 'vieux-jeton',
          expire: '2026-08-22T12:00:00.000Z',
        }),
      },
    });

    // Le libelle n'a pas ete remplace, et le bouton mene toujours a
    // la confirmation : rien ne laisse croire qu'un acces est ouvert.
    assert.equal(elements['bouton-secours'].textContent, '');

    elements['bouton-secours'].onclick();

    assert.equal(
      elements['confirmation-secours'].style.display,
      'block',
    );
  });

  test('Le déclenchement mémorise l’accès pour le réafficher',
    async () => {
      const { elements, stockage } = await rendre(FICHE_AVEC_BOUTON, {
        avecQr: true,
        reponseDeclenchement: {
          token: 'jeton-neuf',
          expire_le: '2026-08-24T12:00:00.000Z',
        },
      });

      elements['confirmer-secours'].onclick();

      await new Promise((resoudre) => setImmediate(resoudre));

      assert.ok(stockage['kidsrelay_secours_token-1']);

      assert.match(
        stockage['kidsrelay_secours_token-1'],
        /jeton-neuf/,
      );
    });
});

// Le défaut du 28/08/2026, et son garde-fou.
//
// `preparerAccesSecours` n'était appelé que depuis le rendu des
// recommandations d'activité — le seul type de fiche où un accès
// secours n'a aucun sens. Sur une fiche secours, ni le bouton ni le
// bandeau n'apparaissaient donc jamais.
//
// Trois assertions de lecture de source le disaient présent : elles
// voyaient le texte du script, pas son exécution. Ces deux-ci
// exercent la page.
describe('Le geste secours atteint bien la fiche secours', () => {
  test('Le bouton apparaît sur une fiche secours', async () => {
    const { elements } = await rendre(
      ficheSecours({}, { acces_secours_disponible: true }),
    );

    assert.equal(elements['bloc-secours'].style.display, 'block');
  });

  test('Le bandeau apparaît sur un accès secours', async () => {
    const { elements } = await rendre(
      ficheSecours({}, {
        est_acces_secours: true,
        expire_le: '2026-08-24T12:00:00.000Z',
      }),
    );

    assert.equal(elements['bandeau-secours'].style.display, 'block');

    assert.match(
      elements['titre-bandeau-secours'].textContent,
      /Accès secours/,
    );
  });
});
