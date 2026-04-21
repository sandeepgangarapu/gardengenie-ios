# GardenGenie

A SwiftUI iOS app for managing your garden — built with Apple's iOS 26 liquid glass design language.

## Features

- **My Garden** — Browse your plants in a responsive grid of cards. Tap any plant for full care details including sunlight, watering, soil, planting season, harvest time, and companion plants.
- **Tasks** — Track garden tasks (watering, pruning, pest checks) grouped into Upcoming and Completed sections.
- **Quick Add** — A floating liquid-glass circle button sits centered in the tab bar for quickly adding new plants or tasks.
- **Profile & Settings** — Accessible from the top-right of My Garden.

## Stack

- **SwiftUI** (iOS 26+)
- **Swift 6** with the `@Observable` macro for MVVM
- **Liquid glass** via `tabViewBottomAccessory` + `.buttonStyle(.glass)`
- **XcodeGen** for project generation from `project.yml`

## Getting Started

```bash
# Regenerate the Xcode project (if project.yml changes)
xcodegen generate

# Open in Xcode
open GardenGenie.xcodeproj
```

Then hit ▶️ in Xcode on an iPhone 17 (or newer) simulator running iOS 26.

## Project Structure

```
GardenGenie/
├── App/              # @main entry point
├── Models/           # Plant, GardenTask
├── ViewModels/       # @Observable view models
├── Views/            # SwiftUI screens and components
├── Theme/            # Design tokens and modifiers
├── Data/             # Mock data
└── Assets.xcassets/  # Colors, icon
```

## Mock Data

Ships with three sample plants — Tomato, Potato, Tulip — and five garden tasks so the UI is fully populated on first launch.
