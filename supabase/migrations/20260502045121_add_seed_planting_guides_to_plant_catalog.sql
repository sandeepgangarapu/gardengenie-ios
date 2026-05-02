-- Add seed-starting and planting guides to plant_catalog.
-- Universal facts (depth, spacing, soil temp, instructions) — region-specific
-- timing already lives on plant_regional_variants.

ALTER TABLE plant_catalog
    ADD COLUMN IF NOT EXISTS seed_starting_guide JSONB,
    ADD COLUMN IF NOT EXISTS planting_guide      JSONB;

COMMENT ON COLUMN plant_catalog.seed_starting_guide IS
    '{soil_temperature, depth, spacing, instructions[], notes}. NULL for plants not grown from seed.';
COMMENT ON COLUMN plant_catalog.planting_guide IS
    '{method, depth, spacing, instructions[], notes}. NULL only when the plant has no outdoor planting phase.';
