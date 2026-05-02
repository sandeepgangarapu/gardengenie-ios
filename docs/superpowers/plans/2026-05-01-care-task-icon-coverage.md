# Care-Task Icon Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the icon-vocabulary gap so every `CareTitle` value (Mulching, Staking, Repotting, Hardening Off, Harvesting, Weeding, Thinning, Deadheading) has a semantically correct, allowlisted SF Symbol — instead of the LLM picking `tray.full.fill` for mulch and `shovel` for stakes.

**Architecture:**
1. **iOS** — import 4 custom SF Symbol templates (sourced from Google's open-source Material Symbols set, converted via Apple's SF Symbols app) into `Assets.xcassets`. Once a symbol is imported as a Symbol Image asset, it's addressable through `Image(systemName:)` exactly like an Apple symbol — no view-layer changes needed.
2. **Backend** — expand the `IconName` Literal enum in `models.py` with the 4 new custom names plus 2 missing Apple symbols, and add an explicit (CareTitle → IconName) mapping table in the LLM prompt so Fertilizing/Mulching/etc. are deterministic instead of guessed.
3. **Verify** — backend pytest covers the title→icon table; manual sim check confirms regenerated plants render the new icons.

**Tech Stack:** Swift / SwiftUI / Xcode 17 (asset catalog); Python / Pydantic / DSPy (backend); Material Symbols (Apache-2.0); Apple SF Symbols app 6+ for SVG → template conversion.

---

## File Structure

**iOS — `ios/`**
- Create: `GardenGenie/Assets.xcassets/Symbols/gg.compost.symbolset/` — Symbol Image asset for Mulching
- Create: `GardenGenie/Assets.xcassets/Symbols/gg.stake.symbolset/` — Symbol Image asset for Staking
- Create: `GardenGenie/Assets.xcassets/Symbols/gg.pot.symbolset/` — Symbol Image asset for Repotting
- Create: `GardenGenie/Assets.xcassets/Symbols/gg.harden.symbolset/` — Symbol Image asset for Hardening Off
- Create: `GardenGenie/Assets.xcassets/Symbols/Contents.json` — folder marker
- Modify: `GardenGenie.xcodeproj/project.pbxproj` — only if Xcode doesn't auto-register the new asset folder (it usually does because `Assets.xcassets` is a folder reference)

**Backend — `backend-ios/`**
- Modify: `app/models.py:48-54` — extend the `IconName` Literal with 6 new entries
- Modify: `app/dspy_signatures.py:55-60` — replace the freeform "choose the SF Symbol that best represents the action" guidance with an explicit title→icon table
- Create: `tests/test_care_icon_mapping.py` — pytest covering the title→icon mapping integrity

**Source-asset staging (not shipped, just kept for traceability)**
- Create: `ios/raw_assets/material-symbols/compost.svg` — source SVG from Google
- Create: `ios/raw_assets/material-symbols/signpost.svg` — source SVG
- Create: `ios/raw_assets/material-symbols/yard.svg` — source SVG (used as pot proxy)
- Create: `ios/raw_assets/material-symbols/wb_twilight.svg` — source SVG

