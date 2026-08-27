-- =======================================================================
-- Plusieurs appareils par partage, et une fenêtre qui ne glisse plus
-- 27/08/2026
-- =======================================================================
--
-- Deux changements liés.
--
-- **Le parent choisit le nombre d'appareils** — 1, 2 ou 5 — à la
-- création, et ce choix s'applique partout, QR compris. La restriction
-- du QR à un seul appareil a été écartée : un dispositif trop rigide
-- pousse la maîtresse à faire une capture d'écran de la fiche et à
-- l'envoyer par messagerie, et là il n'y a plus ni verrou, ni
-- révocation, ni journal.
--
-- **La fenêtre de tolérance ne glisse plus.** Elle était réécrite à
-- chaque reprise, donc renouvelable sans fin : constaté en base le
-- 27/08/2026, `verrou_pose_le` valait l'heure du second appareil et
-- non celle du premier. Désormais chaque place porte sa propre date de
-- première occupation, et un remplacement n'y touche pas.

-- =======================================================================
-- 1. Le nombre d'appareils autorisés
-- =======================================================================

alter table public.partages
  add column if not exists appareils_max smallint not null default 1;

alter table public.partages
  drop constraint if exists appareils_max_propose;

-- Les trois valeurs proposées au parent, et rien d'autre. Pas de
-- saisie libre : un champ ouvert invite le 20, et 20 n'est plus un
-- partage.
alter table public.partages
  add constraint appareils_max_propose
  check (appareils_max in (1, 2, 5));

comment on column public.partages.appareils_max is
  'Nombre d''appareils pouvant consulter ce partage. Choisi par le '
  'parent a la creation : 1 (defaut), 2 ou 5.';

-- =======================================================================
-- 2. Les places
-- =======================================================================
--
-- Une ligne par appareil qui a pris une place.
--
-- `pris_le` est la date de **première** occupation de la place, et
-- **n'est jamais réécrite** — c'est tout l'objet de la correction. Un
-- remplacement dans la fenêtre de tolérance change `empreinte`, jamais
-- `pris_le`.
--
-- `empreinte` est le hachage SHA-256 d'un secret que nous fabriquons et
-- déposons dans le navigateur. Jamais le secret lui-même : une fuite de
-- cette table ne donnerait à personne de quoi rouvrir un lien. Et rien
-- n'est lu sur l'appareil — ce n'est pas une empreinte de navigateur.

create table if not exists public.appareils_partage (
  id         uuid primary key default gen_random_uuid(),
  partage_id uuid not null
    references public.partages (id) on delete cascade,
  empreinte  text not null,
  pris_le    timestamptz not null default now()
);

create index if not exists appareils_partage_partage_idx
  on public.appareils_partage (partage_id, pris_le desc);

alter table public.appareils_partage enable row level security;

-- Le parent voit combien d'appareils ont ouvert son partage. Il ne voit
-- pas les empreintes — elles ne lui apprendraient rien et n'ont pas à
-- circuler. Aucune policy d'ecriture : seule la cle de service ecrit,
-- hors RLS, puisque celui qui ouvre le lien n'est pas authentifie.
drop policy if exists "appareils_lisibles_par_le_parent"
  on public.appareils_partage;

create policy "appareils_lisibles_par_le_parent"
  on public.appareils_partage
  for select
  using (
    exists (
      select 1 from public.partages p
      where p.id = partage_id
        and public.enfant_du_parent(p.enfant_id)
    )
  );

-- =======================================================================
-- 3. Reprise des verrous déjà posés
-- =======================================================================
--
-- Les liens verrouilles avant ce script gardent leur acces : leur
-- empreinte devient leur premiere place. Sans cela, l'appareil qui
-- detenait le verrou serait refuse du jour au lendemain.

insert into public.appareils_partage (partage_id, empreinte, pris_le)
select p.id, p.verrou_empreinte, coalesce(p.verrou_pose_le, now())
from public.partages p
where p.verrou_empreinte is not null
  and not exists (
    select 1 from public.appareils_partage a where a.partage_id = p.id
  );

-- =======================================================================
-- 4. Ce qui n'est PAS fait ici, et pourquoi
-- =======================================================================
--
-- `verrou_empreinte` et `verrou_pose_le` restent en place, inutilisees
-- par le nouveau code.
--
-- Les supprimer maintenant casserait la fonction `consulter-partage`
-- actuellement deployee, qui les lit encore : entre l'execution de ce
-- script et le redeploiement, plus aucun lien ne s'ouvrirait. Elles
-- seront retirees dans un second temps, une fois le redeploiement
-- confirme.
--
--   alter table public.partages
--     drop column verrou_empreinte,
--     drop column verrou_pose_le;
