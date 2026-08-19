-- =====================================================================
-- SafeKids - debloque le partage "recommandations_activite" :
-- "photo" figee au moment du partage, jamais recalculee cote serveur
-- (le moteur de recommandations n'existe qu'en Dart/Flutter, pas dans
-- les Edge Functions Deno). Voir corrections_a_faire.md point 5.
--
-- Script idempotent (peut etre rejoue sans risque).
-- A executer dans Supabase : Dashboard -> SQL Editor -> coller -> Run.
-- =====================================================================

alter table public.partages
  add column if not exists contenu_fige jsonb,
  add column if not exists activite_id uuid
    references public.activites_preparees (id) on delete set null;
