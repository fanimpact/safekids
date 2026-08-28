// Écrit `public/index.html` à partir de la source de vérité :
// `supabase/functions/_logique/page_partage.mts`.
//
// La page n'est pas recopiée à la main. Elle reste construite par la
// fonction que ses 21 tests protègent — le fichier déposé chez OVH en
// est le rendu, régénéré à chaque changement.
//
//   node web_partage/generer.mjs
//
// Puis déposer `web_partage/public/` dans `www/fiche/` (voir README).

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { construirePage } from '../supabase/functions/_logique/page_partage.mts';

const ici = dirname(fileURLToPath(import.meta.url));
const dossier = join(ici, 'public');

mkdirSync(dossier, { recursive: true });

// La bibliotheque de QR, inlinee telle quelle : aucun CDN, aucune
// requete vers un tiers, et le code se calcule hors ligne.
//
// La source lisible plutot que la version minifiee : 57 Ko contre
// 20 Ko, sur une page chargee une fois. Ce que cela achete, c'est de
// pouvoir relire ce qu'on depose chez un hebergeur — un blob minifie
// ne s'audite pas.
const bibliothequeQr = readFileSync(
  join(ici, 'vendor', 'qrcode.js'),
  'utf8',
);

const page = construirePage(
  undefined,
  undefined,
  undefined,
  bibliothequeQr,
);

writeFileSync(join(dossier, 'index.html'), page, 'utf8');

// Ceinture et bretelles avec la balise `robots` de la page : un moteur
// qui ignorerait l'une lira l'autre. Une fiche d'enfant n'a rien à
// faire dans un index de recherche.
writeFileSync(
  join(dossier, 'robots.txt'),
  'User-agent: *\nDisallow: /\n',
  'utf8',
);

console.log(`Page écrite : ${join(dossier, 'index.html')}`);
console.log(`${page.length} octets`);
