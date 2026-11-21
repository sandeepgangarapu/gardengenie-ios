import Foundation
import UIKit

/// A plant's catalog photo (from Unsplash, chosen by the backend) and the
/// attribution it needs.
struct PlantArt: Hashable, Sendable {
    var photoURL: URL? = nil
    /// Photographer's name (or another attribution line).
    var credit: String? = nil
    /// "Unsplash", or a license label such as "CC BY".
    var license: String? = nil
    /// Where the credit links: the photographer's Unsplash profile.
    var sourceURL: URL? = nil

    /// "Photo by Jane Doe on Unsplash" — nil when there's nothing to credit.
    var creditLine: String? {
        guard let credit, !credit.isEmpty else { return nil }
        guard let license, !license.isEmpty else { return "Photo: \(credit)" }
        if license.caseInsensitiveCompare("Unsplash") == .orderedSame {
            return "Photo by \(credit) on Unsplash"
        }
        return credit.localizedCaseInsensitiveContains(license) ? "Photo: \(credit)" : "Photo: \(credit) · \(license)"
    }
}

/// What a poster shows: the user's own photo, else the catalog photo, else the
/// type-accent gradient with the plant's SF Symbol.
enum PlantArtContent: Equatable {
    case userPhoto(UIImage)
    case catalogPhoto(URL)
    case symbol

    static func resolve(art: PlantArt, userPhoto: UIImage?) -> PlantArtContent {
        if let userPhoto { return .userPhoto(userPhoto) }
        if let url = art.photoURL { return .catalogPhoto(url) }
        return .symbol
    }

    /// Catalog photos need a credit; the user's own photo doesn't.
    var needsCredit: Bool {
        if case .catalogPhoto = self { return true }
        return false
    }
}
