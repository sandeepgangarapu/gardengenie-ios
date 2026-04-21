import SwiftUI

/// Detail screen showing full care information for a plant.
struct PlantDetailView: View {
    let plant: Plant

    private let gridColumns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.md),
        GridItem(.flexible(), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                heroSection

                Text(plant.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.md)

                careGrid

                companionSection
            }
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.secondaryGreen.opacity(0.08).ignoresSafeArea())
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryGreen.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: plant.iconName)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryGreen)
            }

            Text(plant.name)
                .font(.largeTitle.bold())
            Text(plant.botanicalName)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)

            Text(plant.statusTag)
                .pillTag(color: AppTheme.Colors.statusColor(for: plant.statusTag))
                .padding(.top, AppTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var careGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Care")
                .font(.title3.bold())
                .padding(.horizontal, AppTheme.Spacing.md)

            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.md) {
                careCard(
                    title: "Sunlight",
                    value: plant.sunlightNeeds,
                    icon: "sun.max.fill",
                    tint: AppTheme.Colors.sunYellow
                )
                careCard(
                    title: "Watering",
                    value: plant.wateringFrequency,
                    icon: "drop.fill",
                    tint: AppTheme.Colors.skyBlue
                )
                careCard(
                    title: "Season",
                    value: plant.plantingSeason,
                    icon: "calendar",
                    tint: AppTheme.Colors.primaryGreen
                )
                careCard(
                    title: "Soil",
                    value: plant.soilType,
                    icon: "mountain.2.fill",
                    tint: AppTheme.Colors.earthBrown
                )
                if let harvest = plant.daysToHarvest {
                    careCard(
                        title: "Harvest",
                        value: harvest,
                        icon: "clock.fill",
                        tint: AppTheme.Colors.primaryGreen
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    @ViewBuilder
    private func careCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .gardenCard()
    }

    private var companionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Companion Plants")
                .font(.title3.bold())
                .padding(.horizontal, AppTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(plant.companionPlants, id: \.self) { companion in
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "leaf.fill")
                                .font(.caption)
                            Text(companion)
                                .font(.callout.weight(.medium))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.secondaryGreen.opacity(0.25), in: Capsule())
                        .foregroundStyle(AppTheme.Colors.primaryGreen)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlantDetailView(plant: MockData.plants[0])
    }
}