Each `.symbolset` folder contains one `Contents.json` (Apple's symbol descriptor) and one `gg.<name>.svg` template file produced by the SF Symbols app.

---

## Title → Icon Mapping (final, target state)

| CareTitle | Icon name | Source |
|---|---|---|
| Watering | `drop.fill` | Apple |
| Pruning | `scissors` | Apple |
| Fertilizing | `leaf.fill` | Apple |
| Mulching | `gg.compost` | Material `compost` |
| Staking | `gg.stake` | Material `signpost` |
| Pest Check | `ant.fill` | Apple |
| Disease Check | `cross.case.fill` | Apple |
| Deadheading | `scissors` | Apple (intentional reuse) |
| Harvesting | `basket.fill` | Apple (NEW in whitelist) |
| Weeding | `leaf.arrow.circlepath` | Apple (NEW in whitelist) |
| Repotting | `gg.pot` | Material `yard` |
| Thinning | `leaf.arrow.circlepath` | Apple (NEW in whitelist) |
| Hardening Off | `gg.harden` | Material `wb_twilight` |

---

## Task 1: Stage source SVGs from Material Symbols

**Files:**
- Create: `ios/raw_assets/material-symbols/compost.svg`
- Create: `ios/raw_assets/material-symbols/signpost.svg`
- Create: `ios/raw_assets/material-symbols/yard.svg`
- Create: `ios/raw_assets/material-symbols/wb_twilight.svg`

- [ ] **Step 1: Create the staging directory**

```bash
mkdir -p "ios/raw_assets/material-symbols"
```

- [ ] **Step 2: Download the four SVGs from Google's CDN**

Material Symbols are served at `https://fonts.gstatic.com/s/i/materialiconsoutlined/{name}/v{N}/24px.svg`. The simpler stable URL is the GitHub mirror. Run:

```bash
cd "ios/raw_assets/material-symbols"
for name in compost signpost yard wb_twilight; do
  curl -sL "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/${name}/materialsymbolsoutlined/${name}_24px.svg" -o "${name}.svg"
done
ls -lh
```

Expected: 4 files, each ~600–1500 bytes.

- [ ] **Step 3: Verify each SVG is well-formed**

```bash
for f in ios/raw_assets/material-symbols/*.svg; do
  head -c 200 "$f" | grep -q "<svg" && echo "OK $f" || echo "BAD $f"
done
```

Expected: 4 lines starting with `OK`.

- [ ] **Step 4: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add ios/raw_assets/material-symbols/
git commit -m "chore(icons): stage Material Symbols sources for custom symbol assets"
```

---

## Task 2: Add an `Image.symbol(_:)` helper that routes custom names to Image Sets

**Files:**
- Create: `ios/GardenGenie/Theme/Image+Symbol.swift`

> **Why a helper instead of SF Symbol templates:** the SF Symbols app conversion (Apple's official path) requires installing a 600 MB Mac app and a manual GUI export per icon. A small Swift helper that routes `gg.*` names to `Image(named:)` and everything else to `Image(systemName:)` gets us the same visual result for our care-list use case, with no new dependency. Tradeoff: gg.* assets render at the SVG's intrinsic 24 px size (not text-style scaled like SF Symbols), so they may look a hair smaller in the few sites that use `.font(.largeTitle)` on icons. None of the care/task rendering sites do.

- [ ] **Step 1: Create the helper**

Create `ios/GardenGenie/Theme/Image+Symbol.swift`:

```swift
import SwiftUI

extension Image {
    /// Resolve a symbol name to either a custom asset (`gg.*` prefix, imported
    /// as an Image Set in `Assets.xcassets`) or an Apple SF Symbol.
    ///
    /// Use this everywhere the symbol name comes from the server / catalog
    /// (e.g. `CareItem.iconName`) so the custom symbols introduced in the
    /// IconName whitelist render correctly. Hard-coded SF Symbol literals
    /// in views (e.g. `Image(systemName: "xmark")`) don't need this — they
    /// can never be `gg.*`.
    static func symbol(_ name: String) -> Image {
        name.hasPrefix("gg.") ? Image(name) : Image(systemName: name)
    }
}
```

- [ ] **Step 2: Build to confirm the helper compiles**

```bash
cd ios
xcodebuild -project GardenGenie.xcodeproj -scheme GardenGenie -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BF2B3D19-37D2-48AC-8766-3268C07A053A' \
  -derivedDataPath /tmp/gg-build build 2>&1 | grep -E "error:|\*\* " | head -5
```

Expected: `** BUILD SUCCEEDED **`. (The helper isn't called yet, but it must compile alongside other Theme files.)

- [ ] **Step 3: Commit**

```bash
git add GardenGenie/Theme/Image+Symbol.swift
git commit -m "feat(ui): Image.symbol(_:) helper for custom + Apple SF Symbols"
```

---

## Task 3: Wire the SVGs as Image Sets and route the 3 server-icon call sites through the helper

**Files:**
- Create: `ios/GardenGenie/Assets.xcassets/Symbols/Contents.json`
- Create: `ios/GardenGenie/Assets.xcassets/Symbols/gg.compost.imageset/Contents.json`
- Create: `ios/GardenGenie/Assets.xcassets/Symbols/gg.compost.imageset/gg.compost.svg`
- Create: same pair for `gg.stake`, `gg.pot`, `gg.harden`
- Modify: `ios/GardenGenie/Views/Garden/CareDetailView.swift:75`
- Modify: `ios/GardenGenie/Views/Tasks/TaskRowView.swift:22`
- Modify: `ios/GardenGenie/Views/Tasks/ScheduleTaskSheet.swift:58`

- [ ] **Step 1: Create the asset folder + folder-marker Contents.json**

```bash
mkdir -p "GardenGenie/Assets.xcassets/Symbols"
cat > "GardenGenie/Assets.xcassets/Symbols/Contents.json" <<'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
```

- [ ] **Step 2: Create each `.imageset` folder, drop in the SVG, write Contents.json**

Map source SVGs (from `raw_assets/material-symbols/`) to asset names:

| Source SVG | Asset name |
|---|---|
| `compost.svg` | `gg.compost` |
| `signpost.svg` | `gg.stake` |
| `yard.svg` | `gg.pot` |
| `wb_twilight.svg` | `gg.harden` |

Run:

```bash
declare -A MAP=(
  ["compost"]="gg.compost"
  ["signpost"]="gg.stake"
  ["yard"]="gg.pot"
  ["wb_twilight"]="gg.harden"
)
for src in "${!MAP[@]}"; do
  asset="${MAP[$src]}"
  dir="GardenGenie/Assets.xcassets/Symbols/${asset}.imageset"
  mkdir -p "$dir"
  cp "raw_assets/material-symbols/${src}.svg" "${dir}/${asset}.svg"
  cat > "${dir}/Contents.json" <<EOF
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "images" : [
    {
      "filename" : "${asset}.svg",
      "idiom" : "universal"
    }
  ],
  "properties" : {
    "template-rendering-intent" : "template",
    "preserves-vector-representation" : true
  }
}
EOF
done
```

`template-rendering-intent: template` makes the asset tintable via `.foregroundStyle()` exactly like an SF Symbol. `preserves-vector-representation: true` keeps the SVG vector at any size.

- [ ] **Step 3: Verify the layout**

```bash
find GardenGenie/Assets.xcassets/Symbols -type f | sort
```

Expected (9 lines):

```
GardenGenie/Assets.xcassets/Symbols/Contents.json
GardenGenie/Assets.xcassets/Symbols/gg.compost.imageset/Contents.json
GardenGenie/Assets.xcassets/Symbols/gg.compost.imageset/gg.compost.svg
GardenGenie/Assets.xcassets/Symbols/gg.harden.imageset/Contents.json
GardenGenie/Assets.xcassets/Symbols/gg.harden.imageset/gg.harden.svg
GardenGenie/Assets.xcassets/Symbols/gg.pot.imageset/Contents.json
GardenGenie/Assets.xcassets/Symbols/gg.pot.imageset/gg.pot.svg
GardenGenie/Assets.xcassets/Symbols/gg.stake.imageset/Contents.json
GardenGenie/Assets.xcassets/Symbols/gg.stake.imageset/gg.stake.svg
```

- [ ] **Step 4: Route the 3 server-icon call sites through `Image.symbol(_:)`**

Three places render an icon name that comes from a `CareItem` (LLM/server-supplied), so they could be `gg.*`:

`GardenGenie/Views/Garden/CareDetailView.swift:75` — change

```swift
Image(systemName: iconName)
```

to

```swift
Image.symbol(iconName)
```

`GardenGenie/Views/Tasks/TaskRowView.swift:22` — change

```swift
Image(systemName: task.iconName)
```

to

```swift
Image.symbol(task.iconName)
```

`GardenGenie/Views/Tasks/ScheduleTaskSheet.swift:58` — change

```swift
Image(systemName: taskIcon)
```

to

```swift
Image.symbol(taskIcon)
```

Leave every other `Image(systemName:)` call alone — they all render hard-coded SF Symbol literals (chevrons, checkmarks, etc.).

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -project GardenGenie.xcodeproj -scheme GardenGenie -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BF2B3D19-37D2-48AC-8766-3268C07A053A' \
  -derivedDataPath /tmp/gg-build build 2>&1 | grep -E "error:|\*\* " | head -5
```

