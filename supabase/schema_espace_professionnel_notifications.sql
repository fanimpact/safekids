-- =====================================================================
-- KidsRelay - Point d'entree unique pour toute notification destinee a
-- un parent (2026-08-19)
--
-- Demande de Fanny : preparer le terrain pour les notifications push
-- (prevues au moment de la publication sur les stores, pas construites
-- maintenant) sans attendre ce chantier -- une seule table sert deja
-- de journal pour l'email, et servira de point d'entree commun quand
-- le canal push sera branche : meme ligne, un statut par canal.
--
-- Types d'evenements prevus (le "type_evenement" est extensible, la
-- contrainte ci-dessous liste ceux deja identifies meme si un seul est
-- reellement declenche aujourd'hui) :
--   - note_ajoutee                     : deja en service (voir plus bas)
--   - expiration_rattachement_7_jours  : prevu, pas encore declenche
--     (§4 du plan espace professionnel, notifications d'expiration --
--     hors perimetre de ce chantier-ci)
--   - rappel_mise_a_jour_profil        : prevu, pas encore declenche
--
-- Cette table est un journal d'evenements a envoyer, pas juste un log
-- apres-coup : la ligne est creee AVANT l'envoi (statut "en_attente"),
-- puis mise a jour une fois l'envoi tente -- c'est ce qui permet de
-- brancher un futur envoi push sur la meme ligne sans dupliquer la
-- logique de declenchement.
--
-- Ce fichier peut etre rejoue sans risque.
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- Necessite schema_espace_professionnel_etablissements.sql (deja
-- execute) pour enfant_du_parent().
-- =====================================================================

create table if not exists public.evenements_notification_parent (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id),
  enfant_id uuid not null
    references public.enfants (id) on delete cascade,
  type_evenement text not null check (type_evenement in (
    'note_ajoutee',
    'expiration_rattachement_7_jours',
    'rappel_mise_a_jour_profil'
  )),
  -- Contexte propre au type d'evenement (ex. activite_id et
  -- etablissement_id pour "note_ajoutee") -- jamais de donnee de
  -- sante ni de contenu de note, memes regles que le contenu des
  -- emails eux-memes.
  donnees jsonb not null default '{}'::jsonb,
  statut_email text not null default 'en_attente'
    check (statut_email in ('en_attente', 'envoye', 'echoue')),
  email_envoye_le timestamptz,
  -- "non_branche" tant que le canal push n'existe pas : distinct de
  -- "en_attente" (evenement pas encore traite) pour ne pas laisser
  -- croire qu'un envoi push est imminent alors que le chantier n'est
  -- pas commence.
  statut_push text not null default 'non_branche'
    check (statut_push in (
      'non_branche', 'en_attente', 'envoye', 'echoue'
    )),
  push_envoye_le timestamptz,
  cree_le timestamptz not null default now()
);

alter table public.evenements_notification_parent enable row level security;

-- Le parent peut voir ses propres evenements (pas d'ecran dedie pour
-- l'instant, mais pas de raison de le lui interdire -- coherent avec
-- son droit de regard total sur tout ce que l'app contient a son
-- sujet). Aucune policy d'ecriture directe : toute creation/mise a
-- jour passe par les fonctions serveur (Edge Functions avec la cle
-- service_role), jamais par le client, pour garantir que parent_id ne
-- peut pas etre falsifie.
drop policy if exists "evenements_notification_lecture_par_parent"
  on public.evenements_notification_parent;

create policy "evenements_notification_lecture_par_parent"
  on public.evenements_notification_parent
  for select
  using (parent_id = auth.uid());
