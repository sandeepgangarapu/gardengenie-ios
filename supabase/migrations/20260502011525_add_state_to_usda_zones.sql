-- Add a state column to usda_zones so iOS can resolve (zone, state) from a single
-- zip-code lookup during onboarding. The state is needed by the plant_regional_variants
-- cache key in the FastAPI service.
--
-- Backfill is performed separately by backend-ios/scripts/backfill_usda_zones_state.py
-- using the uszipcode library. After backfill, we'll add NOT NULL.

ALTER TABLE usda_zones
    ADD COLUMN IF NOT EXISTS state CHAR(2);

-- Helpful index for any queries that filter by state alone
CREATE INDEX IF NOT EXISTS usda_zones_state_idx ON usda_zones (state);

COMMENT ON COLUMN usda_zones.state IS 'ISO 2-letter US state code (CA, NY, TX, ...). Backfilled from zip_code via uszipcode lib.';