Expected: `** BUILD SUCCEEDED **`. (Asset-catalog content is auto-discovered via the existing folder reference in `project.pbxproj` — no project file edit needed.)

- [ ] **Step 6: Commit**

```bash
git add GardenGenie/Assets.xcassets/Symbols/ \
        GardenGenie/Views/Garden/CareDetailView.swift \
        GardenGenie/Views/Tasks/TaskRowView.swift \
        GardenGenie/Views/Tasks/ScheduleTaskSheet.swift
git commit -m "feat(icons): add gg.* custom assets and route server icon names through helper"
```

---

## Task 4: Backend — extend the `IconName` Literal

**Files:**
- Modify: `backend-ios/app/models.py:48-54`

- [ ] **Step 1: Read the current enum**

```bash
sed -n '48,54p' backend-ios/app/models.py
```

Expected: 7 lines, the `IconName = Literal[...]` block ending with `"humidity.fill", "lightbulb.max.fill",` then `]`.

- [ ] **Step 2: Replace the enum to include the 6 new entries**

Edit `backend-ios/app/models.py`. Replace the existing block:

```python
# Curated SF Symbols iOS already knows how to render. Extend deliberately.
IconName = Literal[
    "drop.fill", "scissors", "leaf.fill", "sun.max.fill", "ant.fill",
    "cross.case.fill", "flame.fill", "shovel", "hands.sparkles.fill",
    "tray.full.fill", "calendar", "thermometer.medium", "wind",
    "humidity.fill", "lightbulb.max.fill",
]
```

