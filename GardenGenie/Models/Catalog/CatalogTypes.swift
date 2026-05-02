import Foundation

// Shared sub-structs and enums used by CatalogPlant and PlantRegionalVariant.
// These mirror the Pydantic shapes from backend-ios/app/models.py exactly,
// with snake_case → camelCase via CodingKeys.
//
// Closed Literal enums on the server become Swift `String` here (we trust the
// strict-output guarantee server-side and stay forward-compatible if the server
// adds new vocab values later — Swift's String never breaks decoding on new values).

// MARK: - Universal sub-structs (stored in plant_catalog.* JSONB columns)

struct CatalogSoilRequirements: Codable, Hashable {
    let phMin: Double
    let phMax: Double
    let type: String        // "loam" | "sandy" | "clay" | "silt" | "loamy-sand" | "well-drained"
    let drainage: String    // "poor" | "moderate" | "good" | "excellent"
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case phMin = "ph_min"
        case phMax = "ph_max"
        case type, drainage, notes
    }
}

struct CatalogTemperatureRange: Codable, Hashable {
    let minF: Int
    let maxF: Int
    let idealMin: Int
    let idealMax: Int

    enum CodingKeys: String, CodingKey {
        case minF = "min_f"
        case maxF = "max_f"
        case idealMin = "ideal_min"
        case idealMax = "ideal_max"
    }
}

struct CatalogMatureSize: Codable, Hashable {
    let heightInches: Int
    let spreadInches: Int

    enum CodingKeys: String, CodingKey {
        case heightInches = "height_inches"
        case spreadInches = "spread_inches"
    }
}

struct CatalogDaysToHarvest: Codable, Hashable {
    let min: Int
    let max: Int
}

// MARK: - Care plan / schedule
//
// Universal CarePlan = WHAT tasks this plant needs (CatalogCareItem).
// Regional CareSchedule = WHEN/HOW OFTEN those tasks happen (CatalogCareScheduleItem).
// They share `title` so iOS can join them when rendering.

struct CatalogCareItem: Codable, Hashable, Identifiable {
    var id: String { title }   // titles are unique within a plant (server-enforced via Literal enum)
    let title: String
    let description: String
    let iconName: String       // SF Symbol name from the closed server enum
    let isCritical: Bool

    enum CodingKeys: String, CodingKey {
        case title, description
        case iconName = "icon_name"
        case isCritical = "is_critical"
    }
}

struct CatalogCarePlan: Codable, Hashable {
    let items: [CatalogCareItem]
}

// MARK: - Seed-starting & planting guides (universal)
//
// Region-specific TIMING for these lives on PlantRegionalVariant
// (indoorSeedStartWindow, transplantWindow, directSowWindow). The instructions
// here are biology, not climate — same advice anywhere.

struct CatalogSeedStartingGuide: Codable, Hashable {
    let soilTemperature: String?
    let depth: String?
    let spacing: String?
    let instructions: [String]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case soilTemperature = "soil_temperature"
        case depth, spacing, instructions, notes
    }
}

struct CatalogPlantingGuide: Codable, Hashable {
    let method: String?
    let depth: String?
    let spacing: String?
    let instructions: [String]
    let notes: String?
}

// MARK: - Regional sub-structs (stored in plant_regional_variants.* JSONB columns)

struct CatalogPlantingWindow: Codable, Hashable {
    let startMonth: Int        // 1–12
    let endMonth: Int          // 1–12
    let weeksBeforeLastFrost: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case startMonth = "start_month"
        case endMonth = "end_month"
        case weeksBeforeLastFrost = "weeks_before_last_frost"
        case notes
    }

    /// Display helper: "Mar – Apr"
    var displayRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let cal = Calendar.current
        guard
            let start = cal.date(from: DateComponents(year: 2000, month: startMonth)),
            let end = cal.date(from: DateComponents(year: 2000, month: endMonth))
        else { return "\(startMonth) – \(endMonth)" }
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}

struct CatalogRegionalPest: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let season: String
    let prevention: String
    let severity: String        // "low" | "moderate" | "high"
}

struct CatalogCareScheduleItem: Codable, Hashable, Identifiable {
    var id: String { title }    // matches a CatalogCareItem.title in the universal plan
    let title: String
    let frequency: String       // "Every 2-3 days", "Weekly"
    let seasonalNotes: String?

    enum CodingKeys: String, CodingKey {
        case title, frequency
        case seasonalNotes = "seasonal_notes"
    }
}

struct CatalogCareSchedule: Codable, Hashable {
    let items: [CatalogCareScheduleItem]
}
