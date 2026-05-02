-- Add sun_category enum column for compact stats display.
-- Closed vocabulary: "Full Sun", "Partial Sun", "Partial Shade", "Full Shade".
-- Existing rows will have NULL until regenerated.

ALTER TABLE plant_catalog
  ADD COLUMN IF NOT EXISTS sun_category TEXT;
