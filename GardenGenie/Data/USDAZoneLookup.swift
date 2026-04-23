import Foundation
import Supabase

enum USDAZoneLookupError: Error {
    case notFound
    case network(Error)
}

struct USDAZoneLookup {
    struct ZoneInfo: Equatable {
        let zone: String
        let temperatureRange: String
        let firstFrostDate: String?
        let lastFrostDate: String?
        let growingSeasonDays: Int?
        let growingSeasonDescription: String?
    }

    private struct Row: Decodable {
        let zone: String
        let temperature_range: String
        let zip_code: String
        let first_frost_date: String?
        let last_frost_date: String?
        let growing_season_days: Int?
        let growing_season_months: Int?
        let growing_season_description: String?
    }

    static func zone(for zipCode: String) async throws -> ZoneInfo {
        let rows: [Row]
        do {
            rows = try await supabase
                .from("usda_zones")
                .select()
                .eq("zip_code", value: zipCode)
                .limit(1)
                .execute()
                .value
        } catch {
            throw USDAZoneLookupError.network(error)
        }
        guard let row = rows.first else {
            throw USDAZoneLookupError.notFound
        }
        return ZoneInfo(
            zone: row.zone,
            temperatureRange: row.temperature_range,
            firstFrostDate: row.first_frost_date,
            lastFrostDate: row.last_frost_date,
            growingSeasonDays: row.growing_season_days,
            growingSeasonDescription: row.growing_season_description
        )
    }
}
