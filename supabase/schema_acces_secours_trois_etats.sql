-- =======================================================================
-- L'accès secours a trois états, pas deux — 28/08/2026
-- =======================================================================
--
-- Une case non cochée ne prouve rien. On ne peut pas distinguer un
-- parent qui a **refusé** d'un parent qui a lu en travers et n'a pas vu
-- la question.
--
-- Or la base légale est l'intérêt vital **renforcé par une
-- préautorisation donnée à froid** : c'est cette préautorisation qui
-- doit pouvoir être démontrée. Un silence ne se démontre pas.
--
-- D'où trois états, et une colonne qui accepte le nul :
--
--   true  — le parent a accepté
--   false — le parent a refusé, explicitement
--   null  — le parent n'a pas encore répondu
--
-- `false` et `null` ont la **même conséquence** — aucun accès secours
-- possible — mais pas la même valeur juridique, et pas le même
-- traitement à l'écran : le premier est une décision, le second une
-- question encore ouverte.

alter table public.enfants
  alter column acces_secours_autorise drop not null,
  alter column acces_secours_autorise drop default;

comment on column public.enfants.acces_secours_autorise is
  'Trois etats : true accepte, false refuse explicitement, null pas '
  'encore repondu. false et null interdisent tous deux l''acces '
  'secours ; seul le premier est une decision demontrable.';

-- Les profils existants n'ont jamais vu la question : leur `false` est
-- un defaut de colonne, pas un refus. Il devient un silence.
--
-- La condition `= false` protege une acceptation reelle, s'il en
-- existait une.
update public.enfants
set acces_secours_autorise = null
where acces_secours_autorise = false;
