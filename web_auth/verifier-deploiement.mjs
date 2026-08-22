// Compare la page réellement servie par auth.kidsrelay.fr avec les
// fichiers du dépôt.
//
// Sans ce contrôle, rien ne garantit que la version en ligne est celle
// du dépôt : la page se dépose à la main en FTP, il n'y a pas de
// déploiement automatique. Un écart passerait inaperçu.
//
//   node web_auth/verifier-deploiement.mjs
//   node web_auth/verifier-deploiement.mjs https://autre-adresse/chemin/
//
// Sort en code 1 si un fichier diffère ou manque, pour pouvoir servir
// de garde-fou dans un script ou une tâche planifiée.

import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const BASE_PAR_DEFAUT =
  'https://auth.kidsrelay.fr/ouvrir-lien-email/';

const FICHIERS = ['index.html', 'auth-lien.js'];

const dossierDuScript = dirname(fileURLToPath(import.meta.url));

const dossierLocal = join(
  dossierDuScript,
  'public',
  'ouvrir-lien-email',
);

/// Les fins de ligne sont normalisées avant comparaison : un dépôt FTP
/// en mode ASCII réécrit les CRLF, ce qui ferait échouer le contrôle
/// alors que le contenu est identique.
function empreinte(contenu) {
  const normalise = contenu.replace(/\r\n/g, '\n').trimEnd();

  return createHash('sha256').update(normalise, 'utf8').digest('hex');
}

async function empreinteLocale(nom) {
  return empreinte(await readFile(join(dossierLocal, nom), 'utf8'));
}

async function empreinteEnLigne(base, nom) {
  const url = new URL(nom, base).toString();

  const reponse = await fetch(url, {
    headers: { 'Cache-Control': 'no-cache' },
  });

  if (!reponse.ok) {
    return {
      erreur: `HTTP ${reponse.status}`,
      url,
    };
  }

  return { empreinte: empreinte(await reponse.text()), url };
}

const base = process.argv[2] ?? BASE_PAR_DEFAUT;

console.log(`Dépôt   : ${dossierLocal}`);
console.log(`En ligne: ${base}`);
console.log('');

let toutConforme = true;

for (const nom of FICHIERS) {
  const attendue = await empreinteLocale(nom);

  let servie;

  try {
    servie = await empreinteEnLigne(base, nom);
  } catch (erreur) {
    console.log(`✖ ${nom} — injoignable (${erreur.message})`);
    toutConforme = false;
    continue;
  }

  if (servie.erreur) {
    console.log(`✖ ${nom} — ${servie.erreur}`);
    toutConforme = false;
    continue;
  }

  if (servie.empreinte === attendue) {
    console.log(`✔ ${nom} — identique (${attendue.slice(0, 12)}…)`);
    continue;
  }

  console.log(`✖ ${nom} — DIFFÉRENT`);
  console.log(`    dépôt    : ${attendue.slice(0, 12)}…`);
  console.log(`    en ligne : ${servie.empreinte.slice(0, 12)}…`);
  toutConforme = false;
}

console.log('');

if (toutConforme) {
  console.log(
    'La page en ligne correspond exactement au dépôt.',
  );
  process.exit(0);
}

console.log(
  'Écart détecté : redéposez les fichiers de '
  + 'web_auth/public/ouvrir-lien-email/ sur l’hébergement.',
);
process.exit(1);
