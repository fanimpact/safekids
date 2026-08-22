-- =====================================================================
-- KidsRelay - Verification : comptes avec un email mais sans identite
--
-- A executer manuellement de temps en temps (ou avant un test de
-- connexion) : liste tout compte qui a un email (confirme ou en
-- attente) mais aucune ligne dans auth.identities pour le provider
-- "email" -- c'est exactement ce qui a empeche plusieurs reconnexions
-- ce soir. Une liste vide = tout est sain.
--
-- Ne modifie rien, lecture seule.
-- =====================================================================

select
  u.id,
  coalesce(nullif(u.email, ''), nullif(u.email_change, '')) as email,
  u.is_anonymous,
  u.created_at
from auth.users u
where coalesce(nullif(u.email, ''), nullif(u.email_change, '')) is not null
  and not exists (
    select 1 from auth.identities i
    where i.user_id = u.id and i.provider = 'email'
  );
