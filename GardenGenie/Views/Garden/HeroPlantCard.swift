import SwiftUI

/// Large poster-style card used in the Featured carousel on the landing screen.
/// Aspect ratio ~3:4, ~260pt wide, radial gradient seeded from the plant's accent.
struct HeroPlantCard: View {
    let plant: Plant

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [plant.accentColor.opacity(0.6), plant.accentColor.opacity(0.15), AppTheme.Colors.cardBackground],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 340
                    )
                )

            // Large SF Symbol
            Image(systemName: plant.iconName)
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(plant.accentColor.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: 20, y: -20)

            // Bottom overlay: type pill + name + description
            VStack(alignment: .leading, spacing: 4) {
                if let type = plant.type {
                    Text(type.capitalized)
                        .pillTag(color: plant.accentColor)
                }

                Text(plant.name)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                if let description = plant.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .frame(width: 260, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Hex Color Convenience

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            ForEach(MockData.plants) { plant in
                HeroPlantCard(plant: plant)
            }
        }
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
