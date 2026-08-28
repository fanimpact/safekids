// Page publique d'un lien de partage : le document HTML complet, servi
// tel quel a un accompagnant qui n'a pas l'application installee.
//
// Sortie de l'Edge Function pour vivre ici : la page n'est que du HTML
// et du JavaScript de navigateur, elle ne depend d'aucun hebergeur.
// Sauf un point, et c'est le seul : l'adresse a laquelle le navigateur
// va chercher les donnees. D'ou le parametre `cheminApi`, qui vaut par
// defaut ce que Supabase impose aujourd'hui.
//
// La page est en lecture seule : aucun formulaire, aucune ecriture.
// Elle echappe systematiquement ce qu'elle affiche (voir `echapper`) —
// un prenom, un nom de traitement ou une reaction allergique sont
// saisis par un parent et ne doivent jamais pouvoir devenir du HTML.
//
// **Le jeton passe par le fragment** (`#jeton=...`), jamais par la
// chaine de requete : le fragment n'est pas transmis au serveur, donc
// le jeton n'apparait dans aucun journal d'acces de l'hebergeur. Meme
// choix que pour `auth.kidsrelay.fr`.
//
// **Cette page n'est plus servie par Supabase.** La passerelle des Edge
// Functions reecrit toute reponse HTML en `text/plain`, y ajoute
// `nosniff` et un CSP `sandbox` : le navigateur affichait le code
// source au lieu de la page. Constate le 27/08/2026 en interrogeant
// les deux fonctions — le JSON de `consulter-partage` passe intact, le
// HTML de `voir-partage` est reecrit. La page est donc deposee sur
// `fiche.kidsrelay.fr`, chez OVH, comme la page d'authentification.

/// Adresse par defaut de la fonction qui rend les donnees.
///
/// Absolue, et non un chemin : la page est servie par un autre domaine
/// que la fonction. `consulter-partage` autorise deja toutes les
/// origines.
export const ADRESSE_API_PAR_DEFAUT =
  'https://xcugfdjaifdibwowlrpi.supabase.co/functions/v1/consulter-partage';

export const ADRESSE_DECLENCHEMENT_PAR_DEFAUT =
  'https://xcugfdjaifdibwowlrpi.supabase.co/functions/v1/' +
  'declencher-acces-secours';

/// L'adresse publique de cette page, pour composer le lien de
/// l'acces secours qu'elle vient d'ouvrir.
export const ADRESSE_PAGE_PAR_DEFAUT = 'https://fiche.kidsrelay.fr';

