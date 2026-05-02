import SwiftUI

extension Image {
    /// Resolve a symbol name to either a custom asset (`gg.*` prefix, imported
    /// as an Image Set in `Assets.xcassets`) or an Apple SF Symbol.
    ///
    /// Use this everywhere the symbol name comes from the server / catalog
    /// (e.g. `CareItem.iconName`) so the custom symbols introduced in the
    /// `IconName` whitelist render correctly. Hard-coded SF Symbol literals
    /// in views (e.g. `Image(systemName: "xmark")`) don't need this — they
    /// can never be `gg.*`.
    static func symbol(_ name: String) -> Image {
        name.hasPrefix("gg.") ? Image(name) : Image(systemName: name)
    }
}
