import SwiftUI

/// The "My Garden" tab: horizontal carousels for all plants and attribute-based categories.
struct MyGardenView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @Binding var selectedTab: AppTab
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar

                    if gardenVM.plants.isEmpty {
                        emptyStateView
                    } else {
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
            .sheet(isPresented: $showSettings) {
                SettingsView(gardenVM: gardenVM, taskVM: taskVM)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Garden")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .circularIconButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Button {
            selectedTab = .search
        } label: {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(AppTheme.Colors.accentPink.opacity(0.6))

                Text("Your garden is empty")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Tap here to search and add your first plant")
                    .font(.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Plants Section

    private var allPlantsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(
                title: "All Plants",
                subtitle: "\(gardenVM.plants.count) plants in your garden",
                destination: PlantGridDestination(
                    title: "All Plants",
                    subtitle: "\(gardenVM.plants.count) plants in your garden",
                    plants: gardenVM.plants
                )
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(gardenVM.plants) { plant in
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
            SectionHeader(
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
        Dictionary(grouping: gardenVM.plants, by: keyPath)
            .sorted { $0.key < $1.key }
            .filter { !$0.value.isEmpty }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
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
    @Previewable @State var selectedTab: AppTab = .myGarden
    MyGardenView(
        gardenVM: GardenViewModel(),
        taskVM: TaskViewModel(),
        selectedTab: $selectedTab
    )
    .preferredColorScheme(.dark)
}
