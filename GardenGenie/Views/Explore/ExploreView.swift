import SwiftUI

/// The "Explore" tab: browse the full plant database with horizontal carousels.
struct ExploreView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar
                    allPlantsSection
                    ForEach(plantsByType, id: \.0) { groupName, plants in
                        carouselSection(title: groupName, subtitle: "By type", plants: plants)
                    }
                    ForEach(plantsByLocation, id: \.0) { groupName, plants in
                        carouselSection(title: groupName, subtitle: "By location", plants: plants)
                    }
                    ForEach(plantsBySun, id: \.0) { groupName, plants in
                        carouselSection(title: groupName, subtitle: "By sunlight", plants: plants)
                    }
                    ForEach(plantsByWater, id: \.0) { groupName, plants in
                        carouselSection(title: groupName, subtitle: "By water needs", plants: plants)
                    }
                    ForEach(plantsBySeason, id: \.0) { groupName, plants in
                        carouselSection(title: groupName, subtitle: "By season", plants: plants)
                    }
                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant, gardenVM: gardenVM, taskVM: taskVM)
            }
            .navigationDestination(for: PlantGridDestination.self) { destination in
                PlantGridView(destination: destination)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Explore")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - All Plants Section

    private var allPlantsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ExploreSectionHeader(
                title: "All Plants",
                subtitle: "\(gardenVM.allPlants.count) plants to discover",
                destination: PlantGridDestination(
                    title: "All Plants",
                    subtitle: "\(gardenVM.allPlants.count) plants to discover",
                    plants: gardenVM.allPlants
                )
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(gardenVM.allPlants) { plant in
                        NavigationLink(value: plant) {
                            HeroPlantCard(plant: plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - Carousel Section

    private func carouselSection(title: String, subtitle: String, plants: [Plant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ExploreSectionHeader(
                title: title,
                subtitle: subtitle,
                destination: PlantGridDestination(title: title, subtitle: subtitle, plants: plants)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: plant) {
                            PlantCardView(plant: plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - Grouping Computed Properties

    private var plantsByType: [(String, [Plant])] {
        groupPlants(by: { $0.type?.capitalized ?? "Other" })
    }

    private var plantsByLocation: [(String, [Plant])] {
        groupPlants(by: { $0.indoorOutdoor?.capitalized ?? "Unspecified" })
    }

    private var plantsBySun: [(String, [Plant])] {
        groupPlants(by: { $0.sunRequirements ?? "Unspecified" })
    }

    private var plantsByWater: [(String, [Plant])] {
        groupPlants(by: { $0.requirements?.water ?? "Unspecified" })
    }

    private var plantsBySeason: [(String, [Plant])] {
        groupPlants(by: { $0.seasonality ?? "Year-round" })
    }

    private func groupPlants(by keyPath: (Plant) -> String) -> [(String, [Plant])] {
        Dictionary(grouping: gardenVM.allPlants, by: keyPath)
            .sorted { $0.key < $1.key }
            .filter { !$0.value.isEmpty }
    }
}

// MARK: - Section Header

private struct ExploreSectionHeader: View {
    let title: String
    let subtitle: String
    var destination: PlantGridDestination? = nil

    var body: some View {
        if let destination {
            NavigationLink(value: destination) {
                headerContent
            }
            .buttonStyle(.plain)
        } else {
            headerContent
        }
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

#Preview {
    ExploreView(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
