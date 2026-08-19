// Edge Function "voir-partage"
//
// Sert une page HTML lisible pour un lien de partage, destinée à un
// accompagnant qui n'a pas l'app SafeKids installée. Le token est lu
// dans l'URL côté navigateur (JavaScript embarqué), qui appelle
// ensuite "consulter-partage" pour récupérer les données et affiche
// une fiche mise en forme. Page en lecture seule : aucun formulaire,
// aucune écriture.
//
// Déploiement (comme consulter-partage, sans vérification JWT
// puisque l'accompagnant n'est pas authentifié) :
//   supabase functions deploy voir-partage --no-verify-jwt
//
// Lien à partager : <url-projet>/functions/v1/voir-partage?token=...

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const PAGE_HTML = `<!doctype html>
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
  #estado-erreur {
    text-align: center;
    padding: 60px 20px;
  }

  #estado-erreur {
    display: none;
  }

  #estado-erreur h1 {
    font-size: 22px;
    margin-bottom: 8px;
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
</style>
</head>
<body>
<main>
  <div id="estado-chargement">Chargement des informations…</div>

  <div id="estado-erreur">
    <h1>Ce lien a expiré ou n’est plus valide.</h1>
    <p>Demandez un nouveau lien à la personne qui vous l’a envoyé.</p>
  </div>

  <div id="contenu">
    <h1 class="nom-enfant" id="nom-enfant"></h1>
    <div class="details-identite" id="details-identite"></div>
    <div id="sections"></div>
    <footer>Fiche en lecture seule — générée par SafeKids.</footer>
  </div>
</main>

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

  function ligneTraitement(t) {
    if (!t || !t.medicationName) return null;
    var d = [t.dosage, t.administrationTimes].filter(Boolean).join(' — ');
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
    var profilActivites = data.profil_activites || {};

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
        lignesListe(profilSante.traitements_urgence, ligneTraitement),
        { highlight: true }
      )
    );
    blocs.push(section('Traitements réguliers', lignesListe(profilSante.traitements_reguliers, ligneTraitement)));
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
  }

  function afficherErreur() {
    document.getElementById('estado-chargement').style.display = 'none';
    document.getElementById('estado-erreur').style.display = 'block';
  }

  var token = new URLSearchParams(window.location.search).get('token');

  if (!token) {
    afficherErreur();
    return;
  }

  var urlFonction =
    window.location.origin + '/functions/v1/consulter-partage?token=' + encodeURIComponent(token);

  fetch(urlFonction)
    .then(function (reponse) {
      if (!reponse.ok) throw new Error('reponse non ok');
      return reponse.json();
    })
    .then(function (data) {
      if (data.error) throw new Error(data.error);
      afficherFiche(data);
    })
    .catch(function () {
      afficherErreur();
    });
})();
</script>
</body>
</html>
`;

Deno.serve((req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  return new Response(PAGE_HTML, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
    },
  });
});
