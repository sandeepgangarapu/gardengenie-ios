-- Split plant_catalog.planting_guide into method-keyed slots so the iOS planting
-- card can render method-appropriate instructions (transplant vs direct sow)
-- without depending on universal advice that's wrong in cool climates.
--
-- Old shape: {method, depth, spacing, instructions[], notes}
-- New shape: {direct_sow?: {depth, spacing, instructions[], notes},
--             transplant?: {depth, spacing, instructions[], notes}}
--
-- All existing rows get wrapped into the direct_sow slot since the current LLM
-- prompt produces direct-sow-shaped instructions by default. Transplant slots
-- are populated separately by re-running the catalog generator on plants where
-- transplant is biologically valid (warm-season fruiting crops, brassicas, etc.).

UPDATE plant_catalog
SET planting_guide = jsonb_build_object(
    'direct_sow', planting_guide - 'method'
)
WHERE planting_guide IS NOT NULL
  AND planting_guide ? 'instructions';   -- old flat shape detector

COMMENT ON COLUMN plant_catalog.planting_guide IS
    '{direct_sow?: {depth, spacing, instructions[], notes}, transplant?: same}. '
    'Stores only the methods that biologically apply. Variant''s window choice '
    '(transplantWindow vs directSowWindow) selects which slot the iOS view renders.';
