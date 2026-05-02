import Foundation
import SwiftUI

/// A plant from the new universal catalog (`plant_catalog` table).
/// Returned by the FastAPI service alongside a `PlantRegionalVariant`.
///
/// Distinct from the legacy `Plant` struct so we can run both side-by-side
/// during the migration. Fields mirror `backend-ios/app/models.py::Plant`.
struct CatalogPlant: Identifiable, Hashable, Codable {

    // MARK: - Identity & lookup
    let id: UUID
    let speciesSlug: String
    let varietySlug: String?
    let commonName: String
    let scientificName: String?
    let aliases: [String]

    // MARK: - Classification
    let type: String?               // vegetable|herb|flower|fruit|shrub|tuber|succulent|vine
    let lifecycle: String?          // annual|biennial|perennial
    let indoorOutdoor: String?      // indoor|outdoor|both

    // MARK: - Description
    let description: String?

    // MARK: - Biological needs (region-agnostic)
    let sunCategory: String?        // "Full Sun"|"Partial Sun"|"Partial Shade"|"Full Shade"
    let sunRequirements: String?
    let soilRequirements: CatalogSoilRequirements?
    let temperatureRange: CatalogTemperatureRange?
    let humidityRange: String?
    let waterGeneral: String?
    let fertilizerGeneral: String?

    // MARK: - Plant facts
    let matureSize: CatalogMatureSize?
    let daysToHarvest: CatalogDaysToHarvest?
    let yieldPerPlant: String?
    let propagationMethods: [String]

    // MARK: - Care
    let carePlan: CatalogCarePlan?

    // MARK: - Seed starting & planting (universal)
    let seedStartingGuide: CatalogSeedStartingGuide?
    let plantingGuide: CatalogPlantingGuide?

    // MARK: - Relationships & varieties
    let companionPlants: [String]
    let avoidPlantingWith: [String]
    let subVarieties: [String]

    // MARK: - Safety
    let edible: Bool?
    let toxicToPets: Bool?
    let toxicToHumans: Bool?

    // MARK: - Presentation
    let iconName: String?           // SF Symbol from the closed server enum
    let imageURL: String?

    // MARK: - Provenance
    let source: String              // llm|seed|verified
    let llmModel: String?
    let promptVersion: String?
    let generatedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case speciesSlug = "species_slug"
        case varietySlug = "variety_slug"
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case aliases
        case type, lifecycle
        case indoorOutdoor = "indoor_outdoor"
        case description
        case sunCategory = "sun_category"
        case sunRequirements = "sun_requirements"
        case soilRequirements = "soil_requirements"
        case temperatureRange = "temperature_range"
        case humidityRange = "humidity_range"
        case waterGeneral = "water_general"
        case fertilizerGeneral = "fertilizer_general"
        case matureSize = "mature_size"
        case daysToHarvest = "days_to_harvest"
        case yieldPerPlant = "yield_per_plant"
        case propagationMethods = "propagation_methods"
        case carePlan = "care_plan"
        case seedStartingGuide = "seed_starting_guide"
        case plantingGuide = "planting_guide"
        case companionPlants = "companion_plants"
        case avoidPlantingWith = "avoid_planting_with"
        case subVarieties = "sub_varieties"
        case edible
        case toxicToPets = "toxic_to_pets"
        case toxicToHumans = "toxic_to_humans"
        case iconName = "icon_name"
        case imageURL = "image_url"
        case source
        case llmModel = "llm_model"
        case promptVersion = "prompt_version"
        case generatedAt = "generated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Client-only display helpers

    /// Falls back to a type-based icon if the server didn't supply one.
    var displayIconName: String {
        if let iconName, !iconName.isEmpty { return iconName }
        return Plant.icon(for: type)         // reuse legacy mapping
    }

    /// Reuses the legacy color palette by type so cards look consistent
    /// alongside any remaining legacy `Plant` views.
    var accentColor: Color {
        Color(hex: Plant.accentHex(for: type))
    }
}