export function construirePage(
  cheminApi: string = ADRESSE_API_PAR_DEFAUT,
  adresseDeclenchement: string = ADRESSE_DECLENCHEMENT_PAR_DEFAUT,
  adressePage: string = ADRESSE_PAGE_PAR_DEFAUT,
  /// La source de `qrcode.js` (Kazuhiko Arase, MIT), inlinée telle
  /// quelle par `web_partage/generer.mjs`.
  ///
  /// Passée en paramètre plutôt qu'importée : cette couche reste
  /// sans dépendance ni accès disque, et la bibliothèque ne vit
  /// qu'à un seul endroit, `web_partage/vendor/qrcode.js`.
  ///
  /// Aucun CDN : la page ne fait aucune requête vers un tiers, et
  /// le QR se calcule hors ligne. Dans un couloir d'école mal
  /// couvert, un code qui dépendrait du réseau serait inutilisable
  /// au moment précis où il sert.
  ///
  /// Vide, la page fonctionne sans QR : l'adresse en clair reste
  /// affichée. C'est le cas de `voir-partage`, dont le HTML est de
  /// toute façon réécrit par la passerelle Supabase.
  bibliothequeQr: string = '',
): string {
  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex, nofollow" />
<title>Informations de l’enfant</title>
<style>
  :root {
    --text: #1a1a1a;
    --muted: #5f6368;
    --border: #e0e0e0;
    --bg: #ffffff;
    --card-bg: #fafafa;
    --emergency-bg: #ffebee;
    --emergency-border: #e57373;
    --emergency-title: #c62828;
    --accent: #1565c0;
  }

  * {
    box-sizing: border-box;
  }

  body {
    margin: 0;
    padding: 0;
    background: var(--bg);
    color: var(--text);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
      Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.5;
  }

  main {
    max-width: 640px;
    margin: 0 auto;
    padding: 24px 20px 60px;
  }

  #estado-chargement,
  #estado-erreur,
  #estado-verrouille {
    text-align: center;
    padding: 60px 20px;
  }

  #estado-erreur,
  #estado-verrouille {
    display: none;
  }

  #estado-erreur h1,
  #estado-verrouille h1 {
    font-size: 22px;
    margin-bottom: 8px;
  }

  #estado-verrouille p {
    color: var(--muted);
  }

  .note-verrouille {
    margin-top: 20px;
    font-size: 14px;
  }

  #estado-erreur p {
    color: var(--muted);
  }

  #contenu {
    display: none;
  }

  h1.nom-enfant {
    font-size: 28px;
    font-weight: 700;
    margin: 0 0 4px;
  }

  .details-identite {
    color: var(--muted);
    font-size: 15px;
    margin-bottom: 24px;
  }

  .section {
    border: 1px solid var(--border);
    background: var(--card-bg);
    border-radius: 12px;
    padding: 16px 18px;
    margin-bottom: 16px;
  }

  .section.highlight {
    background: var(--emergency-bg);
    border-color: var(--emergency-border);
  }

  .section h2 {
    font-size: 17px;
    margin: 0 0 10px;
  }

  .section.highlight h2 {
    color: var(--emergency-title);
  }

  .section ul {
    margin: 0;
    padding-left: 20px;
  }

  .section li {
    margin-bottom: 6px;
  }

  .section li:last-child {
    margin-bottom: 0;
  }

  footer {
    text-align: center;
    color: var(--muted);
    font-size: 13px;
    margin-top: 32px;
  }
  /* --- Accès secours ------------------------------------------- */

  #bandeau-secours,
  #bloc-secours,
  #confirmation-secours,
  #resultat-secours {
    display: none;
  }

  /* Compact, et au-dessus de la fiche sans la repousser hors de
     l'écran : un secouriste en intervention doit voir les
     informations, pas une page d'accueil. */
  #bandeau-secours {
    background: var(--alerte-fond, #fbf1df);
    border: 1px solid var(--alerte-bordure, #e8c98a);
    border-radius: 8px;
    padding: 12px 14px;
    margin-bottom: 20px;
    font-size: 14px;
  }

  #bandeau-secours p {
    margin: 6px 0 0;
  }

  #bloc-secours {
    margin: 28px 0 8px;
  }

  #bouton-secours,
  #confirmer-secours,
  #annuler-secours,
  #reprendre-acces {
    width: 100%;
    padding: 16px 18px;
    font-size: 17px;
    font-family: inherit;
    border-radius: 8px;
    border: 1px solid var(--accent, #1f4a3f);
    background: var(--accent, #1f4a3f);
    color: var(--accent-texte, #ffffff);
    cursor: pointer;
  }

  #annuler-secours,
  .secondaire {
    background: transparent;
    color: var(--texte, #26302c);
    border-color: var(--bordure, #d9d5ce);
  }

  #confirmation-secours,
  #resultat-secours {
    padding: 40px 20px;
  }

  .paire-boutons {
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-top: 28px;
  }

  /* Cadre blanc et marge autour du code : un lecteur a besoin de
     la zone calme, et un fond sombre le rendrait illisible. */
  .qr-secours {
    max-width: 320px;
    margin: 24px auto 0;
    padding: 12px;
    background: #ffffff;
    border: 1px solid var(--bordure, #d9d5ce);
    border-radius: 8px;
  }

  .qr-secours svg {
    display: block;
    width: 100%;
    height: auto;
  }

  #bloc-transmission {
    display: none;
    margin: 28px 0 8px;
    padding-top: 24px;
    border-top: 1px solid var(--bordure, #d9d5ce);
  }

  .adresse-secours {
    margin-top: 24px;
    padding: 14px;
    background: var(--carte, #ffffff);
    border: 1px solid var(--bordure, #d9d5ce);
    border-radius: 8px;
    font-size: 15px;
    word-break: break-all;
  }

</style>
</head>
<body>
<main>
  <div id="estado-chargement">Chargement des informations…</div>

  <div id="estado-erreur">
    <h1 id="titre-erreur"></h1>
    <p id="texte-erreur"></p>
  </div>

  <div id="estado-verrouille">
    <h1>Cette fiche a déjà été ouverte sur un autre appareil</h1>
    <p>
      <strong>Si c’est vous</strong> — par exemple parce que vous
      l’aviez ouverte en scannant un code, et que vous l’ouvrez
      maintenant depuis votre navigateur — reprenez l’accès ici.
    </p>
    <p>
      Le parent en sera informé immédiatement, et pourra couper
      l’accès s’il ne l’avait pas voulu.
    </p>

    <button id="reprendre-acces" type="button">
      C’est moi, reprendre l’accès
    </button>

    <p class="note-verrouille">
      Si ce n’est pas vous, n’appuyez pas.
      <strong>Ce n’est pas la peine de demander qu’on vous le
      renvoie</strong> : un nouveau lien ne changerait rien.
      Rapprochez-vous du parent : il pourra vous donner accès.
    </p>
  </div>

  <div id="contenu">
    <div id="bandeau-secours">
      <strong id="titre-bandeau-secours"></strong>
      <p id="texte-bandeau-secours"></p>
    </div>

    <h1 class="nom-enfant" id="nom-enfant"></h1>
    <div class="details-identite" id="details-identite"></div>
    <div id="sections"></div>

    <div id="bloc-secours">
      <button id="bouton-secours" type="button">
        L’enfant part avec les secours
      </button>
    </div>

    <div id="bloc-transmission">
      <strong>Vous passez le relais ?</strong>
      <p>
        Faites scanner ce code à la personne qui prend l’enfant en
        charge après vous. Elle gardera la fiche sur son propre
        téléphone et pourra la rouvrir sans vous.
      </p>
      <div class="qr-secours" id="qr-transmission"></div>
      <p class="adresse-secours" id="adresse-transmission"></p>
    </div>

    <footer>Fiche en lecture seule — générée par KidsRelay.</footer>
  </div>

  <div id="confirmation-secours">
    <h1>L’enfant part avec les secours ?</h1>
    <p>
      Vous allez pouvoir montrer ces informations aux soignants qui le
      prennent en charge, et les transmettre à la personne qui
      l’accompagne.
    </p>
    <p><strong>Le parent en sera informé immédiatement.</strong></p>

    <div class="paire-boutons">
      <button id="annuler-secours" type="button" class="secondaire">
        Annuler
      </button>
      <button id="confirmer-secours" type="button">
        Oui, l’enfant part avec les secours
      </button>
    </div>
  </div>

  <div id="resultat-secours">
    <h1>Accès secours ouvert</h1>
    <p>
      Cet accès donne <strong>les informations pour les secours, et
      rien d’autre</strong>. Il prend fin
      <strong id="fin-acces-secours"></strong>.
    </p>
    <p>
      <strong>Il est destiné aux soignants qui prennent l’enfant en
      charge, et à la personne qui l’accompagne.</strong>
    </p>
    <p>
      Faites-le scanner à chaque nouvelle personne qui s’occupe de
      l’enfant : chacune gardera la fiche sur son propre téléphone et
      pourra la rouvrir sans vous.
    </p>
    <div class="qr-secours" id="qr-secours"></div>
    <p class="adresse-secours" id="adresse-secours"></p>
  </div>
</main>

<script>
${bibliothequeQr}
</script>

<script>
(function () {
  function echapper(valeur) {
    return String(valeur == null ? '' : valeur)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function formaterDate(iso) {
    if (!iso) return null;
    var d = new Date(iso);
    if (isNaN(d.getTime())) return null;
    var jour = String(d.getDate()).padStart(2, '0');
    var mois = String(d.getMonth() + 1).padStart(2, '0');
    return jour + '/' + mois + '/' + d.getFullYear();
  }

  function calculerAge(dateNaissance) {
    if (!dateNaissance) return null;
    var naissance = new Date(dateNaissance);
    if (isNaN(naissance.getTime())) return null;
    var maintenant = new Date();
    var age = maintenant.getFullYear() - naissance.getFullYear();
    var m = maintenant.getMonth() - naissance.getMonth();
    if (m < 0 || (m === 0 && maintenant.getDate() < naissance.getDate())) {
      age--;
    }
    return age;
  }

  function texteIdentite(enfant) {
    var parts = [];
    var age = calculerAge(enfant.date_naissance);
    if (age !== null) parts.push(age + ' ans');
    if (enfant.poids != null) parts.push(enfant.poids + ' kg');
    if (enfant.taille != null) parts.push(enfant.taille + ' cm');
    if (enfant.poids != null || enfant.taille != null) {
      var dateMaj = formaterDate(enfant.date_maj_poids);
      parts.push(dateMaj ? 'mesurés le ' + dateMaj : 'date de mesure non renseignée');
    }
    return parts.join(' · ');
  }

  // Les noms de champs ci-dessous correspondent aux champs du modèle
  // Flutter (ex. medicationName, deviceName...). A ajuster si la
  // structure des jsonb change lors de la migration des données.

  // "mention" rappelle le cadre d'administration à côté du traitement
  // (jamais un avertissement) : selon le PAI pour une structure
  // d'accueil, selon les indications du parent pour un particulier —
  // choisi par le parent à la création du lien (champ destinataire).
  function ligneTraitement(t, mention) {
    if (!t || !t.medicationName) return null;
    var d = [t.dosage, t.administrationTimes].filter(Boolean);
    if (mention) d.push(mention);
    d = d.join(' — ');
    return echapper(d ? t.medicationName + ' — ' + d : t.medicationName);
  }

  function ligneDispositif(d) {
    if (!d || !d.deviceName) return null;
    return echapper(d.mainUse ? d.deviceName + ' — ' + d.mainUse : d.deviceName);
  }

  function lignePathologie(p) {
    if (!p || !p.name) return null;
    return echapper(
      p.approximateDiagnosisDate
        ? p.name + ' (diagnostiquée : ' + p.approximateDiagnosisDate + ')'
        : p.name
    );
  }

  function ligneAllergie(a) {
    if (!a || !a.allergen) return null;
    return echapper(
      a.observedReaction ? a.allergen + ' — réaction : ' + a.observedReaction : a.allergen
    );
  }

  function ligneContact(c) {
    if (!c || !c.fullName) return null;
    var d = [c.relationship, c.phoneNumber].filter(Boolean).join(' — ');
    return echapper(d ? c.fullName + ' — ' + d : c.fullName);
  }

  // Rendu simplifié des facteurs déclenchants : une ligne par facteur
  // renseigné, sans reprendre toute la logique de priorité de l'app.
  var LABELS_FACTEURS = {
    flashingLights: 'Photosensibilité (lumières clignotantes)',
    heat: 'Chaleur',
    fatigueOrLackOfSleep: 'Fatigue ou manque de sommeil',
    stressOrStrongEmotions: 'Stress ou émotions fortes',
    physicalEffort: 'Effort physique',
    noise: 'Bruit',
    crowd: 'Foule',
    confinedSpaces: 'Espaces confinés',
  };

  function lignesFacteursDeclenchants(f) {
    if (!f || !f.hasTriggerFactors) return [];
    var lignes = [];
    Object.keys(LABELS_FACTEURS).forEach(function (cle) {
      if (f[cle] === true) lignes.push(echapper(LABELS_FACTEURS[cle]));
    });
    if (f.waterContact) lignes.push('Eau : vigilance particulière');
    if (f.animals) lignes.push('Animaux : vigilance particulière');
    if (f.height) lignes.push('Hauteur : vigilance particulière');
    if (f.other) lignes.push(echapper('Autre : ' + f.other));
    return lignes;
  }

  function section(titre, lignes, opts) {
    opts = opts || {};
    if (!lignes || lignes.length === 0) return '';
    var classe = opts.highlight ? 'section highlight' : 'section';
    return (
      '<div class="' + classe + '"><h2>' + echapper(titre) + '</h2><ul>' +
      lignes.map(function (l) { return '<li>' + l + '</li>'; }).join('') +
      '</ul></div>'
    );
  }

  // Consignes d'urgence numérotées, rédigées par le parent pour une
  // pathologie ou une allergie précise. Corrigé (19/08/2026) : jusqu'ici
  // visibles uniquement dans le Mode Urgence interactif de l'app, jamais
  // sur ce lien -- exactement ce que consulte quelqu'un sans l'app sous
  // la main. Affiché uniquement sur la fiche secours.
  function sectionConsignesUrgence(profilSante) {
    var entrees = [];

    (profilSante.pathologies || []).forEach(function (p) {
      var etapes = (p && p.emergencyInstructionSteps || [])
        .map(function (e) { return String(e || '').trim(); })
        .filter(Boolean);
      if (p && p.name && etapes.length) {
        entrees.push({ label: p.name, etapes: etapes });
      }
    });

    (profilSante.allergies || []).forEach(function (a) {
      var etapes = (a && a.emergencyInstructionSteps || [])
        .map(function (e) { return String(e || '').trim(); })
        .filter(Boolean);
      if (a && a.allergen && etapes.length) {
        entrees.push({ label: a.allergen, etapes: etapes });
      }
    });

    if (!entrees.length) return '';

    var corps = entrees.map(function (entree) {
      var items = entree.etapes.map(function (etape, index) {
        return '<li>' + (index + 1) + '. ' + echapper(etape) + '</li>';
      }).join('');
      return '<p style="font-weight:700;margin:12px 0 4px">' +
        echapper(entree.label) + '</p><ul>' + items + '</ul>';
    }).join('');

    return (
      '<div class="section highlight"><h2>Consignes d’urgence</h2>' +
      corps + '</div>'
    );
  }

  function lignesListe(items, formateur) {
    return (items || []).map(formateur).filter(Boolean);
  }

  // "recommandations_activite" : photo figée au moment du partage
  // (voir contenu_fige), rendue telle quelle -- jamais recalculée ici.
  function afficherRecommandationsActivite(data) {
    var contenu = data.contenu_fige || {};
    var blocs = [];

    var infosActivite = [contenu.activite_nom, formaterDate(contenu.activite_date), contenu.activite_lieu]
      .filter(Boolean)
      .map(echapper)
      .join(' · ');

    if (infosActivite) {
      blocs.push('<div class="section"><h2>Activité</h2><p>' + infosActivite + '</p></div>');
    }

    (contenu.sections || []).forEach(function (bloc) {
      var lignes = (bloc.lignes || []).map(echapper);
      blocs.push(section(bloc.titre, lignes));
    });

    document.getElementById('sections').innerHTML = blocs.join('');
    document.getElementById('estado-chargement').style.display = 'none';
    document.getElementById('contenu').style.display = 'block';

    preparerAccesSecours(data);
  }

  // --- Accès secours ---------------------------------------------
  //
  // Trois écrans : le bouton en bas de la fiche, la confirmation, et
  // le résultat. Le bouton est en bas de la fiche elle-meme, visible
  // sans menu : tout le dispositif repose sur un geste a faire en dix
  // secondes sous stress.

  function afficherEcran(id) {
    var ecrans = [
      'contenu',
      'confirmation-secours',
      'resultat-secours',
    ];

    for (var i = 0; i < ecrans.length; i++) {
      var bloc = document.getElementById(ecrans[i]);

      if (bloc) {
        bloc.style.display = ecrans[i] === id ? 'block' : 'none';
      }
    }
  }

  // Le code a scanner. Niveau de correction M : pour notre adresse de
  // 82 caracteres, il donne exactement la meme grille que L (37x37)
  // tout en tolerant deux fois plus de reflets et de traces de doigts.
  // Q et H la densifieraient (45x45 et 49x49), ce qui nuit plus qu'il
  // n'aide sur un ecran tenu a bout de bras.
  function dessinerQr(idConteneur, adresse) {
    var conteneur = document.getElementById(idConteneur);

    if (!conteneur) {
      return false;
    }

    conteneur.innerHTML = '';

    // Sans la bibliotheque, l'adresse en clair reste affichee : elle
    // est le repli, pas un pis-aller.
    if (typeof qrcode !== 'function') {
      conteneur.style.display = 'none';
      return false;
    }

    try {
      var qr = qrcode(0, 'M');

      qr.addData(adresse);
      qr.make();

      conteneur.innerHTML = qr.createSvgTag({
        cellSize: 8,
        margin: 4,
        scalable: true,
        title: 'Code a scanner pour ouvrir la fiche secours',
      });

      conteneur.style.display = 'block';
      return true;
    } catch (e) {
      conteneur.style.display = 'none';
      return false;
    }
  }

  function adresseDeLaFiche(jeton) {
    return '${adressePage}/#jeton=' + jeton;
  }

  // On retient l'acces ouvert depuis CE navigateur, pour que la
  // personne qui ferme l'ecran ou dont le telephone se verrouille
  // retrouve son code sans rien redemander au serveur.
  //
  // Volontairement sans verification au reaffichage : la validite se
  // controle au scan, par le serveur, seul endroit qui la connaisse.
  // Un aller-retour reseau ici echouerait dans un couloir mal couvert,
  // au moment precis ou le code sert.
  // Une fonction et non une variable : le jeton est lu plus bas dans
  // le script, et une constante calculee ici vaudrait undefined.
  function cleAccesOuvert() {
    return 'kidsrelay_secours_' + token;
  }

  function memoriserAcces(jeton, expireLe) {
    try {
      window.localStorage.setItem(
        cleAccesOuvert(),
        JSON.stringify({ jeton: jeton, expire: expireLe }),
      );
    } catch (e) {
      // Sans stockage, le bouton restera celui du declenchement — qui
      // retrouve l'acces existant cote serveur. Rien n'est perdu.
    }
  }

  function accesMemorise() {
    try {
      var brut = window.localStorage.getItem(cleAccesOuvert());

      if (!brut) {
        return null;
      }

      var garde = JSON.parse(brut);

      if (!garde || !garde.jeton) {
        return null;
      }

      if (garde.expire && new Date(garde.expire) < new Date()) {
        window.localStorage.removeItem(cleAccesOuvert());
        return null;
      }

      return garde;
    } catch (e) {
      return null;
    }
  }

  function montrerResultat(jeton, expireLe) {
    document.getElementById('fin-acces-secours').textContent =
      quandFinit(expireLe);

    var adresse = adresseDeLaFiche(jeton);

    dessinerQr('qr-secours', adresse);

    // L'adresse en clair sous le code : tout le monde ne sait pas
    // scanner, et c'est le repli quand le QR ne prend pas.
    document.getElementById('adresse-secours').textContent = adresse;

    afficherEcran('resultat-secours');
  }

  function preparerAccesSecours(data) {
    // La fiche EST un acces secours : bandeau d'explication, et pas de
    // bouton — un acces secours n'en ouvre pas un autre.
    if (data.est_acces_secours) {
      var bandeau = document.getElementById('bandeau-secours');
      var titre = document.getElementById('titre-bandeau-secours');
      var texte = document.getElementById('texte-bandeau-secours');

      var prenom = (data.enfant && data.enfant.prenom) || 'l’enfant';

      titre.textContent = 'Accès secours — ' + prenom;

      texte.textContent =
        'Ces informations vous sont transmises parce que l’enfant est ' +
        'pris en charge par les secours. Elles ne contiennent que les ' +
        'informations pour les secours. Cet accès prend fin ' +
        quandFinit(data.expire_le) +
        '. Le parent en a été informé.';

      bandeau.style.display = 'block';

      // Le relais. Sans ce code, chaque nouveau soignant devrait
      // rappeler la personne restee a l'ecole — ce qui ne se
      // produira pas dans la realite (decision du 28/08/2026).
      var adressePropre = adresseDeLaFiche(token);

      dessinerQr('qr-transmission', adressePropre);

      document.getElementById('adresse-transmission').textContent =
        adressePropre;

      document.getElementById('bloc-transmission').style.display =
        'block';

      return;
    }

    if (!data.acces_secours_disponible) {
      return;
    }

    document.getElementById('bloc-secours').style.display = 'block';

    var deja = accesMemorise();
    var bouton = document.getElementById('bouton-secours');

    // Un acces est deja ouvert depuis cet appareil : le bouton doit
    // le dire. « L'enfant part avec les secours » une seconde fois
    // ferait croire qu'on en ouvre un autre — alors que le serveur
    // rendrait le meme.
    if (deja) {
      bouton.textContent = 'Revoir le code de l’accès secours';

      bouton.onclick = function () {
        montrerResultat(deja.jeton, deja.expire);
      };
    } else {
      bouton.onclick = function () {
        afficherEcran('confirmation-secours');
      };
    }

    document.getElementById('annuler-secours').onclick = function () {
      afficherEcran('contenu');
    };

    document.getElementById('confirmer-secours').onclick = function () {
      declencherSecours();
    };
  }

  function quandFinit(iso) {
    if (!iso) {
      return 'plus tard';
    }

    var fin = new Date(iso);

    if (isNaN(fin.getTime())) {
      return 'plus tard';
    }

    var heures = ('0' + fin.getHours()).slice(-2);
    var minutes = ('0' + fin.getMinutes()).slice(-2);
    var jour = ('0' + fin.getDate()).slice(-2);
    var mois = ('0' + (fin.getMonth() + 1)).slice(-2);

    return 'le ' + jour + '/' + mois + ' à ' + heures + 'h' + minutes;
  }

  function declencherSecours() {
    var bouton = document.getElementById('confirmer-secours');

    bouton.disabled = true;
    bouton.textContent = 'Ouverture…';

    var url = '${adresseDeclenchement}?token=' + encodeURIComponent(token);

    if (secret) {
      url += '&secret=' + encodeURIComponent(secret);
    }

    fetch(url, { method: 'POST' })
      .then(function (reponse) {
        return reponse.json().then(function (data) {
          if (!reponse.ok) {
            throw new Error(data.error || 'Refusé');
          }

          return data;
        });
      })
      .then(function (data) {
        memoriserAcces(data.token, data.expire_le);
        montrerResultat(data.token, data.expire_le);
      })
      .catch(function (erreur) {
        bouton.disabled = false;
        bouton.textContent = 'Oui, l’enfant part avec les secours';

        // Le message du serveur, tel quel : il distingue « le parent
        // n'a pas activé » de « ce lien ne le permet pas », et cette
        // différence compte pour savoir quoi faire.
        alerterSecours(
          (erreur && erreur.message) ||
            'L’accès secours n’a pas pu être ouvert.',
        );
      });
  }

  function alerterSecours(message) {
    var bloc = document.getElementById('confirmation-secours');
    var deja = document.getElementById('erreur-secours');

    if (deja) {
      deja.textContent = message;
      return;
    }

    var p = document.createElement('p');

    p.id = 'erreur-secours';
    p.textContent = message;
    bloc.appendChild(p);
  }

  function afficherFiche(data) {
    var enfant = data.enfant || {};

    document.getElementById('nom-enfant').textContent =
      [enfant.prenom, enfant.nom].filter(Boolean).join(' ') || 'Enfant';
    document.getElementById('details-identite').textContent = texteIdentite(enfant);

    if (data.type_fiche === 'recommandations_activite') {
      afficherRecommandationsActivite(data);
      return;
    }

    var profilSante = data.profil_sante || {};

    var mentionTraitement =
      data.destinataire === 'structure_accueil'
        ? 'posologie et administration selon le PAI'
        : 'posologie et administration selon les indications du parent';

    function ligneTraitementAvecMention(t) {
      return ligneTraitement(t, mentionTraitement);
    }

    var blocs = [];

    if (data.type_fiche === 'secours') {
      blocs.push(sectionConsignesUrgence(profilSante));
    }

    blocs.push(section('Pathologies', lignesListe(profilSante.pathologies, lignePathologie)));
    blocs.push(section('Allergies', lignesListe(profilSante.allergies, ligneAllergie)));

    if (data.type_fiche === 'ce_qu_il_faut_savoir') {
      blocs.push(
        section(
          'Facteurs déclenchants et sensibilités',
          lignesFacteursDeclenchants(profilSante.facteurs_declenchants)
        )
      );
    }

    blocs.push(
      section(
        'Traitements d’urgence',
        lignesListe(profilSante.traitements_urgence, ligneTraitementAvecMention),
        { highlight: true }
      )
    );
    blocs.push(section('Traitements réguliers', lignesListe(profilSante.traitements_reguliers, ligneTraitementAvecMention)));
    blocs.push(section('Dispositifs médicaux', lignesListe(profilSante.dispositifs_medicaux, ligneDispositif)));

    if (data.type_fiche === 'secours') {
      var medecin = profilSante.medecin_traitant;
      if (medecin && medecin.name) {
        blocs.push(
          section('Médecin traitant', [
            echapper([medecin.name, medecin.workplace, medecin.phoneNumber].filter(Boolean).join(' — ')),
          ])
        );
      }
      blocs.push(
        section(
          'Facteurs déclenchants et sensibilités',
          lignesFacteursDeclenchants(profilSante.facteurs_declenchants)
        )
      );
    }

    blocs.push(section('Contacts à prévenir', lignesListe(profilSante.contacts_urgence, ligneContact)));

    document.getElementById('sections').innerHTML = blocs.join('');
    document.getElementById('estado-chargement').style.display = 'none';
    document.getElementById('contenu').style.display = 'block';

    // Sans cette ligne, ni le bouton ni le bandeau n'apparaissaient
    // sur une fiche secours : l'appel n'existait que dans le rendu
    // des recommandations d'activite, seul type de fiche ou un acces
    // secours n'a aucun sens. Trouve le 28/08/2026 en exercant la
    // page pour de vrai, apres trois assertions de lecture de source
    // qui ne voyaient que le texte du script.
    preparerAccesSecours(data);
  }

  function afficherVerrouille() {
    document.getElementById('estado-chargement').style.display = 'none';
    document.getElementById('estado-verrouille').style.display = 'block';
  }

  // Quatre situations, quatre messages. La page les confondait toutes
  // sous « Ce lien a expire ou n'est plus valide » : le professionnel
  // refuse par le verrou reclamait alors un nouveau lien, ce qui ne
  // pouvait rien resoudre.
  var MESSAGES = {
    adresse: [
      'Il manque quelque chose dans cette adresse',
      'Ouvrez le lien complet, tel qu’il vous a été envoyé. Si vous ' +
        'l’avez retrouvé dans l’historique de votre navigateur ou ' +
        'dans vos favoris, il est probablement incomplet — revenez ' +
        'au message d’origine.',
    ],
    // Expire et revoque partagent le meme texte : rien ne doit
    // laisser deviner que le parent a coupe l'acces. Les deux causes
    // sont nommees sans que l'on dise laquelle.
    fini: [
      'Ce lien ne fonctionne plus',
      'Il a atteint sa date de fin, ou le parent y a mis un terme. ' +
        'Demandez-lui un nouveau lien si vous en avez encore besoin.',
    ],
    // Un code a scanner perime ne se dit pas comme un lien fini :
    // le parent est a cote de la personne, il lui suffit d'en
    // afficher un nouveau. « Demandez-lui un nouveau lien »
    // l'enverrait chercher un SMS qui n'existe pas.
    code: [
      'Ce code n’est plus valable',
      'Un code à scanner vaut cinq minutes. Demandez au parent, ' +
        'qui est à côté de vous, d’en afficher un nouveau.',
    ],
    panne: [
      'Impossible d’afficher cette fiche',
      'Vérifiez votre connexion et réessayez. Si le problème ' +
        'persiste, prévenez la personne qui vous a envoyé ce lien.',
    ],
  };

  function afficherErreur(cas) {
    var message = MESSAGES[cas] || MESSAGES.panne;

    document.getElementById('estado-chargement').style.display = 'none';
    document.getElementById('titre-erreur').textContent = message[0];
    document.getElementById('texte-erreur').textContent = message[1];
    document.getElementById('estado-erreur').style.display = 'block';
  }

  // Le fragment, jamais la chaine de requete : il n'est pas transmis
  // au serveur qui sert cette page.
  var token = new URLSearchParams(
    window.location.hash.replace(/^#/, '')
  ).get('jeton');

  if (!token) {
    afficherErreur('adresse');
    return;
  }

  // Le secret que cet appareil a recu a sa premiere ouverture. Ce
  // n'est pas une empreinte : c'est une valeur que le serveur a
  // fabriquee et deposee ici, sans signification et sans rapport avec
  // l'appareil. Rien n'est lu sur le navigateur.
  //
  // Range par token : deux liens differents ne se marchent pas dessus.
  var cleSecret = 'kidsrelay_partage_' + token;
  var secret = null;

  try {
    secret = window.localStorage.getItem(cleSecret);
  } catch (e) {
    // Stockage refuse (navigation privee stricte, cookies bloques) :
    // on ouvre sans secret. Le serveur decidera.
    secret = null;
  }

  // Rejouable : la reprise refait exactement la meme demande, avec
  // un drapeau en plus. Une seule chaine de traitement pour les deux
  // cas, donc un seul endroit ou elle peut se tromper.
  function ouvrirFiche(reprise) {
    var urlFonction =
      '${cheminApi}?token=' + encodeURIComponent(token);

    if (secret) {
      urlFonction += '&secret=' + encodeURIComponent(secret);
    }

    if (reprise) {
      urlFonction += '&reprise=1';
    }

    return fetch(urlFonction)
    .then(function (reponse) {
      // 423 : le lien est pris par un autre appareil.
      if (reponse.status === 423) {
        throw { cas: 'verrou' };
      }

      // 404 et 410 : jeton inconnu, lien expire ou revoque. Le
      // serveur ne les distingue pas non plus dans sa reponse.
      //
      // Sauf un : un code a scanner perime porte un marqueur, et
      // merite son propre message. On lit donc le corps avant de
      // conclure — et s'il n'est pas lisible, on retombe sur le
      // cas general plutot que sur une panne.
      if (reponse.status === 404 || reponse.status === 410) {
        return reponse.json().then(
          function (data) {
            throw {
              cas:
                data && data.code === 'code_expire'
                  ? 'code'
                  : 'fini',
            };
          },
          function () {
            throw { cas: 'fini' };
          },
        );
      }

      if (!reponse.ok) throw { cas: 'panne' };

      return reponse.json();
    })
    .then(function (data) {
      if (data.error) throw { cas: 'fini' };

      if (data.secret) {
        try {
          window.localStorage.setItem(cleSecret, data.secret);
        } catch (e) {
          // Sans stockage, la prochaine ouverture repartira sans
          // secret. Rien a faire de plus : la fiche s'affiche.
        }
      }

      afficherFiche(data);
    })
      .catch(function (erreur) {
        if (erreur && erreur.cas === 'verrou') {
          afficherVerrouille();
          return;
        }

        // Sans cas connu, l'echec vient du reseau : la requete a
        // echoue avant d'avoir vu une reponse. Ce n'est pas un lien
        // mort, et le dire serait faux.
        afficherErreur(erreur && erreur.cas);
      });
  }

  var boutonReprise = document.getElementById('reprendre-acces');

  if (boutonReprise) {
    boutonReprise.onclick = function () {
      boutonReprise.disabled = true;
      boutonReprise.textContent = 'Reprise…';

      document.getElementById('estado-verrouille').style.display =
        'none';
      document.getElementById('estado-chargement').style.display =
        'block';

      ouvrirFiche(true).then(function () {
        // Rendu utilisable quoi qu'il arrive : si la reprise a
        // echoue, l'ecran de refus revient et le bouton doit
        // pouvoir servir encore.
        boutonReprise.disabled = false;
        boutonReprise.textContent = 'C’est moi, reprendre l’accès';
      });
    };
  }

  ouvrirFiche(false);
})();
</script>
</body>
</html>
`;
}
