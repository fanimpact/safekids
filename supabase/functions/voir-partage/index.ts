// Edge Function "voir-partage"
//
// Sert une page HTML lisible pour un lien de partage, destinée à un
// accompagnant qui n'a pas l'app KidsRelay installée. Le token est lu
// dans l'URL côté navigateur (JavaScript embarqué), qui appelle
// ensuite "consulter-partage" pour récupérer les données et affiche
// une fiche mise en forme. Page en lecture seule : aucun formulaire,
// aucune écriture.
//
// Ce fichier ne contient plus que l'enveloppe. La page elle-même est
// dans ../_logique/page_partage.mts, où son rendu est testé dans un
// faux DOM. Le seul point qui la liait à Supabase — l'adresse à
// laquelle le navigateur va chercher les données — est devenu un
// paramètre, dont la valeur par défaut est celle utilisée ici.
//
// Déploiement (comme consulter-partage, sans vérification JWT
// puisque l'accompagnant n'est pas authentifié) :
//   supabase functions deploy voir-partage --no-verify-jwt
//
// Lien à partager : <url-projet>/functions/v1/voir-partage?token=...

import {
  estPreflight,
  reponseHtml,
  reponsePreflight,
} from '../_enveloppe/http.mts';

import { construirePage } from '../_logique/page_partage.mts';

// Construite une seule fois : la page ne dépend d'aucune requête.
const PAGE_HTML = construirePage();

Deno.serve((req) => {
  if (estPreflight(req)) {
    return reponsePreflight();
  }

  return reponseHtml(PAGE_HTML);
});
