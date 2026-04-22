import Foundation

// MARK: - JSONB Sub-Structs
// These mirror the JSONB columns in the Supabase `plants` table.

/// General growing requirements (soil, water, temperature, etc.).
struct PlantRequirements: Codable, Hashable {
    var soil: String?
    var water: String?
    var temperature: String?
    var humidity: String?
    var fertilizer: String?
}

/// Seed-starting information — when and how to start seeds.
struct SeedStartingInfo: Codable, Hashable {
    var month: String?
    var instructions: [String]?
    var indoorWeeksBeforeLastFrost: Int?
    var soilTemperature: String?
    var depth: String?
    var spacing: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case month, instructions, depth, spacing, notes
        case indoorWeeksBeforeLastFrost = "indoor_weeks_before_last_frost"
        case soilTemperature = "soil_temperature"
    }
}

/// Outdoor planting information — when and how to transplant / direct sow.
struct PlantingInfo: Codable, Hashable {
    var month: String?
    var instructions: [String]?
    var spacing: String?
    var depth: String?
    var method: String?
    var notes: String?
}

/// The plant's care plan, split into critical vs. optional items.
struct CarePlan: Codable, Hashable {
    /// Critical tasks — pruning, watering schedule, etc. Missing these harms plant health.
    var mustDo: [CareItem]?
    /// Nice-to-have tasks that can be added to the user's task list.
    var others: [CareItem]?

    enum CodingKeys: String, CodingKey {
        case mustDo = "must_do"
        case others
    }
}

/// A single care instruction inside a `CarePlan`.
struct CareItem: Codable, Hashable, Identifiable {
    var id: String { title }
    var title: String
    var description: String?
    var frequency: String?
    /// SF Symbol name suggested by the LLM (client can default).
    var iconName: String?

    enum CodingKeys: String, CodingKey {
        case title, description, frequency
        case iconName = "icon_name"
    }
}

/// Type-specific attributes — harvest time, companion plants, yield, etc.
struct TypeSpecificInfo: Codable, Hashable {
    var daysToHarvest: String?
    var companionPlants: [String]?
    var yield: String?
    var varieties: [String]?

    enum CodingKeys: String, CodingKey {
        case yield, varieties
        case daysToHarvest = "days_to_harvest"
        case companionPlants = "companion_plants"
    }
}
