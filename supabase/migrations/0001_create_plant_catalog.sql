-- Universal plant catalog: facts that don't change with region.
-- One row per (species) or (species, variety). variety_slug NULL = generic species row.
-- Named `plant_catalog` to avoid colliding with a pre-existing `plants` table in this project.

CREATE TABLE IF NOT EXISTS plant_catalog (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- identity & lookup
    species_slug          TEXT NOT NULL,
    variety_slug          TEXT,
    common_name           TEXT NOT NULL,
    scientific_name       TEXT,
    aliases               TEXT[] NOT NULL DEFAULT '{}',

    -- classification
    type                  TEXT,                 -- vegetable|herb|flower|fruit|shrub|tuber|succulent|vine
    lifecycle             TEXT,                 -- annual|biennial|perennial
    indoor_outdoor        TEXT,                 -- indoor|outdoor|both

    -- description
    description           TEXT,

    -- biological needs (stable across regions)
    sun_requirements      TEXT,
    soil_requirements     JSONB,                -- {ph_min, ph_max, type, drainage, notes}
    temperature_range     JSONB,                -- {min_f, max_f, ideal_min, ideal_max}
    humidity_range        TEXT,
    water_general         TEXT,
    fertilizer_general    TEXT,

    -- plant facts
    mature_size           JSONB,                -- {height_inches, spread_inches}
    days_to_harvest       JSONB,                -- {min, max}
    yield_per_plant       TEXT,
    propagation_methods   TEXT[],

    -- universal care plan (WHAT tasks; frequency lives on the regional variant)
    care_plan             JSONB,                -- {items: [{title, description, icon_name, is_critical}]}

    -- relationships & varieties
    companion_plants      TEXT[],
    avoid_planting_with   TEXT[],
    sub_varieties         TEXT[],

    -- safety
    edible                BOOLEAN,
    toxic_to_pets         BOOLEAN,
    toxic_to_humans       BOOLEAN,

    -- presentation
    icon_name             TEXT,
    image_url             TEXT,

    -- provenance / cache hygiene
    source                TEXT NOT NULL DEFAULT 'llm',  -- llm|seed|verified
    llm_model             TEXT,
    prompt_version        TEXT,
    generated_at          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Null-safe uniqueness via NULLS NOT DISTINCT (Postgres 15+).
-- Two ('tomato', NULL) rows are treated as equal, so the unique constraint
-- correctly prevents duplicates of the generic species row.
-- Required as a plain column-list index (not expression-based) so supabase-py's
-- `.upsert(on_conflict="species_slug,variety_slug")` can reference it.
CREATE UNIQUE INDEX IF NOT EXISTS plant_catalog_species_variety_uq
    ON plant_catalog (species_slug, variety_slug) NULLS NOT DISTINCT;

-- Fast alias lookup for the slugify-then-match flow.
CREATE INDEX IF NOT EXISTS plant_catalog_aliases_gin
    ON plant_catalog USING GIN (aliases);

-- updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS plant_catalog_set_updated_at ON plant_catalog;
CREATE TRIGGER plant_catalog_set_updated_at
    BEFORE UPDATE ON plant_catalog
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: tables are private; only FastAPI service-role key reads/writes.
ALTER TABLE plant_catalog ENABLE ROW LEVEL SECURITY;
-- No policies = no anon access. Service role bypasses RLS.

COMMENT ON TABLE plant_catalog IS 'Universal plant catalog. Rows are LLM-generated and cached; (species_slug, variety_slug) is the natural key.';
COMMENT ON COLUMN plant_catalog.source IS 'llm = generated; seed = bootstrapped from MockData; verified = hand-curated, do not regenerate.';
COMMENT ON COLUMN plant_catalog.aliases IS 'Search aliases like ["tomato","tomatoes","love-apple"]. Hit via GIN: WHERE $1 = ANY(aliases).';
