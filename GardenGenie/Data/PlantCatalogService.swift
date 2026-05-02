import Foundation

/// Single response object from `POST /plant-guide`.
struct PlantGuideResponse: Codable, Hashable {
    let plant: CatalogPlant
    let variant: PlantRegionalVariant
}

/// Errors thrown by `PlantCatalogService`. UI surfaces these as friendly messages.
enum PlantCatalogServiceError: LocalizedError {
    case notAPlant
    case generationFailed(retryAfterSeconds: Int)
    case rateLimited
    case invalidRequest(String)
    case networkFailure(Error)
    case decodeFailure(Error)
    case missingRegion

    var errorDescription: String? {
        switch self {
        case .notAPlant:
            return "That doesn't look like a plant we recognize. Try \"tomato\", \"basil\", \"lavender\"…"
        case .generationFailed(let s):
            return "Couldn't generate that plant guide. Try again in \(s)s."
        case .rateLimited:
            return "Too many requests — give it a minute."
        case .invalidRequest(let m):
            return "Invalid request: \(m)"
        case .networkFailure:
            return "Network error. Check your connection and try again."
        case .decodeFailure:
            return "Got an unexpected response from the server."
        case .missingRegion:
            return "Set your zip code in Settings so we can fetch region-specific care."
        }
    }
}

/// HTTP client for the GardenGenie iOS backend.
enum PlantCatalogService {

    /// Production URL. Override only if pointing at a local dev FastAPI.
    static let baseURL = URL(string: "https://gardengenie-ios-backend.fly.dev")!

    /// Resolve a plant guide for the user's region.
    ///
    /// - Parameters:
    ///   - query: free-text plant name from the user (e.g. "Roma tomato")
    ///   - zone: USDA hardiness zone like "9b" — taken from `@AppStorage("usda_zone")`
    ///   - state: ISO 2-letter US state code like "CA" — taken from `@AppStorage("state_code")`
    /// - Returns: a `PlantGuideResponse` containing both the universal plant and its regional variant.
    /// - Throws: `PlantCatalogServiceError` for any failure surface.
    static func fetch(query: String, zone: String, state: String) async throws -> PlantGuideResponse {
        guard !zone.isEmpty, !state.isEmpty else { throw PlantCatalogServiceError.missingRegion }

        let url = baseURL.appendingPathComponent("plant-guide")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Generous timeout — cache miss can be 5–15s while LLM runs.
        request.timeoutInterval = 30

        let body: [String: String] = ["query": query, "zone": zone, "state": state.uppercased()]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PlantCatalogServiceError.networkFailure(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw PlantCatalogServiceError.networkFailure(URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601WithFractional
            do {
                return try decoder.decode(PlantGuideResponse.self, from: data)
            } catch {
                throw PlantCatalogServiceError.decodeFailure(error)
            }

        case 422:
            // Could be `{error: "not_a_plant"}` or FastAPI validation error.
            if let parsed = try? JSONDecoder().decode(ErrorBody.self, from: data),
               parsed.error == "not_a_plant"
            {
                throw PlantCatalogServiceError.notAPlant
            }
            let detail = String(data: data, encoding: .utf8) ?? "validation error"
            throw PlantCatalogServiceError.invalidRequest(detail)

        case 429:
            throw PlantCatalogServiceError.rateLimited

        case 502:
            let parsed = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw PlantCatalogServiceError.generationFailed(retryAfterSeconds: parsed?.retryAfterS ?? 5)

        default:
            throw PlantCatalogServiceError.networkFailure(
                URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
            )
        }
    }

    private struct ErrorBody: Codable {
        let error: String
        let detail: String?
        let retryAfterS: Int?

        enum CodingKeys: String, CodingKey {
            case error, detail
            case retryAfterS = "retry_after_s"
        }
    }
}

// MARK: - ISO8601 with fractional-second support

extension JSONDecoder.DateDecodingStrategy {
    /// Backend writes timestamps via Python's `datetime.isoformat()` which includes
    /// microseconds. The default `.iso8601` decoder rejects fractional seconds.
    static var iso8601WithFractional: Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: raw) { return date }
            // Fallback for timestamps without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse ISO8601 date: \(raw)"
            )
        }
    }
}
