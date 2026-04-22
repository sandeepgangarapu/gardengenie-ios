import Foundation

enum TaskKind: String, Codable, Hashable {
    case care
    case seedStarting
    case planting

    var defaultIcon: String {
        switch self {
        case .care: return "drop.fill"
        case .seedStarting: return "sparkles"
        case .planting: return "leaf.fill"
        }
    }
}
