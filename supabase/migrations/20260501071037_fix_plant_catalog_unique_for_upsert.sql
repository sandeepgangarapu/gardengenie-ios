-- Replace the expression-based unique index (COALESCE(variety_slug,'')) with a
-- regular column-list unique index using NULLS NOT DISTINCT (Postgres 15+).
--
-- Why: supabase-py's `.upsert(on_conflict="species_slug,variety_slug")` requires
-- a unique constraint or index on the exact column list. Expression indexes
-- (like the COALESCE one) cannot be referenced this way through PostgREST.
--
-- NULLS NOT DISTINCT preserves the null-safe semantics: ('tomato', NULL) and
-- another ('tomato', NULL) are considered equal, so the unique constraint
-- correctly prevents duplicates of the generic species row.

DROP INDEX IF EXISTS plant_catalog_species_variety_uq;

CREATE UNIQUE INDEX plant_catalog_species_variety_uq
    ON plant_catalog (species_slug, variety_slug) NULLS NOT DISTINCT;
