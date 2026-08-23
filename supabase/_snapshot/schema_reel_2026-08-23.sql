-- =====================================================================
-- KidsRelay - INSTANTANE DU SCHEMA REEL DE LA BASE
-- Projet Supabase : xcugfdjaifdibwowlrpi (eu-central-1)
-- Date de capture : 2026-08-23
--
-- CE FICHIER EST UNE PHOTOGRAPHIE, PAS UN SCRIPT A EXECUTER.
-- Il decrit ce que la base contient reellement, pour servir de point
-- de comparaison avec les 17 fichiers supabase/*.sql appliques a la
-- main. Voir docs/audits/ecart_schema.md pour l'analyse.
--
-- Genere depuis les catalogues PostgreSQL (pg_class, pg_attribute,
-- pg_constraint, pg_indexes, pg_policies, pg_proc, cron.job) et NON
-- par pg_dump : ni pg_dump, ni psql, ni Docker ne sont installes sur
-- le poste. Le contenu est donc fidele mais la mise en forme differe
-- de celle d'un pg_dump : ordre alphabetique, pas de dependances.
-- =====================================================================

-- ---------------------------------------------------------------------
-- EXTENSIONS (6)
-- ---------------------------------------------------------------------
-- pg_cron v1.6.4 (schema pg_catalog)
-- pg_stat_statements v1.11 (schema extensions)
-- pgcrypto v1.3 (schema extensions)
-- plpgsql v1.0 (schema pg_catalog)
-- supabase_vault v0.3.1 (schema vault)
-- uuid-ossp v1.1 (schema extensions)

-- ---------------------------------------------------------------------
-- SCHEMAS NON INTERNES (9)
-- ---------------------------------------------------------------------
-- auth, cron, extensions, graphql, graphql_public, public, realtime, storage, vault

-- ---------------------------------------------------------------------
-- TABLES (16)   VUES (0)   TRIGGERS (0)
-- ---------------------------------------------------------------------

create table public.activites_preparees (
  id uuid not null default gen_random_uuid(),
  cree_par uuid not null,
  parent_id uuid,
  etablissement_id uuid,
  nom_activite text,
  date_activite timestamp with time zone,
  lieu text,
  description jsonb not null default '{}'::jsonb,
  enfants_ids uuid[] not null default '{}'::uuid[],
  cree_le timestamp with time zone not null default now(),
  modifie_le timestamp with time zone not null default now(),
  modifie_par uuid
);

alter table public.activites_preparees add constraint activites_preparees_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES auth.users(id);
alter table public.activites_preparees add constraint activites_preparees_etablissement_id_fkey FOREIGN KEY (etablissement_id) REFERENCES etablissements(id) ON DELETE CASCADE;
alter table public.activites_preparees add constraint activites_preparees_modifie_par_fkey FOREIGN KEY (modifie_par) REFERENCES auth.users(id);
alter table public.activites_preparees add constraint activites_preparees_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES auth.users(id);
alter table public.activites_preparees add constraint activites_preparees_pkey PRIMARY KEY (id);
alter table public.activites_preparees add constraint un_seul_proprietaire CHECK (((((parent_id IS NOT NULL))::integer + ((etablissement_id IS NOT NULL))::integer) = 1));

alter table public.activites_preparees enable row level security;

CREATE UNIQUE INDEX activites_preparees_pkey ON public.activites_preparees USING btree (id);

create policy "activites_creation_par_membre" on public.activites_preparees
  as permissive
  for insert
  to public
  with check (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id) AND (cree_par = auth.uid())))
;

create policy "activites_du_parent" on public.activites_preparees
  as permissive
  for all
  to public
  using ((parent_id = auth.uid()))
  with check (((parent_id = auth.uid()) AND (cree_par = auth.uid())))
;

create policy "activites_lecture_par_membre" on public.activites_preparees
  as permissive
  for select
  to public
  using (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id)))
;

create policy "activites_modification_par_membre" on public.activites_preparees
  as permissive
  for update
  to public
  using (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id)))
  with check (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id)))
;

create policy "activites_suppression_par_membre" on public.activites_preparees
  as permissive
  for delete
  to public
  using (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id)))
;

-- ---------------------------------------------------------------------

create table public.activites_recommandations_masquees (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  activite_id uuid not null,
  cle_recommandation text not null,
  masque_le timestamp with time zone not null default now()
);

alter table public.activites_recommandations_masquees add constraint activites_recommandations_mas_user_id_activite_id_cle_recom_key UNIQUE (user_id, activite_id, cle_recommandation);
alter table public.activites_recommandations_masquees add constraint activites_recommandations_masquees_activite_id_fkey FOREIGN KEY (activite_id) REFERENCES activites_preparees(id) ON DELETE CASCADE;
alter table public.activites_recommandations_masquees add constraint activites_recommandations_masquees_pkey PRIMARY KEY (id);
alter table public.activites_recommandations_masquees add constraint activites_recommandations_masquees_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table public.activites_recommandations_masquees enable row level security;

CREATE UNIQUE INDEX activites_recommandations_mas_user_id_activite_id_cle_recom_key ON public.activites_recommandations_masquees USING btree (user_id, activite_id, cle_recommandation);
CREATE UNIQUE INDEX activites_recommandations_masquees_pkey ON public.activites_recommandations_masquees USING btree (id);

create policy "masquages_ecriture_insert" on public.activites_recommandations_masquees
  as permissive
  for insert
  to public
  with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM activites_preparees a
  WHERE ((a.id = activites_recommandations_masquees.activite_id) AND ((a.parent_id = auth.uid()) OR ((a.etablissement_id IS NOT NULL) AND est_membre_actif(a.etablissement_id))))))))
;

create policy "masquages_ecriture_update" on public.activites_recommandations_masquees
  as permissive
  for update
  to public
  using ((user_id = auth.uid()))
  with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM activites_preparees a
  WHERE ((a.id = activites_recommandations_masquees.activite_id) AND ((a.parent_id = auth.uid()) OR ((a.etablissement_id IS NOT NULL) AND est_membre_actif(a.etablissement_id))))))))
;

create policy "masquages_lecture" on public.activites_recommandations_masquees
  as permissive
  for select
  to public
  using (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM activites_preparees a
  WHERE ((a.id = activites_recommandations_masquees.activite_id) AND ((a.parent_id = auth.uid()) OR ((a.etablissement_id IS NOT NULL) AND est_membre_actif(a.etablissement_id))))))))
;

create policy "masquages_suppression" on public.activites_recommandations_masquees
  as permissive
  for delete
  to public
  using ((user_id = auth.uid()))
;

-- ---------------------------------------------------------------------

create table public.appareils_reconnus (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  jeton_hash text not null,
  nom_appareil text,
  cree_le timestamp with time zone not null default now(),
  derniere_utilisation_le timestamp with time zone not null default now()
);

alter table public.appareils_reconnus add constraint appareils_reconnus_pkey PRIMARY KEY (id);
alter table public.appareils_reconnus add constraint appareils_reconnus_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.appareils_reconnus add constraint appareils_reconnus_user_id_jeton_hash_key UNIQUE (user_id, jeton_hash);

alter table public.appareils_reconnus enable row level security;

CREATE UNIQUE INDEX appareils_reconnus_pkey ON public.appareils_reconnus USING btree (id);
CREATE UNIQUE INDEX appareils_reconnus_user_id_jeton_hash_key ON public.appareils_reconnus USING btree (user_id, jeton_hash);

create policy "appareils_du_compte" on public.appareils_reconnus
  as permissive
  for all
  to public
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()))
;

-- ---------------------------------------------------------------------

create table public.codes_verification (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  code_hash text not null,
  jeton_appareil_hash text not null,
  cree_le timestamp with time zone not null default now(),
  expire_le timestamp with time zone not null,
  utilise_le timestamp with time zone,
  tentatives integer not null default 0
);

alter table public.codes_verification add constraint codes_verification_pkey PRIMARY KEY (id);
alter table public.codes_verification add constraint codes_verification_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table public.codes_verification enable row level security;

CREATE INDEX codes_verification_expire_le_idx ON public.codes_verification USING btree (expire_le);
CREATE UNIQUE INDEX codes_verification_pkey ON public.codes_verification USING btree (id);

-- ---------------------------------------------------------------------

create table public.comptes_parents (
  id uuid not null,
  email text,
  abonnement_actif boolean not null default false,
  compte_relie_le timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

alter table public.comptes_parents add constraint comptes_parents_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.comptes_parents add constraint comptes_parents_pkey PRIMARY KEY (id);

alter table public.comptes_parents enable row level security;

CREATE UNIQUE INDEX comptes_parents_pkey ON public.comptes_parents USING btree (id);

create policy "comptes_parents_creation_propre" on public.comptes_parents
  as permissive
  for insert
  to public
  with check (((id = auth.uid()) AND (abonnement_actif = false)))
;

create policy "comptes_parents_lecture_propre" on public.comptes_parents
  as permissive
  for select
  to public
  using ((id = auth.uid()))
;

create policy "comptes_parents_maj_propre" on public.comptes_parents
  as permissive
  for update
  to public
  using ((id = auth.uid()))
  with check (((id = auth.uid()) AND (abonnement_actif = false)))
;

-- ---------------------------------------------------------------------

create table public.enfants (
  id uuid not null default gen_random_uuid(),
  parent_id uuid not null,
  prenom text,
  nom text,
  date_naissance date,
  poids numeric,
  taille numeric,
  date_maj_poids date,
  created_at timestamp with time zone not null default now(),
  a_pathologies_diagnostiquees boolean
);

alter table public.enfants add constraint enfants_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.enfants add constraint enfants_pkey PRIMARY KEY (id);

alter table public.enfants enable row level security;

CREATE UNIQUE INDEX enfants_pkey ON public.enfants USING btree (id);

create policy "enfants_du_parent" on public.enfants
  as permissive
  for all
  to public
  using ((parent_id = auth.uid()))
  with check ((parent_id = auth.uid()))
;

create policy "enfants_modifiables_par_personne_de_confiance" on public.enfants
  as permissive
  for update
  to public
  using (enfant_confie_a(id, 'lecture_ecriture'::text))
  with check (enfant_confie_a(id, 'lecture_ecriture'::text))
;

create policy "enfants_visibles_par_etablissement" on public.enfants
  as permissive
  for select
  to public
  using (enfant_visible_par_etablissement(id))
;

create policy "enfants_visibles_par_personne_de_confiance" on public.enfants
  as permissive
  for select
  to public
  using (enfant_confie_a(id))
;

-- ---------------------------------------------------------------------

create table public.enfants_confiance (
  id uuid not null default gen_random_uuid(),
  enfant_id uuid not null,
  email text not null,
  user_id uuid,
  niveau_acces text not null default 'lecture'::text,
  statut text not null default 'invite'::text,
  invite_par uuid not null,
  invite_le timestamp with time zone not null default now(),
  accepte_le timestamp with time zone,
  revoque_par uuid,
  revoque_le timestamp with time zone
);

alter table public.enfants_confiance add constraint enfants_confiance_enfant_id_email_key UNIQUE (enfant_id, email);
alter table public.enfants_confiance add constraint enfants_confiance_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.enfants_confiance add constraint enfants_confiance_invite_par_fkey FOREIGN KEY (invite_par) REFERENCES auth.users(id);
alter table public.enfants_confiance add constraint enfants_confiance_niveau_acces_check CHECK ((niveau_acces = ANY (ARRAY['lecture'::text, 'lecture_ecriture'::text])));
alter table public.enfants_confiance add constraint enfants_confiance_pkey PRIMARY KEY (id);
alter table public.enfants_confiance add constraint enfants_confiance_revoque_par_fkey FOREIGN KEY (revoque_par) REFERENCES auth.users(id);
alter table public.enfants_confiance add constraint enfants_confiance_statut_check CHECK ((statut = ANY (ARRAY['invite'::text, 'actif'::text, 'revoque'::text])));
alter table public.enfants_confiance add constraint enfants_confiance_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table public.enfants_confiance enable row level security;

CREATE UNIQUE INDEX enfants_confiance_enfant_id_email_key ON public.enfants_confiance USING btree (enfant_id, email);
CREATE UNIQUE INDEX enfants_confiance_pkey ON public.enfants_confiance USING btree (id);

create policy "enfants_confiance_lecture" on public.enfants_confiance
  as permissive
  for select
  to public
  using (((user_id = auth.uid()) OR enfant_du_parent(enfant_id)))
;

-- ---------------------------------------------------------------------

create table public.enfants_etablissements (
  id uuid not null default gen_random_uuid(),
  token text not null default encode(extensions.gen_random_bytes(24), 'hex'::text),
  enfant_id uuid not null,
  etablissement_id uuid,
  statut text not null default 'en_attente'::text,
  date_creation timestamp with time zone not null default now(),
  date_expiration timestamp with time zone not null,
  claime_par uuid,
  claime_le timestamp with time zone,
  revoque_le timestamp with time zone
);

alter table public.enfants_etablissements add constraint enfants_etablissements_claime_par_fkey FOREIGN KEY (claime_par) REFERENCES auth.users(id);
alter table public.enfants_etablissements add constraint enfants_etablissements_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.enfants_etablissements add constraint enfants_etablissements_etablissement_id_fkey FOREIGN KEY (etablissement_id) REFERENCES etablissements(id) ON DELETE CASCADE;
alter table public.enfants_etablissements add constraint enfants_etablissements_pkey PRIMARY KEY (id);
alter table public.enfants_etablissements add constraint enfants_etablissements_statut_check CHECK ((statut = ANY (ARRAY['en_attente'::text, 'actif'::text, 'revoque'::text])));
alter table public.enfants_etablissements add constraint enfants_etablissements_token_key UNIQUE (token);

alter table public.enfants_etablissements enable row level security;

CREATE UNIQUE INDEX enfants_etablissements_pkey ON public.enfants_etablissements USING btree (id);
CREATE UNIQUE INDEX enfants_etablissements_token_key ON public.enfants_etablissements USING btree (token);

create policy "enfants_etablissements_du_parent" on public.enfants_etablissements
  as permissive
  for all
  to public
  using (enfant_du_parent(enfant_id))
  with check (enfant_du_parent(enfant_id))
;

create policy "enfants_etablissements_lecture_par_membre" on public.enfants_etablissements
  as permissive
  for select
  to public
  using (((etablissement_id IS NOT NULL) AND est_membre_actif(etablissement_id)))
;

create policy "enfants_etablissements_lecture_token_en_attente" on public.enfants_etablissements
  as permissive
  for select
  to public
  using (((statut = 'en_attente'::text) AND (date_expiration > now())))
;

-- ---------------------------------------------------------------------

create table public.etablissements (
  id uuid not null default gen_random_uuid(),
  nom text not null,
  type_etablissement text,
  created_by uuid not null,
  created_at timestamp with time zone not null default now()
);

alter table public.etablissements add constraint etablissements_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
alter table public.etablissements add constraint etablissements_pkey PRIMARY KEY (id);

alter table public.etablissements enable row level security;

CREATE UNIQUE INDEX etablissements_pkey ON public.etablissements USING btree (id);

create policy "etablissements_visibles_par_membre_actif" on public.etablissements
  as permissive
  for select
  to public
  using (est_membre_actif(id))
;

create policy "etablissements_visibles_par_parent_enfant_rattache" on public.etablissements
  as permissive
  for select
  to public
  using (etablissement_du_parent(id))
;

-- ---------------------------------------------------------------------

create table public.evenements_notification_parent (
  id uuid not null default gen_random_uuid(),
  parent_id uuid not null,
  enfant_id uuid not null,
  type_evenement text not null,
  donnees jsonb not null default '{}'::jsonb,
  statut_email text not null default 'en_attente'::text,
  email_envoye_le timestamp with time zone,
  statut_push text not null default 'non_branche'::text,
  push_envoye_le timestamp with time zone,
  cree_le timestamp with time zone not null default now()
);

alter table public.evenements_notification_parent add constraint evenements_notification_parent_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.evenements_notification_parent add constraint evenements_notification_parent_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES auth.users(id);
alter table public.evenements_notification_parent add constraint evenements_notification_parent_pkey PRIMARY KEY (id);
alter table public.evenements_notification_parent add constraint evenements_notification_parent_statut_email_check CHECK ((statut_email = ANY (ARRAY['en_attente'::text, 'envoye'::text, 'echoue'::text])));
alter table public.evenements_notification_parent add constraint evenements_notification_parent_statut_push_check CHECK ((statut_push = ANY (ARRAY['non_branche'::text, 'en_attente'::text, 'envoye'::text, 'echoue'::text])));
alter table public.evenements_notification_parent add constraint evenements_notification_parent_type_evenement_check CHECK ((type_evenement = ANY (ARRAY['note_ajoutee'::text, 'expiration_rattachement_7_jours'::text, 'rappel_mise_a_jour_profil'::text])));

alter table public.evenements_notification_parent enable row level security;

CREATE UNIQUE INDEX evenements_notification_parent_pkey ON public.evenements_notification_parent USING btree (id);

create policy "evenements_notification_lecture_par_parent" on public.evenements_notification_parent
  as permissive
  for select
  to public
  using ((parent_id = auth.uid()))
;

-- ---------------------------------------------------------------------

create table public.journal_consultations_fiche (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  enfant_id uuid not null,
  etablissement_id uuid,
  type_fiche text not null,
  consulte_le timestamp with time zone not null default now()
);

alter table public.journal_consultations_fiche add constraint journal_consultations_fiche_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.journal_consultations_fiche add constraint journal_consultations_fiche_etablissement_id_fkey FOREIGN KEY (etablissement_id) REFERENCES etablissements(id) ON DELETE CASCADE;
alter table public.journal_consultations_fiche add constraint journal_consultations_fiche_pkey PRIMARY KEY (id);
alter table public.journal_consultations_fiche add constraint journal_consultations_fiche_type_fiche_check CHECK ((type_fiche = ANY (ARRAY['secours'::text, 'ce_qu_il_faut_savoir'::text, 'profil_activites'::text, 'mode_urgence'::text])));
alter table public.journal_consultations_fiche add constraint journal_consultations_fiche_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table public.journal_consultations_fiche enable row level security;

CREATE INDEX journal_consultations_consulte_le_idx ON public.journal_consultations_fiche USING btree (consulte_le);
CREATE UNIQUE INDEX journal_consultations_fiche_pkey ON public.journal_consultations_fiche USING btree (id);

create policy "journal_ecriture_par_membre_actif" on public.journal_consultations_fiche
  as permissive
  for insert
  to public
  with check (((user_id = auth.uid()) AND enfant_visible_par_etablissement(enfant_id)))
;

create policy "journal_lecture_par_parent" on public.journal_consultations_fiche
  as permissive
  for select
  to public
  using (enfant_du_parent(enfant_id))
;

-- ---------------------------------------------------------------------

create table public.membres_etablissement (
  id uuid not null default gen_random_uuid(),
  etablissement_id uuid not null,
  email text not null,
  user_id uuid,
  role text not null,
  statut text not null default 'invite'::text,
  invite_par uuid not null,
  invite_le timestamp with time zone not null default now(),
  accepte_le timestamp with time zone,
  revoque_par uuid,
  revoque_le timestamp with time zone
);

alter table public.membres_etablissement add constraint membres_etablissement_etablissement_id_email_key UNIQUE (etablissement_id, email);
alter table public.membres_etablissement add constraint membres_etablissement_etablissement_id_fkey FOREIGN KEY (etablissement_id) REFERENCES etablissements(id) ON DELETE CASCADE;
alter table public.membres_etablissement add constraint membres_etablissement_invite_par_fkey FOREIGN KEY (invite_par) REFERENCES auth.users(id);
alter table public.membres_etablissement add constraint membres_etablissement_pkey PRIMARY KEY (id);
alter table public.membres_etablissement add constraint membres_etablissement_revoque_par_fkey FOREIGN KEY (revoque_par) REFERENCES auth.users(id);
alter table public.membres_etablissement add constraint membres_etablissement_role_check CHECK ((role = ANY (ARRAY['directeur'::text, 'adjoint'::text, 'membre'::text])));
alter table public.membres_etablissement add constraint membres_etablissement_statut_check CHECK ((statut = ANY (ARRAY['invite'::text, 'actif'::text, 'revoque'::text])));
alter table public.membres_etablissement add constraint membres_etablissement_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table public.membres_etablissement enable row level security;

CREATE UNIQUE INDEX membres_etablissement_etablissement_id_email_key ON public.membres_etablissement USING btree (etablissement_id, email);
CREATE UNIQUE INDEX membres_etablissement_pkey ON public.membres_etablissement USING btree (id);

create policy "membres_lecture_par_membre_actif_ou_soi_meme" on public.membres_etablissement
  as permissive
  for select
  to public
  using (((user_id = auth.uid()) OR est_membre_actif(etablissement_id)))
;

-- ---------------------------------------------------------------------

create table public.notes_activite (
  id uuid not null default gen_random_uuid(),
  activite_id uuid not null,
  auteur_id uuid not null,
  enfant_id uuid,
  note text not null,
  cree_le timestamp with time zone not null default now(),
  modifie_le timestamp with time zone
);

alter table public.notes_activite add constraint notes_activite_activite_id_fkey FOREIGN KEY (activite_id) REFERENCES activites_preparees(id) ON DELETE CASCADE;
alter table public.notes_activite add constraint notes_activite_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES auth.users(id);
alter table public.notes_activite add constraint notes_activite_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.notes_activite add constraint notes_activite_pkey PRIMARY KEY (id);

alter table public.notes_activite enable row level security;

CREATE UNIQUE INDEX notes_activite_pkey ON public.notes_activite USING btree (id);

create policy "notes_creation_par_membre" on public.notes_activite
  as permissive
  for insert
  to public
  with check (((auteur_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM activites_preparees a
  WHERE ((a.id = notes_activite.activite_id) AND (a.etablissement_id IS NOT NULL) AND est_membre_actif(a.etablissement_id))))))
;

create policy "notes_lecture_auteur_ou_parent" on public.notes_activite
  as permissive
  for select
  to public
  using (((auteur_id = auth.uid()) OR ((enfant_id IS NOT NULL) AND enfant_du_parent(enfant_id))))
;

create policy "notes_modification_par_auteur" on public.notes_activite
  as permissive
  for update
  to public
  using ((auteur_id = auth.uid()))
  with check ((auteur_id = auth.uid()))
;

create policy "notes_suppression_par_auteur" on public.notes_activite
  as permissive
  for delete
  to public
  using ((auteur_id = auth.uid()))
;

-- ---------------------------------------------------------------------

create table public.partages (
  id uuid not null default gen_random_uuid(),
  token text not null default encode(extensions.gen_random_bytes(24), 'hex'::text),
  enfant_id uuid not null,
  type_fiche text not null,
  date_creation timestamp with time zone not null default now(),
  date_expiration timestamp with time zone not null,
  date_derniere_consultation timestamp with time zone,
  contenu_fige jsonb,
  activite_id uuid,
  destinataire text not null default 'particulier'::text
);

alter table public.partages add constraint partages_activite_id_fkey FOREIGN KEY (activite_id) REFERENCES activites_preparees(id) ON DELETE SET NULL;
alter table public.partages add constraint partages_destinataire_check CHECK ((destinataire = ANY (ARRAY['particulier'::text, 'structure_accueil'::text])));
alter table public.partages add constraint partages_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.partages add constraint partages_pkey PRIMARY KEY (id);
alter table public.partages add constraint partages_token_key UNIQUE (token);
alter table public.partages add constraint partages_type_fiche_check CHECK ((type_fiche = ANY (ARRAY['secours'::text, 'ce_qu_il_faut_savoir'::text, 'recommandations_activite'::text])));

alter table public.partages enable row level security;

CREATE UNIQUE INDEX partages_pkey ON public.partages USING btree (id);
CREATE UNIQUE INDEX partages_token_key ON public.partages USING btree (token);

create policy "partages_geres_par_le_parent" on public.partages
  as permissive
  for all
  to public
  using (enfant_du_parent(enfant_id))
  with check (enfant_du_parent(enfant_id))
;

-- ---------------------------------------------------------------------

create table public.profils_activites (
  id uuid not null default gen_random_uuid(),
  enfant_id uuid not null,
  habillage jsonb not null default '{}'::jsonb,
  toilettes jsonb not null default '{}'::jsonb,
  communication jsonb not null default '{}'::jsonb,
  transport jsonb not null default '{}'::jsonb,
  securite jsonb not null default '{}'::jsonb,
  nuitee jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  activite_aquatique jsonb not null default '{}'::jsonb,
  effort_marche jsonb not null default '{}'::jsonb,
  transitions jsonb not null default '{}'::jsonb,
  autres_informations jsonb not null default '{}'::jsonb,
  repas jsonb not null default '{}'::jsonb
);

alter table public.profils_activites add constraint profils_activites_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.profils_activites add constraint profils_activites_pkey PRIMARY KEY (id);

alter table public.profils_activites enable row level security;

CREATE UNIQUE INDEX profils_activites_enfant_id_key ON public.profils_activites USING btree (enfant_id);
CREATE UNIQUE INDEX profils_activites_pkey ON public.profils_activites USING btree (id);

create policy "profils_activites_du_parent" on public.profils_activites
  as permissive
  for all
  to public
  using ((enfant_id IN ( SELECT enfants.id
   FROM enfants
  WHERE (enfants.parent_id = auth.uid()))))
  with check ((enfant_id IN ( SELECT enfants.id
   FROM enfants
  WHERE (enfants.parent_id = auth.uid()))))
;

create policy "profils_activites_modifiables_par_personne_de_confiance" on public.profils_activites
  as permissive
  for update
  to public
  using (enfant_confie_a(enfant_id, 'lecture_ecriture'::text))
  with check (enfant_confie_a(enfant_id, 'lecture_ecriture'::text))
;

create policy "profils_activites_visibles_par_etablissement" on public.profils_activites
  as permissive
  for select
  to public
  using (enfant_visible_par_etablissement(enfant_id))
;

create policy "profils_activites_visibles_par_personne_de_confiance" on public.profils_activites
  as permissive
  for select
  to public
  using (enfant_confie_a(enfant_id))
;

-- ---------------------------------------------------------------------

create table public.profils_sante (
  id uuid not null default gen_random_uuid(),
  enfant_id uuid not null,
  pathologies jsonb not null default '[]'::jsonb,
  allergies jsonb not null default '[]'::jsonb,
  traitements_urgence jsonb not null default '[]'::jsonb,
  traitements_reguliers jsonb not null default '[]'::jsonb,
  dispositifs_medicaux jsonb not null default '[]'::jsonb,
  medecin_traitant jsonb not null default '{}'::jsonb,
  facteurs_declenchants jsonb not null default '{}'::jsonb,
  contacts_urgence jsonb not null default '[]'::jsonb,
  created_at timestamp with time zone not null default now(),
  evenements_medicaux jsonb not null default '[]'::jsonb,
  observations_medicales jsonb not null default '[]'::jsonb,
  traitements_arretes jsonb not null default '[]'::jsonb,
  a_pathologies boolean,
  a_allergies boolean,
  a_traitements_reguliers boolean,
  a_traitements_arretes boolean,
  a_traitements_urgence boolean,
  a_dispositifs_medicaux boolean
);

alter table public.profils_sante add constraint profils_sante_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE;
alter table public.profils_sante add constraint profils_sante_pkey PRIMARY KEY (id);

alter table public.profils_sante enable row level security;

CREATE UNIQUE INDEX profils_sante_enfant_id_key ON public.profils_sante USING btree (enfant_id);
CREATE UNIQUE INDEX profils_sante_pkey ON public.profils_sante USING btree (id);

create policy "profils_sante_du_parent" on public.profils_sante
  as permissive
  for all
  to public
  using ((enfant_id IN ( SELECT enfants.id
   FROM enfants
  WHERE (enfants.parent_id = auth.uid()))))
  with check ((enfant_id IN ( SELECT enfants.id
   FROM enfants
  WHERE (enfants.parent_id = auth.uid()))))
;

create policy "profils_sante_modifiables_par_personne_de_confiance" on public.profils_sante
  as permissive
  for update
  to public
  using (enfant_confie_a(enfant_id, 'lecture_ecriture'::text))
  with check (enfant_confie_a(enfant_id, 'lecture_ecriture'::text))
;

create policy "profils_sante_visibles_par_etablissement" on public.profils_sante
  as permissive
  for select
  to public
  using (enfant_visible_par_etablissement(enfant_id))
;

create policy "profils_sante_visibles_par_personne_de_confiance" on public.profils_sante
  as permissive
  for select
  to public
  using (enfant_confie_a(enfant_id))
;

-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- FONCTIONS (18)
-- ---------------------------------------------------------------------

-- enfant_confie_a(p_enfant_id uuid, p_niveau_requis text) | sql | security definer | md5 ecd7d3cfea81b040ef2c29d8aecc60f9
CREATE OR REPLACE FUNCTION public.enfant_confie_a(p_enfant_id uuid, p_niveau_requis text DEFAULT 'lecture'::text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.enfants_confiance
    where enfant_id = p_enfant_id
      and user_id = auth.uid()
      and statut = 'actif'
      and (
        p_niveau_requis = 'lecture'
        or niveau_acces = 'lecture_ecriture'
      )
  );
$function$;

-- enfant_du_parent(p_enfant_id uuid) | sql | security definer | md5 4a055ab983fd24598f954a2f19fadeae
CREATE OR REPLACE FUNCTION public.enfant_du_parent(p_enfant_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.enfants
    where id = p_enfant_id and parent_id = auth.uid()
  );
$function$;

-- enfant_visible_par_etablissement(p_enfant_id uuid) | sql | security definer | md5 ff080e036df6ecc003ed4ab9cc2db38a
CREATE OR REPLACE FUNCTION public.enfant_visible_par_etablissement(p_enfant_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.enfant_id = p_enfant_id
      and ee.statut = 'actif'
      and ee.date_expiration > now()
      and ee.etablissement_id is not null
      and public.est_membre_actif(ee.etablissement_id)
  );
$function$;

-- est_membre_actif(p_etablissement_id uuid) | sql | security definer | md5 f2f3c304eddf019eb0bad3e07795ccf6
CREATE OR REPLACE FUNCTION public.est_membre_actif(p_etablissement_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.membres_etablissement
    where user_id = auth.uid()
      and etablissement_id = p_etablissement_id
      and statut = 'actif'
  );
$function$;

-- etablissement_du_parent(p_etablissement_id uuid) | sql | security definer | md5 43580c296202797a20e54a6a810bbe12
CREATE OR REPLACE FUNCTION public.etablissement_du_parent(p_etablissement_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.enfants_etablissements ee
    where ee.etablissement_id = p_etablissement_id
      and public.enfant_du_parent(ee.enfant_id)
  );
$function$;

-- nombre_gestionnaires_actifs(p_etablissement_id uuid) | sql | security definer | md5 d10f48cf5380176a261b0dff61bdf209
CREATE OR REPLACE FUNCTION public.nombre_gestionnaires_actifs(p_etablissement_id uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select count(*)::integer
  from public.membres_etablissement
  where etablissement_id = p_etablissement_id
    and statut = 'actif'
    and role in ('directeur', 'adjoint');
$function$;

-- peut_gerer_membres(p_etablissement_id uuid) | sql | security definer | md5 03a893daeed75dfd918169d378666b99
CREATE OR REPLACE FUNCTION public.peut_gerer_membres(p_etablissement_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.membres_etablissement
    where user_id = auth.uid()
      and etablissement_id = p_etablissement_id
      and statut = 'actif'
      and role in ('directeur', 'adjoint')
  );
$function$;

-- rpc_activer_confiances_en_attente() | plpgsql | security definer | md5 7b1a851f381234fa5c6dcf00f90bbf2b
CREATE OR REPLACE FUNCTION public.rpc_activer_confiances_en_attente()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_email text;
  v_count integer;
begin
  v_email := lower(trim(coalesce(auth.jwt() ->> 'email', '')));

  if v_email = '' then
    return 0;
  end if;

  update public.enfants_confiance
  set user_id = auth.uid(),
      statut = 'actif',
      accepte_le = now()
  where email = v_email
    and statut = 'invite'
    and user_id is null;

  get diagnostics v_count = row_count;

  return v_count;
end;
$function$;

-- rpc_activer_invitations_en_attente() | plpgsql | security definer | md5 21c792976853c12c7a83acaf153073dc
CREATE OR REPLACE FUNCTION public.rpc_activer_invitations_en_attente()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_email text;
  v_count integer;
begin
  v_email := lower(trim(coalesce(auth.jwt() ->> 'email', '')));

  if v_email = '' then
    return 0;
  end if;

  update public.membres_etablissement
  set user_id = auth.uid(),
      statut = 'actif',
      accepte_le = now()
  where email = v_email
    and statut = 'invite'
    and user_id is null;

  get diagnostics v_count = row_count;

  return v_count;
end;
$function$;

-- rpc_assurer_identite_email() | plpgsql | security definer | md5 8aa3cf41952a6ac4c2dc1b045498e5b4
CREATE OR REPLACE FUNCTION public.rpc_assurer_identite_email()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user_id uuid;
  v_email text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    return;
  end if;

  -- Utilise l'email confirme s'il existe deja, sinon celui en attente
  -- de confirmation : dans les deux cas, c'est l'adresse avec laquelle
  -- la personne va essayer de se reconnecter.
  select coalesce(
    nullif(email, ''),
    nullif(email_change, '')
  )
  into v_email
  from auth.users
  where id = v_user_id;

  if v_email is null then
    return;
  end if;

  -- Confirme l'email directement sur auth.users, sans attendre le
  -- clic sur le lien envoye par Supabase : c'est cette colonne, pas
  -- auth.identities, que signInWithPassword utilise pour retrouver le
  -- compte.
  -- confirmed_at est une colonne generee (derivee de
  -- email_confirmed_at / phone_confirmed_at) : impossible de l'ecrire
  -- directement, elle se met a jour toute seule.
  update auth.users
  set
    email = v_email,
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    email_change = '',
    email_change_confirm_status = 0,
    is_anonymous = false
  where id = v_user_id;

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  )
  values (
    gen_random_uuid(), v_user_id, v_user_id,
    jsonb_build_object(
      'sub', v_user_id,
      'email', v_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  )
  on conflict (provider_id, provider) do nothing;

  -- Cause racine confirmee (19/08/2026) : comptes_parents.email n'est
  -- ecrit qu'une fois, lors de AccountService.createAccount() --
  -- jamais resynchronise si l'email de auth.users change ensuite (ex.
  -- correction manuelle en base pendant le debogage du 17-18/08). Les
  -- notifications par email (note ajoutee, expiration) lisent
  -- comptes_parents.email, pas auth.users.email : un ecart entre les
  -- deux fait partir l'email vers une adresse perimee, en silence,
  -- sans jamais faire echouer l'appel Brevo (l'adresse perimee peut
  -- tres bien exister). On les garde synchronises ici a chaque appel.
  update public.comptes_parents
  set email = v_email
  where id = v_user_id
    and email is distinct from v_email;
end;
$function$;

-- rpc_changer_niveau_confiance(p_confiance_id uuid, p_nouveau_niveau text) | plpgsql | security definer | md5 246b6edd93f849dfe4eaea1ad2afcbee
CREATE OR REPLACE FUNCTION public.rpc_changer_niveau_confiance(p_confiance_id uuid, p_nouveau_niveau text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_enfant_id uuid;
begin
  select enfant_id into v_enfant_id
  from public.enfants_confiance
  where id = p_confiance_id
  for update;

  if v_enfant_id is null then
    raise exception 'Personne de confiance introuvable.';
  end if;

  if not public.enfant_du_parent(v_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut changer ce niveau d''acces.';
  end if;

  if p_nouveau_niveau not in ('lecture', 'lecture_ecriture') then
    raise exception 'Niveau d''acces invalide.';
  end if;

  update public.enfants_confiance
  set niveau_acces = p_nouveau_niveau
  where id = p_confiance_id;
end;
$function$;

-- rpc_changer_role_membre(p_membre_id uuid, p_nouveau_role text) | plpgsql | security definer | md5 e9d14fa697c2601b95a0c7132ae6a7a2
CREATE OR REPLACE FUNCTION public.rpc_changer_role_membre(p_membre_id uuid, p_nouveau_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_etablissement_id uuid;
  v_ancien_role text;
  v_statut text;
begin
  select etablissement_id, role, statut
  into v_etablissement_id, v_ancien_role, v_statut
  from public.membres_etablissement
  where id = p_membre_id
  for update;

  if v_etablissement_id is null then
    raise exception 'Membre introuvable.';
  end if;

  if not public.peut_gerer_membres(v_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent changer un role.';
  end if;

  if v_statut != 'actif' then
    raise exception 'Seul un membre actif peut changer de role.';
  end if;

  if p_nouveau_role not in ('directeur', 'adjoint', 'membre') then
    raise exception 'Role invalide.';
  end if;

  if v_ancien_role in ('directeur', 'adjoint')
     and p_nouveau_role = 'membre'
     and public.nombre_gestionnaires_actifs(v_etablissement_id) <= 1 then
    raise exception
      'Impossible : ce serait le dernier directeur ou adjoint de '
      'l''etablissement. Nommez d''abord quelqu''un d''autre.';
  end if;

  update public.membres_etablissement
  set role = p_nouveau_role
  where id = p_membre_id;
end;
$function$;

-- rpc_creer_etablissement(p_nom text, p_type text) | plpgsql | security definer | md5 1cd6dc5ef55a13a63b1d2a8c19b25075
CREATE OR REPLACE FUNCTION public.rpc_creer_etablissement(p_nom text, p_type text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
  v_email text;
begin
  if p_nom is null or length(trim(p_nom)) = 0 then
    raise exception 'Le nom de l''etablissement est obligatoire.';
  end if;

  v_email := auth.jwt() ->> 'email';

  insert into public.etablissements (nom, type_etablissement, created_by)
  values (trim(p_nom), p_type, auth.uid())
  returning id into v_id;

  insert into public.membres_etablissement
    (etablissement_id, email, user_id, role, statut, invite_par, accepte_le)
  values
    (v_id, coalesce(v_email, ''), auth.uid(), 'directeur', 'actif', auth.uid(), now());

  return v_id;
end;
$function$;

-- rpc_inviter_membre(p_etablissement_id uuid, p_email text, p_role text) | plpgsql | security definer | md5 e5c121c01eeaa070210e5bd920f598b1
CREATE OR REPLACE FUNCTION public.rpc_inviter_membre(p_etablissement_id uuid, p_email text, p_role text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
  v_email text;
begin
  if not public.peut_gerer_membres(p_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent inviter quelqu''un.';
  end if;

  if p_role not in ('adjoint', 'membre') then
    raise exception
      'Role invalide pour une invitation (adjoint ou membre uniquement).';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));

  if v_email = '' then
    raise exception 'L''adresse email est obligatoire.';
  end if;

  insert into public.membres_etablissement
    (etablissement_id, email, role, statut, invite_par)
  values
    (p_etablissement_id, v_email, p_role, 'invite', auth.uid())
  returning id into v_id;

  return v_id;
end;
$function$;

-- rpc_inviter_personne_confiance(p_enfant_id uuid, p_email text, p_niveau_acces text) | plpgsql | security definer | md5 1847b83a48a8ebba0cbaf922266ffe92
CREATE OR REPLACE FUNCTION public.rpc_inviter_personne_confiance(p_enfant_id uuid, p_email text, p_niveau_acces text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
  v_email text;
  v_nombre_actuel integer;
begin
  if not public.enfant_du_parent(p_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut inviter une personne de '
      'confiance.';
  end if;

  if p_niveau_acces not in ('lecture', 'lecture_ecriture') then
    raise exception 'Niveau d''acces invalide.';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));

  if v_email = '' then
    raise exception 'L''adresse email est obligatoire.';
  end if;

  select count(*) into v_nombre_actuel
  from public.enfants_confiance
  where enfant_id = p_enfant_id
    and statut != 'revoque';

  if v_nombre_actuel >= 2 then
    raise exception
      'Deux personnes de confiance au maximum par enfant. '
      'Revoquez d''abord un acces existant.';
  end if;

  insert into public.enfants_confiance
    (enfant_id, email, niveau_acces, statut, invite_par)
  values
    (p_enfant_id, v_email, p_niveau_acces, 'invite', auth.uid())
  returning id into v_id;

  return v_id;
end;
$function$;

-- rpc_reclamer_rattachement(p_token text, p_etablissement_id uuid) | plpgsql | security definer | md5 06225066990222167ff8b91c39ceb525
CREATE OR REPLACE FUNCTION public.rpc_reclamer_rattachement(p_token text, p_etablissement_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_rattachement_id uuid;
  v_enfant_id uuid;
  v_prenom text;
begin
  if not public.est_membre_actif(p_etablissement_id) then
    raise exception 'Vous n''etes pas membre actif de cet etablissement.';
  end if;

  select id, enfant_id into v_rattachement_id, v_enfant_id
  from public.enfants_etablissements
  where token = p_token
    and statut = 'en_attente'
    and date_expiration > now()
  for update;

  if v_rattachement_id is null then
    raise exception 'Lien invalide ou expire.';
  end if;

  update public.enfants_etablissements
  set etablissement_id = p_etablissement_id,
      statut = 'actif',
      claime_par = auth.uid(),
      claime_le = now()
  where id = v_rattachement_id;

  select prenom into v_prenom
  from public.enfants
  where id = v_enfant_id;

  return v_prenom;
end;
$function$;

-- rpc_revoquer_confiance(p_confiance_id uuid) | plpgsql | security definer | md5 c5ff57a467f13469ff36fc0973b4bcfe
CREATE OR REPLACE FUNCTION public.rpc_revoquer_confiance(p_confiance_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_enfant_id uuid;
begin
  select enfant_id into v_enfant_id
  from public.enfants_confiance
  where id = p_confiance_id
  for update;

  if v_enfant_id is null then
    raise exception 'Personne de confiance introuvable.';
  end if;

  if not public.enfant_du_parent(v_enfant_id) then
    raise exception
      'Seul le parent de cet enfant peut revoquer cet acces.';
  end if;

  update public.enfants_confiance
  set statut = 'revoque',
      revoque_par = auth.uid(),
      revoque_le = now()
  where id = p_confiance_id;
end;
$function$;

-- rpc_revoquer_membre(p_membre_id uuid) | plpgsql | security definer | md5 50d2b970f4e8418ab13f79e763a7f0bc
CREATE OR REPLACE FUNCTION public.rpc_revoquer_membre(p_membre_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_etablissement_id uuid;
  v_role text;
  v_statut text;
begin
  select etablissement_id, role, statut
  into v_etablissement_id, v_role, v_statut
  from public.membres_etablissement
  where id = p_membre_id
  for update;

  if v_etablissement_id is null then
    raise exception 'Membre introuvable.';
  end if;

  if not public.peut_gerer_membres(v_etablissement_id) then
    raise exception
      'Seuls le directeur et les adjoints peuvent revoquer quelqu''un.';
  end if;

  if v_statut = 'revoque' then
    return;
  end if;

  if v_role in ('directeur', 'adjoint')
     and public.nombre_gestionnaires_actifs(v_etablissement_id) <= 1 then
    raise exception
      'Impossible : ce serait le dernier directeur ou adjoint de '
      'l''etablissement. Nommez d''abord quelqu''un d''autre.';
  end if;

  update public.membres_etablissement
  set statut = 'revoque',
      revoque_par = auth.uid(),
      revoque_le = now()
  where id = p_membre_id;
end;
$function$;

-- ---------------------------------------------------------------------
-- TACHES PLANIFIEES pg_cron (NON VERIFIABLE - voir ci-dessous)
-- ---------------------------------------------------------------------
-- Lecture impossible : permission denied for schema cron
