import SwiftUI

/// Compact horizontal plant card used in the "Needs Care" carousel.
/// Icon square left, text stack right, dark card fill.
struct PlantCardView: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon in a rounded tinted square
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(plant.accentColor.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: plant.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(plant.accentColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(plant.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                if let type = plant.type {
                    Text(type.capitalized)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                if let seasonality = plant.seasonality {
                    Text(seasonality)
                        .pillTag(color: plant.accentColor)
                }
            }
        }
        .frame(width: 220, alignment: .leading)
        .gardenCard()
    }
}

#Preview {
    PlantCardView(plant: MockData.plants[0])
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