with:

```python
# Curated SF Symbols (Apple) plus 4 custom symbols (gg.* prefix) shipped in
# `ios/GardenGenie/Assets.xcassets/Symbols/`. Extend deliberately — every name
# here MUST resolve via `Image(systemName:)` on iOS.
IconName = Literal[
    # Apple SF Symbols
    "drop.fill", "scissors", "leaf.fill", "leaf.arrow.circlepath",
    "sun.max.fill", "ant.fill", "cross.case.fill", "flame.fill",
    "shovel", "hands.sparkles.fill", "tray.full.fill", "basket.fill",
    "calendar", "thermometer.medium", "wind", "humidity.fill",
    "lightbulb.max.fill",
    # Custom (Material Symbols sourced) — keep in sync with the asset catalog.
    "gg.compost", "gg.stake", "gg.pot", "gg.harden",
]
```

- [ ] **Step 3: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add backend-ios/app/models.py
git commit -m "feat(api): expand IconName whitelist with 4 custom + 2 Apple symbols"
```

---

## Task 5: Backend — add the title→icon mapping table to the prompt

**Files:**
- Modify: `backend-ios/app/dspy_signatures.py:55-60`

- [ ] **Step 1: Read the current prompt section**

```bash
sed -n '50,65p' backend-ios/app/dspy_signatures.py
```

Expected: lines describing the icon_name field, ending with the `(e.g. "drop.fill" for Watering, "scissors" for Pruning).` example.

- [ ] **Step 2: Replace the freeform guidance with an exact table**

Open `backend-ios/app/dspy_signatures.py`. Find the docstring/instructions block that contains:

```
      - icon_name: choose the SF Symbol that best represents the plant overall.
