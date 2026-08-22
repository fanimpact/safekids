-- =====================================================================
-- KidsRelay - a qui un lien de partage est destine (particulier ou
-- structure d'accueil), choisi obligatoirement par le parent a la
-- creation du lien. Sert a afficher la bonne mention a cote de chaque
-- traitement sur la page publique du lien (voir-partage) : rappel du
-- PAI pour une structure d'accueil, rappel des indications du parent
-- pour un particulier -- ce ne serait pas la meme mention selon qui
-- recoit le lien (grand-parent/nounou vs ecole/centre de loisirs).
--
-- Script idempotent. A executer dans Supabase : Dashboard -> SQL
-- Editor -> coller -> Run.
-- =====================================================================

alter table public.partages
  add column if not exists destinataire text
    not null default 'particulier'
    check (destinataire in ('particulier', 'structure_accueil'));
