# Custom SF Symbols (gg.* prefix)

This directory holds the source SVGs (Material Symbols, Apache-2.0) for the
custom icons we ship in `GardenGenie/Assets.xcassets/Symbols/`. Symbols here
are referenced by name through `Image.symbol(_:)` and listed in the backend's
`IconName` Literal.

## Adding a new custom symbol

1. Find the icon at https://fonts.google.com/icons (Material Symbols).
2. Download the **Outlined** style 24px SVG into this folder:
   ```bash
   curl -sL -o NAME.svg \
     "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/NAME/materialsymbolsoutlined/NAME_24px.svg"
   ```
3. Create the imageset folder under `GardenGenie/Assets.xcassets/Symbols/`:
   ```bash
   mkdir -p "GardenGenie/Assets.xcassets/Symbols/gg.NAME.imageset"
   cp raw_assets/material-symbols/NAME.svg \
      "GardenGenie/Assets.xcassets/Symbols/gg.NAME.imageset/gg.NAME.svg"
   ```
4. Write the imageset's `Contents.json`:
   ```json
   {
     "info" : { "author" : "xcode", "version" : 1 },
     "images" : [
       { "filename" : "gg.NAME.svg", "idiom" : "universal" }
     ],
     "properties" : {
       "template-rendering-intent" : "template",
       "preserves-vector-representation" : true
     }
   }
   ```
   `template-rendering-intent: template` makes the asset tintable via
   `.foregroundStyle()` exactly like an SF Symbol.
5. Add `"gg.NAME"` to the `IconName` Literal in
   `backend-ios/app/models.py`.
6. If it maps to a `CareTitle`, also update:
   - `CARE_ICON_MAP` in `backend-ios/tests/test_care_icon_mapping.py`
   - The title→icon table in `backend-ios/app/dspy_signatures.py`
7. Run the mapping tests:
   ```bash
   cd backend-ios && uv run pytest tests/test_care_icon_mapping.py -v
   ```
   All four assertions must pass.
8. Render through `Image.symbol(_:)` (defined in
   `GardenGenie/Theme/Image+Symbol.swift`) — the helper routes `gg.*` to the
   asset and everything else to `Image(systemName:)`.
9. Deploy the backend, regenerate an affected plant to verify.

## Why no SF Symbols app step?

Apple's official "import an SVG as an SF Symbol template" workflow requires
the SF Symbols Mac app and a manual GUI export per icon. We bypass it: the
SVGs ship as Image Sets with `template-rendering-intent: template`, and the
`Image.symbol(_:)` helper picks the right initializer at the call site. Same
visual result for our flat icons; no GUI step.
