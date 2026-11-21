import SwiftUI

/// Poster card for a catalog plant in Explore: the plant's cut-out on a gradient
/// in its color (or the user's own photo when they have one).
struct ExplorePoster: View {
    let plant: CatalogPlant
    var badge: String? = nil
    var photo: UIImage? = nil
    var cutout: UIImage? = nil
    var width: CGFloat? = nil
    let height: CGFloat

    private var isLarge: Bool { height >= 180 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlantArtworkView(
                accent: plant.accentColor,
                symbol: plant.displayIconName,
                content: .resolve(art: plant.art, userPhoto: photo, userCutout: cutout),
                symbolSize: isLarge ? 72 : 40,
                endRadius: isLarge ? 280 : 170,
                labelInset: isLarge ? 0.3 : 0.26
            )

            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 3) {
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Text(plant.commonName)
                    .font(isLarge ? .headline : .caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                if isLarge {
                    Text([plant.type?.capitalized, plant.sunCategory].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(isLarge ? 12 : 9)
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: isLarge ? AppTheme.CornerRadius.card : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isLarge ? AppTheme.CornerRadius.card : 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

/// The round + / ✓ button laid over a poster. Kept outside the poster's
/// NavigationLink so tapping it adds the plant instead of opening it.
struct QuickAddButton: View {
    let plantName: String
    let isInGarden: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            Image(systemName: isInGarden ? "checkmark" : "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(width: 28, height: 28)
                .background {
                    if isInGarden {
                        Circle().fill(AppTheme.Colors.accentPink)
                    } else {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isInGarden)
        .padding(8)
        .accessibilityLabel(isInGarden ? "\(plantName) is in your garden" : "Add \(plantName) to garden")
    }
}