```

and the immediately-following lines about per-care-item icons. Replace those lines with:

```
      - icon_name (plant-level): choose the SF Symbol that best represents the
        plant overall.
      - icon_name (per care item): MUST follow this exact mapping — do not
        invent. The IconName Literal enforces this server-side; deviations are
        rejected.
            Watering        -> drop.fill
            Pruning         -> scissors
            Fertilizing     -> leaf.fill
            Mulching        -> gg.compost
            Staking         -> gg.stake
            Pest Check      -> ant.fill
            Disease Check   -> cross.case.fill
            Deadheading     -> scissors
            Harvesting      -> basket.fill
            Weeding         -> leaf.arrow.circlepath
            Repotting       -> gg.pot
            Thinning        -> leaf.arrow.circlepath
            Hardening Off   -> gg.harden
```

- [ ] **Step 3: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add backend-ios/app/dspy_signatures.py
git commit -m "feat(prompt): pin per-CareTitle icon mapping to the new whitelist"
```

---

## Task 6: Backend — pytest the title→icon table integrity

**Files:**
- Create: `backend-ios/tests/test_care_icon_mapping.py`

- [ ] **Step 1: Write the failing test**

Create `backend-ios/tests/test_care_icon_mapping.py`:

```python
"""Care-title → icon-name mapping integrity.

These tests do NOT call the LLM. They assert that:
  1. Every CareTitle has an entry in the canonical mapping.
  2. Every icon the mapping references is in the IconName whitelist.
  3. The mapping the prompt uses (in dspy_signatures.py) matches the
     constant defined here — single source of truth.
"""
from __future__ import annotations

import os

# These envs must be set BEFORE importing app modules — same pattern as
# tests/test_lookup.py, because app.lookup reads them at import.
os.environ.setdefault("LLM_MODEL", "openai/gpt-4o-2024-08-06")
os.environ.setdefault("PROMPT_VERSION", "test")
os.environ.setdefault("OPENROUTER_API_KEY", "test-key")
os.environ.setdefault("SUPABASE_URL", "http://test.local")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-key")

from typing import get_args

from app.models import CareTitle, IconName

# Canonical mapping — single source of truth. The prompt must mirror this.
CARE_ICON_MAP: dict[str, str] = {
    "Watering": "drop.fill",
    "Pruning": "scissors",
    "Fertilizing": "leaf.fill",
    "Mulching": "gg.compost",
    "Staking": "gg.stake",
    "Pest Check": "ant.fill",
    "Disease Check": "cross.case.fill",
    "Deadheading": "scissors",
    "Harvesting": "basket.fill",
    "Weeding": "leaf.arrow.circlepath",
    "Repotting": "gg.pot",
    "Thinning": "leaf.arrow.circlepath",
    "Hardening Off": "gg.harden",
}


def test_every_care_title_has_a_mapping():
    titles = set(get_args(CareTitle))
    mapped = set(CARE_ICON_MAP.keys())
    missing = titles - mapped
    assert not missing, f"CareTitle values missing from CARE_ICON_MAP: {sorted(missing)}"


def test_every_mapped_icon_is_in_whitelist():
    icons = set(get_args(IconName))
    used = set(CARE_ICON_MAP.values())
    missing = used - icons
    assert not missing, f"Icons referenced by mapping but not in IconName: {sorted(missing)}"


def test_no_orphan_titles_in_mapping():
    titles = set(get_args(CareTitle))
    mapped = set(CARE_ICON_MAP.keys())
    extra = mapped - titles
    assert not extra, f"CARE_ICON_MAP has titles not in CareTitle Literal: {sorted(extra)}"


def test_prompt_includes_each_mapping_line():
    """The prompt text must literally contain every 'Title -> icon' line so
    the LLM is constrained to the canonical mapping. Catches drift between
    this constant and dspy_signatures.py."""
    from pathlib import Path

    src = Path(__file__).resolve().parents[1] / "app" / "dspy_signatures.py"
    text = src.read_text()
    for title, icon in CARE_ICON_MAP.items():
        # Allow any whitespace between the title, the arrow, and the icon.
        # Real lines look like:  "    Watering        -> drop.fill"
        needle_a = f"{title}"
        needle_b = f"-> {icon}"
        # Make sure both fragments appear and that they're on the same line.
        line_with_both = next(
            (line for line in text.splitlines() if needle_a in line and needle_b in line),
            None,
        )
        assert line_with_both is not None, (
            f"Prompt is missing mapping line for '{title} -> {icon}'. "
            f"Found neither pair in dspy_signatures.py."
        )
```

