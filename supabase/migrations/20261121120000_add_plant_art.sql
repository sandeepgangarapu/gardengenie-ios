-- Plant artwork: a transparent cut-out of the plant (image_url) plus the openly
-- licensed photo it came from, with the attribution that license requires.
-- Filled by backend-ios/app/plant_art.py (after /plant-guide, and by
-- scripts/backfill_plant_art.py). Existing rows stay NULL until backfilled.

ALTER TABLE plant_catalog
  ADD COLUMN IF NOT EXISTS photo_url        TEXT,
  ADD COLUMN IF NOT EXISTS photo_credit     TEXT,
  ADD COLUMN IF NOT EXISTS photo_license    TEXT,
  ADD COLUMN IF NOT EXISTS photo_source_url TEXT,
  ADD COLUMN IF NOT EXISTS image_checked_at TIMESTAMPTZ;

COMMENT ON COLUMN plant_catalog.image_url IS 'Transparent PNG cut-out of the plant in the public plant-art bucket; the app draws it on the type-accent gradient. NULL when no photo cut out cleanly.';
COMMENT ON COLUMN plant_catalog.photo_url IS 'Source photo (CC0 / CC BY / CC BY-SA / public domain) the cut-out was made from, or the best photo when none cut out.';
COMMENT ON COLUMN plant_catalog.photo_credit IS 'Attribution line required by the photo license, e.g. "(c) Jane Doe, some rights reserved (CC BY)".';
COMMENT ON COLUMN plant_catalog.photo_license IS 'Display label: CC0, CC BY, CC BY-SA 4.0, Public domain.';
COMMENT ON COLUMN plant_catalog.photo_source_url IS 'Page to link for attribution (iNaturalist observation or Wikimedia Commons file page).';
COMMENT ON COLUMN plant_catalog.image_checked_at IS 'When artwork was last looked for. Set even when nothing was found, so it is not retried on every request.';

-- Public bucket for the cut-outs. Writes use the service-role key (bypasses
-- RLS); public buckets serve reads without a policy.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('plant-art', 'plant-art', true, 5242880, ARRAY['image/png'])
ON CONFLICT (id) DO NOTHING;
