import Foundation
import SwiftUI

/// A plant from the Supabase catalog, matching the `public.plants` table.
struct Plant: Identifiable, Hashable, Codable {

    // MARK: - Supabase Columns

    let id: UUID
    var name: String
    var description: String?

    /// Plant classification — vegetable, herb, shrub, tuber, etc.
    var type: String?
    /// USDA hardiness zone this catalog row targets.
    var zone: String?
    var sunRequirements: String?
    /// Freeform text describing which zones the plant thrives in.
    var zoneSuitability: String?
    /// Season tags — e.g. "Spring", "Cool-season annual".
    var seasonality: String?
    /// Indoor / Outdoor classification.
    var indoorOutdoor: String?

    // JSONB blobs
    var requirements: PlantRequirements?
    var seedStarting: SeedStartingInfo?
    var planting: PlantingInfo?
    var carePlan: CarePlan?
    var typeSpecific: TypeSpecificInfo?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "plant_id"
        case name = "plant_name"
        case description
        case type, zone
        case sunRequirements = "sun_requirements"
        case zoneSuitability = "zone_suitability"
        case seasonality
        case indoorOutdoor = "indoor_outdoor"
        case requirements
        case seedStarting = "seed_starting"
        case planting
        case carePlan = "care_plan"
        case typeSpecific = "type_specific"
    }

    // MARK: - Client-Only Computed Properties

    /// SF Symbol name derived from the plant's `type`.
    var iconName: String {
        Self.icon(for: type)
    }

    /// Hex color seed derived from the plant's `type`, used for card gradients.
    var accentHex: String {
        Self.accentHex(for: type)
    }

    // MARK: - Type → Icon Mapping

    static func icon(for type: String?) -> String {
        switch type?.lowercased() {
        case "vegetable":   return "leaf.fill"
        case "herb":        return "leaf.arrow.circlepath"
        case "flower":      return "camera.macro"
        case "fruit":       return "heart.fill"
        case "shrub":       return "tree.fill"
        case "tuber":       return "leaf.circle.fill"
        case "succulent":   return "sparkles"
        case "vine":        return "wind"
        default:            return "leaf.fill"
        }
    }

    // MARK: - Type → Accent Color Mapping

    static func accentHex(for type: String?) -> String {
        switch type?.lowercased() {
        case "vegetable":   return "E84545"
        case "herb":        return "4BB84B"
        case "flower":      return "E84B8A"
        case "fruit":       return "E84560"
        case "shrub":       return "4B8BE8"
        case "tuber":       return "8B6B3D"
        case "succulent":   return "9B59B6"
        case "vine":        return "F5B731"
        default:            return "F24C78"
        }
    }

    /// Convenience: SwiftUI Color from the computed accent hex.
    var accentColor: Color {
        Color(hex: accentHex)
    }
}
