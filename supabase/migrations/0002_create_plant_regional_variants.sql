-- Regional plant care: facts that vary by USDA zone + state.
-- One row per (plant_id, usda_zone, state_code). LLM-generated and cached.

CREATE TABLE IF NOT EXISTS plant_regional_variants (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plant_id                    UUID NOT NULL REFERENCES plant_catalog(id) ON DELETE CASCADE,

    -- region key
    usda_zone                   TEXT NOT NULL,           -- e.g. "9b"
    state_code                  CHAR(2) NOT NULL,        -- ISO state, e.g. "CA"

    -- planting calendar (varies with frost dates / season length)
    indoor_seed_start_window    JSONB,                   -- {start_month, end_month, weeks_before_last_frost, notes}
    direct_sow_window           JSONB,
    transplant_window           JSONB,
    harvest_window              JSONB,

    -- climate-conditioned care
    watering_schedule           TEXT,
    frost_protection_notes      TEXT,
    fertilizer_schedule         TEXT,
    -- Regional care schedule. Each item's title MUST match an item in plant_catalog.care_plan
    -- (enforced at generation time via the shared CareTitle Literal in the FastAPI service).
    care_schedule               JSONB,                   -- {items: [{title, frequency, seasonal_notes}]}

    -- regional reality
    regional_pests              JSONB,                   -- [{name, season, prevention, severity}]
    regional_diseases           JSONB,                   -- same shape
    recommended_varieties       TEXT[],
    local_sourcing_notes        TEXT,
    extension_office_url        TEXT,

    -- provenance
    llm_model                   TEXT,
    prompt_version              TEXT,
    generated_at                TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (plant_id, usda_zone, state_code)
);

CREATE INDEX IF NOT EXISTS plant_regional_variants_lookup
    ON plant_regional_variants (plant_id, usda_zone, state_code);

DROP TRIGGER IF EXISTS plant_regional_variants_set_updated_at ON plant_regional_variants;
CREATE TRIGGER plant_regional_variants_set_updated_at
    BEFORE UPDATE ON plant_regional_variants
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: private; only the FastAPI service-role key reads/writes.
ALTER TABLE plant_regional_variants ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE plant_regional_variants IS 'Per-(zone,state) care advice. LLM-generated and cached.';
COMMENT ON COLUMN plant_regional_variants.care_schedule IS 'items[].title must match plant_catalog.care_plan.items[].title; alignment is enforced at generation time, not in the DB.';
