import Foundation

/// Region-specific care advice for a plant in a given USDA zone + state.
/// Mirrors `backend-ios/app/models.py::PlantRegionalVariant`.
///
/// `careSchedule.items[].title` is guaranteed (server-side via shared Literal
/// enum) to match a title in the parent `CatalogPlant.carePlan.items[].title`,
/// so iOS can join them without lookup misses.
struct PlantRegionalVariant: Identifiable, Hashable, Codable {

    let id: UUID
    let plantID: UUID

    // Region key
    let usdaZone: String        // "9b"
    let stateCode: String       // "CA"

    // Planting calendar
    let indoorSeedStartWindow: CatalogPlantingWindow?
    let directSowWindow: CatalogPlantingWindow?
    let transplantWindow: CatalogPlantingWindow?
    let harvestWindow: CatalogPlantingWindow?

    // Climate-conditioned care
    let wateringSchedule: String?
    let frostProtectionNotes: String?
    let fertilizerSchedule: String?
    let careSchedule: CatalogCareSchedule?

    // Regional reality
    let regionalPests: [CatalogRegionalPest]
    let regionalDiseases: [CatalogRegionalPest]
    let recommendedVarieties: [String]
    let localSourcingNotes: String?
    let extensionOfficeURL: String?

    // Provenance
    let llmModel: String?
    let promptVersion: String?
    let generatedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case plantID = "plant_id"
        case usdaZone = "usda_zone"
        case stateCode = "state_code"
        case indoorSeedStartWindow = "indoor_seed_start_window"
        case directSowWindow = "direct_sow_window"
        case transplantWindow = "transplant_window"
        case harvestWindow = "harvest_window"
        case wateringSchedule = "watering_schedule"
        case frostProtectionNotes = "frost_protection_notes"
        case fertilizerSchedule = "fertilizer_schedule"
        case careSchedule = "care_schedule"
        case regionalPests = "regional_pests"
        case regionalDiseases = "regional_diseases"
        case recommendedVarieties = "recommended_varieties"
        case localSourcingNotes = "local_sourcing_notes"
        case extensionOfficeURL = "extension_office_url"
        case llmModel = "llm_model"
        case promptVersion = "prompt_version"
        case generatedAt = "generated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
