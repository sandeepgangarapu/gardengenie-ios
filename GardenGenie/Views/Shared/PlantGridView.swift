import SwiftUI

/// Destination value pushed when a user taps a carousel section header.
/// Conforms to Hashable so it can be used with `NavigationLink(value:)`.
struct PlantGridDestination: Hashable {
    let title: String
    let subtitle: String
    let plants: [Plant]
}

/// Full-screen 2-column grid of plants — the "See all" destination for the
/// carousel headers in Explore and My Garden.
struct PlantGridView: View {
    let destination: PlantGridDestination

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.md),
        GridItem(.flexible(), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(destination.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, AppTheme.Spacing.md)

                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
                    ForEach(destination.plants) { plant in
                        NavigationLink(value: plant) {
                            GridPlantCard(plant: plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)

                Spacer(minLength: 80)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Vertical-format card tailored for the grid. Larger icon tile on top,
/// text stack below. Fills its grid column.
private struct GridPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(plant.accentColor.opacity(0.18))
                    .aspectRatio(1, contentMode: .fit)
                Image(systemName: plant.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(plant.accentColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(plant.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                if let type = plant.type {
                    Text(type.capitalized)
                        .pillTag(color: plant.accentColor)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}