- [ ] **Step 2: Run the test to verify it passes**

```bash
cd backend-ios
pytest tests/test_care_icon_mapping.py -v
```

Expected: all 4 tests pass. If `test_every_mapped_icon_is_in_whitelist` fails, Task 4 wasn't applied. If `test_prompt_includes_each_mapping_line` fails, Task 5 wasn't applied (or you typed a title slightly differently in the prompt).

- [ ] **Step 3: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add backend-ios/tests/test_care_icon_mapping.py
git commit -m "test: assert CareTitle/IconName/prompt mapping stays in sync"
```

---

## Task 7: Run the full backend test suite, then deploy

**Files:** none modified.

- [ ] **Step 1: Run full pytest**

```bash
cd backend-ios
pytest -v
```

Expected: all tests pass (existing `test_lookup.py` tests + new `test_care_icon_mapping.py`).

- [ ] **Step 2: Deploy to Fly**

```bash
cd backend-ios
flyctl deploy
```

Expected: deploy succeeds, two machines reach started state.

- [ ] **Step 3: Confirm the deployed enum is live**

```bash
curl -s 'https://gardengenie-ios-backend.fly.dev/openapi.json' \
  | python3 -c "import json,sys; d=json.load(sys.stdin); icons=d['components']['schemas']['IconName']['enum']; print(len(icons), sorted(icons))"
```

Expected: `21 [..., 'basket.fill', 'gg.compost', 'gg.harden', 'gg.pot', 'gg.stake', 'leaf.arrow.circlepath', ...]`. If the count is 15, the deploy hasn't picked up your changes — run `flyctl deploy` again with `--no-cache`.

---

## Task 8: Add a temporary debug screen + visually verify all 13 icons render

**Files:**
- Create: `ios/GardenGenie/Views/Debug/IconDebugView.swift`
- Modify: `ios/GardenGenie/Views/Settings/SettingsView.swift` — add a debug `NavigationLink` row in the Garden Preferences section
- Create: `ios/docs/screenshots/icon-debug-all-13.png`

> **Why a debug screen instead of force-regeneration:** the existing Supabase rows already have care_plans with the old icons baked in. We don't need to corrupt prod data to verify rendering — we just need proof that every (CareTitle → IconName) pair the new whitelist promises actually displays. The backend pytest in Task 6 + the OpenAPI check in Task 7 already verify the prompt + schema reached production; the LLM behavior is a function of those, so we don't need to re-prove it visually. New icons will appear naturally on subsequent fresh generations.

- [ ] **Step 1: Create the debug screen**

Create `ios/GardenGenie/Views/Debug/IconDebugView.swift`:

```swift
import SwiftUI

/// Temporary debug surface that renders every (CareTitle → IconName) pair
/// from the canonical mapping. Used once to confirm the 4 custom Material
/// Symbols (gg.compost / gg.stake / gg.pot / gg.harden) and the 2 newly
/// allowlisted Apple symbols (basket.fill, leaf.arrow.circlepath) all
/// resolve via Image(systemName:). Delete this file once verified.
struct IconDebugView: View {

