import Foundation

/// Bridges the new catalog data model into the legacy `Plant` shape so that
/// `PlantDetailView`, `CareDetailView`, and `PlantingDetailView` can render
/// a `CatalogPlant` + `PlantRegionalVariant` without any view changes.
///
/// Mapping summary:
///   - Identity / classification: direct
///   - Structured `soilRequirements` / `temperatureRange` / `daysToHarvest`
///     are formatted back into the legacy string fields
///   - `carePlan.items[].is_critical` is split into `mustDo` (true) / `others` (false);
///     frequency is filled in from the regional `careSchedule` matched on title
///   - `seedStartingGuide` + variant.indoor_seed_start_window → `SeedStartingInfo`
///   - `plantingGuide` + variant.transplant_window (or direct_sow_window) → `PlantingInfo`
enum CatalogPlantAdapter {

    static func adapt(_ catalog: CatalogPlant, variant: PlantRegionalVariant?) -> Plant {
        Plant(
            id: catalog.id,
            name: catalog.commonName,
            description: catalog.description,
            type: catalog.type,
            zone: variant?.usdaZone,
            sunRequirements: catalog.sunCategory,
            zoneSuitability: nil,
            seasonality: nil,
            indoorOutdoor: catalog.indoorOutdoor,
            lifecycle: capitalize(catalog.lifecycle),
            soilType: capitalize(catalog.soilRequirements?.type),
            matureHeight: formatInches(catalog.matureSize?.heightInches),
            matureSpread: formatInches(catalog.matureSize?.spreadInches),
            requirements: PlantRequirements(
                soil: formatSoil(catalog.soilRequirements),
                water: catalog.waterGeneral,
                temperature: formatTemperature(catalog.temperatureRange),
                humidity: catalog.humidityRange,
                fertilizer: catalog.fertilizerGeneral
            ),
            seedStarting: adaptSeedStarting(catalog.seedStartingGuide, window: variant?.indoorSeedStartWindow),
            planting: adaptPlanting(catalog.plantingGuide,
                                    window: variant?.transplantWindow ?? variant?.directSowWindow),
            carePlan: adaptCarePlan(catalog.carePlan, schedule: variant?.careSchedule),
            typeSpecific: TypeSpecificInfo(
                daysToHarvest: formatDaysToHarvest(catalog.daysToHarvest),
                companionPlants: catalog.companionPlants.isEmpty ? nil : catalog.companionPlants,
                yield: catalog.yieldPerPlant,
                varieties: chooseVarieties(catalog: catalog, variant: variant)
            )
        )
    }

    // MARK: - Field formatters

    private static func formatSoil(_ s: CatalogSoilRequirements?) -> String? {
        guard let s else { return nil }
        return String(format: "pH %.1f–%.1f", s.phMin, s.phMax)
    }

    private static func formatTemperature(_ t: CatalogTemperatureRange?) -> String? {
        guard let t else { return nil }
        return "\(t.idealMin)–\(t.idealMax)°F"
    }

    private static func formatDaysToHarvest(_ d: CatalogDaysToHarvest?) -> String? {
        guard let d else { return nil }
        return "\(d.min)–\(d.max) days"
    }

    /// "loam" → "Loam"; nil/empty stays nil so the chip is hidden.
    private static func capitalize(_ s: String?) -> String? {
        guard let raw = s?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    /// 8 → "8 in", 36 → "3 ft", 30 → "2.5 ft". Hidden when nil or zero.
    private static func formatInches(_ inches: Int?) -> String? {
        guard let inches, inches > 0 else { return nil }
        if inches < 24 { return "\(inches) in" }
        let feet = Double(inches) / 12.0
        // Drop trailing .0 for whole feet.
        return feet.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(feet)) ft"
            : String(format: "%.1f ft", feet)
    }

    private static func chooseVarieties(catalog: CatalogPlant, variant: PlantRegionalVariant?) -> [String]? {
        // Prefer the regional recommendation; fall back to universal sub-varieties.
        if let v = variant, !v.recommendedVarieties.isEmpty { return v.recommendedVarieties }
        return catalog.subVarieties.isEmpty ? nil : catalog.subVarieties
    }

    // MARK: - Care plan / schedule

    private static func adaptCarePlan(
        _ plan: CatalogCarePlan?,
        schedule: CatalogCareSchedule?
    ) -> CarePlan? {
        guard let plan else { return nil }
        let scheduleByTitle: [String: CatalogCareScheduleItem] =
            Dictionary(uniqueKeysWithValues: (schedule?.items ?? []).map { ($0.title, $0) })

        var mustDo: [CareItem] = []
        var others: [CareItem] = []
        for item in plan.items {
            let frequency = scheduleByTitle[item.title]?.frequency
            let careItem = CareItem(
                title: item.title,
                description: item.description,
                frequency: frequency,
                iconName: item.iconName
            )
            if item.isCritical { mustDo.append(careItem) } else { others.append(careItem) }
        }
        return CarePlan(
            mustDo: mustDo.isEmpty ? nil : mustDo,
            others: others.isEmpty ? nil : others
        )
    }

    // MARK: - Seed starting & planting

    private static func adaptSeedStarting(
        _ guide: CatalogSeedStartingGuide?,
        window: CatalogPlantingWindow?
    ) -> SeedStartingInfo? {
        // Show the section if we have either a guide or a regional window.
        guard guide != nil || window != nil else { return nil }
        return SeedStartingInfo(
            month: window?.displayRange,
            instructions: guide?.instructions.isEmpty == false ? guide?.instructions : nil,
            indoorWeeksBeforeLastFrost: window?.weeksBeforeLastFrost,
            soilTemperature: guide?.soilTemperature,
            depth: guide?.depth,
            spacing: guide?.spacing,
            notes: combineNotes(guide?.notes, window?.notes)
        )
    }

    private static func adaptPlanting(
        _ guide: CatalogPlantingGuide?,
        window: CatalogPlantingWindow?
    ) -> PlantingInfo? {
        guard guide != nil || window != nil else { return nil }
        return PlantingInfo(
            month: window?.displayRange,
            instructions: guide?.instructions.isEmpty == false ? guide?.instructions : nil,
            spacing: guide?.spacing,
            depth: guide?.depth,
            method: guide?.method,
            notes: combineNotes(guide?.notes, window?.notes)
        )
    }

    private static func combineNotes(_ a: String?, _ b: String?) -> String? {
        switch (a, b) {
        case let (a?, b?): return "\(a)\n\n\(b)"
        case let (a?, nil): return a
        case let (nil, b?): return b
        default: return nil
        }
    }
}
