import Foundation
import UIKit

/// A plant's catalog artwork: a transparent cut-out of the plant (drawn on the
/// type-accent gradient) plus the openly licensed photo it was made from.
/// Filled by the backend (`backend-ios/app/plant_art.py`).
struct PlantArt: Hashable, Sendable {
    var cutoutURL: URL? = nil
    var photoURL: URL? = nil
    /// Attribution required by the license, e.g. "(c) Jane Doe, some rights reserved (CC BY)".
    var credit: String? = nil
    /// "CC0", "CC BY", "CC BY-SA 4.0", "Public domain".
    var license: String? = nil
    /// Page to link for attribution (iNaturalist observation / Commons file page).
    var sourceURL: URL? = nil

    /// "Photo: Jane Doe · CC BY" — nil when there's nothing to credit.
    var creditLine: String? {
        guard let credit, !credit.isEmpty else { return nil }
        // iNaturalist attributions already end with "(CC BY)"; don't repeat it.
        if let license, !license.isEmpty, !credit.localizedCaseInsensitiveContains(license) {
            return "Photo: \(credit) · \(license)"
        }
        return "Photo: \(credit)"
    }
}

/// What a poster shows, best first. The user's own photo beats catalog art, and
/// a cut-out beats a full-bleed photo because it sits on the app's own gradient.
enum PlantArtContent: Equatable {
    case userCutout(UIImage)
    case userPhoto(UIImage)
    case catalogCutout(URL)
    case catalogPhoto(URL)
    case symbol

    static func resolve(art: PlantArt, userPhoto: UIImage?, userCutout: UIImage?) -> PlantArtContent {
        if let userCutout { return .userCutout(userCutout) }
        if let userPhoto { return .userPhoto(userPhoto) }
        if let url = art.cutoutURL { return .catalogCutout(url) }
        if let url = art.photoURL { return .catalogPhoto(url) }
        return .symbol
    }

    /// True when the poster shows catalog art, which needs a photo credit.
    var needsCredit: Bool {
        switch self {
        case .catalogCutout, .catalogPhoto: return true
        default: return false
        }
    }
}
