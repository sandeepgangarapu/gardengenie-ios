import SwiftUI

/// Destination value pushed when a user taps a carousel section header.
/// Conforms to Hashable so it can be used with `NavigationLink(value:)`.
struct PlantGridDestination: Hashable {
    let title: String
    let subtitle: String
    let plants: [Plant]
}

/// Full-screen 3-column poster grid — the "See all" destination for the
/// section headers in Explore.
struct PlantGridView: View {
    let destination: PlantGridDestination

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

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

                LazyVGrid(columns: columns, spacing: 10) {
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

/// Poster tile for the grid: the plant's cut-out on its color, name at the bottom.
private struct GridPlantCard: View {
    let plant: Plant

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlantArtworkView(
                accent: plant.accentColor,
                symbol: plant.iconName,
                content: .resolve(art: plant.art, userPhoto: nil, userCutout: nil),
                symbolSize: 40,
                endRadius: 170,
                labelInset: 0.26,
                topInset: 0.1
            )
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
            Text(plant.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .padding(9)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
