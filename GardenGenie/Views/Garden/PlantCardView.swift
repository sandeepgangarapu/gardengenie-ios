import SwiftUI

/// A single plant card used in the garden grid.
struct PlantCardView: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Icon in a rounded tinted square
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.Colors.primaryGreen.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: plant.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryGreen)
            }

            Spacer(minLength: 0)

            Text(plant.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(plant.botanicalName)
                .font(.caption2)
                .italic()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(plant.statusTag)
                .pillTag(color: AppTheme.Colors.statusColor(for: plant.statusTag))
        }
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
        .gardenCard()
    }
}

#Preview {
    PlantCardView(plant: MockData.plants[0])
        .padding()
}
