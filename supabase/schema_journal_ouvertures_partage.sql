-- ---------------------------------------------------------------------
-- KidsRelay - tracer toutes les ouvertures d'un lien de partage
-- (25/08/2026)
--
-- Jusqu'ici, ouvrir un lien de partage mettait a jour une seule date
-- sur la ligne `partages` -- la derniere, ecrasee a chaque fois. Le
-- journal des consultations, lui, ne recensait que les etablissements
-- rattachés. Un parent qui avait partage un lien ne voyait donc rien.
--
-- Choix : reutiliser `journal_consultations_fiche` plutot que creer
-- une table. Elle a deja sa purge a 12 mois, sa policy de lecture par
-- le parent, son ecran, et elle figure deja dans l'export RGPD. Une
-- table de plus aurait tout fallu redoubler.
--
-- Ce qui est enregistre : l'enfant, le partage, le type de fiche, la
-- date et l'heure. **Rien d'autre.** Pas d'adresse IP, pas d'empreinte
-- de navigateur, pas d'en-tete de requete. Une ouverture de lien n'est
-- pas rattachable a une personne, et ce n'est pas un manque : le
-- parent a besoin de savoir que sa fiche a ete ouverte, pas de savoir
-- qui tenait le telephone.
--
-- A executer dans le SQL Editor de Supabase, en une fois. Idempotent.
-- ---------------------------------------------------------------------


-- =====================================================================
-- 1. La table accueille desormais deux origines
-- =====================================================================

-- Une ouverture de lien n'a pas d'utilisateur connecte : c'est tout
-- l'interet du lien de partage. La colonne devient donc facultative.
alter table public.journal_consultations_fiche
  alter column user_id drop not null;

alter table public.journal_consultations_fiche
  add column if not exists origine text not null
    default 'etablissement',
  add column if not exists partage_id uuid
    references public.partages (id) on delete set null;

comment on column public.journal_consultations_fiche.origine is
  'Qui a ouvert la fiche : "etablissement" (un membre du personnel '
  'rattache, identifie par user_id) ou "lien_partage" (quelqu''un qui '
  'a suivi un lien, non identifiable par construction).';

comment on column public.journal_consultations_fiche.partage_id is
  'Le lien ouvert, quand l''origine est "lien_partage". Passe a null '
  'si le parent revoque le lien : l''ouverture reste tracee, le lien '
  'disparait.';

-- La valeur par defaut n'existe que pour les lignes deja presentes,
-- qui viennent toutes d'un etablissement. Les prochaines ecritures
-- renseignent la colonne explicitement.
do $$
begin
  alter table public.journal_consultations_fiche
    add constraint journal_origine_valide
    check (origine in ('etablissement', 'lien_partage'));
exception when duplicate_object then
  null;
end;
$$;

-- Une ligne d'etablissement a toujours un utilisateur ; une ouverture
-- de lien n'en a jamais. Sans cette contrainte, une ecriture mal
-- formee passerait inapercue.
do $$
begin
  alter table public.journal_consultations_fiche
    add constraint journal_origine_coherente
    check (
      (origine = 'etablissement' and user_id is not null)
      or (origine = 'lien_partage' and user_id is null)
    );
exception when duplicate_object then
  null;
end;
$$;

-- Un lien de partage peut porter une fiche de recommandations
-- d'activite : ce type manquait a la contrainte, ecrite avant que le
-- partage de recommandations existe.
alter table public.journal_consultations_fiche
  drop constraint if exists journal_consultations_fiche_type_fiche_check;

alter table public.journal_consultations_fiche
  add constraint journal_consultations_fiche_type_fiche_check
  check (
    type_fiche in (
      'secours',
      'ce_qu_il_faut_savoir',
      'profil_activites',
      'mode_urgence',
      'recommandations_activite'
    )
  );

create index if not exists journal_consultations_enfant_idx
  on public.journal_consultations_fiche (enfant_id, consulte_le desc);


-- =====================================================================
-- 2. Ce qui ne change pas
-- =====================================================================
--
-- La policy d'ecriture "journal_ecriture_par_membre_actif" reste telle
-- quelle : elle exige user_id = auth.uid(), donc elle ne peut pas
-- servir a inserer une ouverture de lien. C'est voulu -- ces lignes
-- sont ecrites par la fonction consulter-partage, avec la cle de
-- service, hors RLS. Personne d'authentifie ne peut fabriquer une
-- fausse ouverture de lien.
--
-- La policy de lecture "journal_lecture_par_parent" couvre les deux
-- origines sans modification : elle ne regarde que l'enfant.
--
-- La purge a 12 mois ("purge-journal-consultations-fiche", tous les
-- jours a 3h) couvre les deux origines sans modification : elle ne
-- regarde que consulte_le.


-- =====================================================================
-- Verifications apres execution
-- =====================================================================
--
--   -- les colonnes et contraintes ajoutees
--   select column_name, is_nullable from information_schema.columns
--   where table_name = 'journal_consultations_fiche'
--   order by ordinal_position;
--
--   select conname from pg_constraint
--   where conrelid = 'public.journal_consultations_fiche'::regclass;
--
--   -- les deux origines, une fois qu'un lien aura ete ouvert
--   select origine, count(*) from public.journal_consultations_fiche
--   group by origine;