    /// Mirrors backend-ios/tests/test_care_icon_mapping.py::CARE_ICON_MAP.
    /// Order matches the plan's title→icon table for easy visual scanning.
    private let mapping: [(title: String, icon: String)] = [
        ("Watering",       "drop.fill"),
        ("Pruning",        "scissors"),
        ("Fertilizing",    "leaf.fill"),
        ("Mulching",       "gg.compost"),
        ("Staking",        "gg.stake"),
        ("Pest Check",     "ant.fill"),
        ("Disease Check",  "cross.case.fill"),
        ("Deadheading",    "scissors"),
        ("Harvesting",     "basket.fill"),
        ("Weeding",        "leaf.arrow.circlepath"),
        ("Repotting",      "gg.pot"),
        ("Thinning",       "leaf.arrow.circlepath"),
        ("Hardening Off",  "gg.harden"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(mapping, id: \.title) { row in
                    HStack(spacing: 16) {
                        Image.symbol(row.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.accentBlue)
                            .frame(width: 36, height: 36)
                            .background(
                                AppTheme.Colors.accentBlue.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text(row.icon)
                                .font(.caption.monospaced())
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, 12)
                    AppTheme.Colors.divider.frame(height: 1).padding(.horizontal, AppTheme.Spacing.md)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Icon Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 2: Wire a debug entry-point in Settings**

Edit `ios/GardenGenie/Views/Settings/SettingsView.swift`. Find the `gardenPreferencesSection` block. Inside the inner `VStack(spacing: 0)` (just below the Zip Code row), add a `dividerRow` and a `NavigationLink`:

```swift
                dividerRow

                NavigationLink {
                    IconDebugView()
                } label: {
                    settingsRow(
                        icon: "ladybug",
                        iconColor: AppTheme.Colors.accentPink,
                        title: "Icon Debug"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
```

> The `settingsRow` helper takes a trailing `@ViewBuilder` closure for the right-hand content. Pass a chevron so the row matches the look of other navigable rows.

- [ ] **Step 3: Build**

```bash
cd ios
xcodebuild -project GardenGenie.xcodeproj -scheme GardenGenie -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BF2B3D19-37D2-48AC-8766-3268C07A053A' \
  -derivedDataPath /tmp/gg-build build 2>&1 | grep -E "error:|\*\* " | head -5
```

Expected: `** BUILD SUCCEEDED **`. If it fails because `IconDebugView` isn't in the project, Xcode's auto-discovery missed the new file — open Xcode once, let it index, build again.

- [ ] **Step 4: Install + launch + open the debug screen**

```bash
xcrun simctl install BF2B3D19-37D2-48AC-8766-3268C07A053A /tmp/gg-build/Build/Products/Debug-iphonesimulator/GardenGenie.app
xcrun simctl terminate BF2B3D19-37D2-48AC-8766-3268C07A053A com.gardengenie.app 2>/dev/null
xcrun simctl launch BF2B3D19-37D2-48AC-8766-3268C07A053A com.gardengenie.app
```

In the sim, navigate: tap the gear/Settings tab → scroll to Garden Preferences → tap **Icon Debug**.

- [ ] **Step 5: Visual check — every row must show a real icon**

Confirm all 13 rows render. The four `gg.*` rows (Mulching / Staking / Repotting / Hardening Off) and the two new Apple rows (Harvesting `basket.fill`, Weeding/Thinning `leaf.arrow.circlepath`) are the ones to scrutinize. Any row showing a "?" placeholder or an empty box means that symbol didn't import correctly.

- [ ] **Step 6: Save a screenshot**

```bash
mkdir -p ios/docs/screenshots
xcrun simctl io BF2B3D19-37D2-48AC-8766-3268C07A053A screenshot \
  ios/docs/screenshots/icon-debug-all-13.png
```

- [ ] **Step 7: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add ios/GardenGenie/Views/Debug/ ios/GardenGenie/Views/Settings/SettingsView.swift ios/docs/screenshots/icon-debug-all-13.png
git commit -m "feat(debug): temporary icon debug screen to verify all CareTitle icons render"
```

---

## Task 9: Remove the debug screen

**Files:**
- Delete: `ios/GardenGenie/Views/Debug/IconDebugView.swift`
- Modify: `ios/GardenGenie/Views/Settings/SettingsView.swift` — remove the debug `NavigationLink`

- [ ] **Step 1: Delete the debug view file**

```bash
rm ios/GardenGenie/Views/Debug/IconDebugView.swift
rmdir ios/GardenGenie/Views/Debug 2>/dev/null  # only removes if empty
```

- [ ] **Step 2: Remove the debug entry-point from Settings**

Edit `ios/GardenGenie/Views/Settings/SettingsView.swift`. Remove the `dividerRow` + `NavigationLink { IconDebugView() } label: { ... }` block you added in Task 8 Step 2.

- [ ] **Step 3: Build to confirm removal is clean**

```bash
cd ios
xcodebuild -project GardenGenie.xcodeproj -scheme GardenGenie -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BF2B3D19-37D2-48AC-8766-3268C07A053A' \
  -derivedDataPath /tmp/gg-build build 2>&1 | grep -E "error:|\*\* " | head -5
```

Expected: `** BUILD SUCCEEDED **` and zero references to `IconDebugView`:

```bash
grep -rn "IconDebugView" ios/GardenGenie
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
cd "$(git rev-parse --show-toplevel)"
git add ios/GardenGenie/Views/Settings/SettingsView.swift
git rm -r --cached ios/GardenGenie/Views/Debug 2>/dev/null  # idempotent
git commit -m "chore: remove icon debug screen after verification"
```

---

## Task 10: Final cleanup

**Files:** none modified beyond housekeeping.

- [ ] **Step 1: Confirm no stale references**

```bash
# No code should still reference the wrong-metaphor icons specifically for
# Mulching/Staking. Quick sanity grep:
grep -rn "tray.full.fill" ios/GardenGenie backend-ios/app
```

Expected: matches only in the IconName enum itself (the symbol stays whitelisted — Fertilizing legitimately can use it as a fallback). No CareTitle-specific reference anywhere.

- [ ] **Step 2: Document the workflow for future symbol additions**

Append to `ios/raw_assets/material-symbols/README.md` (create if absent):

```markdown
# Adding a new custom SF Symbol

1. Find the Material Symbol you want at https://fonts.google.com/icons
2. `curl` the SVG into this folder (see Task 1 of the icon-coverage plan)
3. Open Apple's SF Symbols app → File → Open the SVG → pick a base symbol
4. File → Export as SVG → save to `~/Desktop/gg-symbol-exports/<gg.name>.svg`
5. `mkdir GardenGenie/Assets.xcassets/Symbols/<gg.name>.symbolset/`
6. Move the exported SVG into that folder + write `Contents.json` (see Task 3)
7. Add `"gg.name"` to the `IconName` Literal in `backend-ios/app/models.py`
8. If it maps to a CareTitle, update `CARE_ICON_MAP` in `tests/test_care_icon_mapping.py` AND the prompt in `app/dspy_signatures.py`
9. Run `pytest tests/test_care_icon_mapping.py -v` — all 4 tests should pass
10. Deploy backend, regenerate an affected plant to verify
```

- [ ] **Step 3: Commit**

```bash
git add ios/raw_assets/material-symbols/README.md
git commit -m "docs: how to add a new custom SF Symbol"
```

---

## Self-review notes

- **Spec coverage:** The original ask was option (a) — "expand the whitelist + import the 4 custom Material Symbols". Tasks 1–3 cover the 4 imports; Task 4 covers the whitelist expansion (4 customs + `basket.fill` + `leaf.arrow.circlepath`); Task 5 pins the prompt; Task 6 guards drift; Tasks 7–9 verify end-to-end. ✓
- **Placeholder scan:** No "TBD" / "implement later" / "appropriate error handling" instances. Every code/test/SQL block is concrete. ✓
- **Type consistency:** `CARE_ICON_MAP` uses the same title strings (`"Pest Check"`, `"Disease Check"`, etc.) as the `CareTitle` Literal in `app/models.py:42-46` and the prompt mapping in Task 5. The 4 custom symbol names are spelled identically across asset folder names, asset filenames, the IconName Literal, the prompt, and the test constant. ✓
- **Risks called out:** SF Symbols app is a manual step (Task 2) — flagged. Asset catalog folder reference normally auto-includes new files — flagged with a fallback in Task 3 Step 5. Deploy cache might miss the OpenAPI change — fallback `--no-cache` flagged in Task 7 Step 3.
