import SwiftUI

/// The "Explore" tab: browse the catalog of plants that have a regional
/// variant for the user's `(usda_zone, state_code)`. Lazily populated server-side
/// — early on this list reflects only what users have searched for in this region.
struct ExploreView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar
                    content
                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Plant.self) { plant in
                detailDestination(for: plant)
            }
            .navigationDestination(for: PlantGridDestination.self) { destination in
                PlantGridView(destination: destination)
            }
        }
        .task(id: regionKey) { await loadIfNeeded() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Explore")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if !usdaZone.isEmpty, !stateCode.isEmpty {
                    Text("Zone \(usdaZone), \(stateCode)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - State machine

    @ViewBuilder
    private var content: some View {
        if usdaZone.isEmpty || stateCode.isEmpty {
            missingRegionState
        } else if gardenVM.isLoadingExplore && adaptedPlants.isEmpty {
            loadingState
        } else if let err = gardenVM.exploreError, adaptedPlants.isEmpty {
            errorState(err)
        } else if adaptedPlants.isEmpty {
            emptyState
        } else {
            sections
        }
    }

    // MARK: - Sections

    private var sections: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
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
        }
    }

    private var allPlantsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ExploreSectionHeader(
                title: "All Plants",
                subtitle: "\(adaptedPlants.count) plants in your zone",
                destination: PlantGridDestination(
                    title: "All Plants",
                    subtitle: "\(adaptedPlants.count) plants in your zone",
                    plants: adaptedPlants
                )
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(adaptedPlants) { plant in
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

    // MARK: - Empty / Loading / Error states

    private var missingRegionState: some View {
        emptyStateCard(
            icon: "location.slash",
            title: "Region not set",
            message: "Set your zip code in Settings so we can show plants for your area."
        )
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .padding(.top, 60)
            Text("Loading plants for zone \(usdaZone)…")
                .font(.callout)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorState(_ err: PlantCatalogServiceError) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 40)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.orange)
            Text(err.errorDescription ?? "Couldn't load plants for your zone.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.lg)
            Button("Try again") {
                Task { await gardenVM.loadExplorePlants(zone: usdaZone, state: stateCode) }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(AppTheme.Colors.accentPink, in: Capsule())
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        emptyStateCard(
            icon: "leaf.circle",
            title: "No plants for your zone yet",
            message: "Search for a plant to add it to the catalog. It'll show up here next time."
        )
    }

    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 60)
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detail routing

    /// Look up the originating `CatalogPlant` so the detail view goes through
    /// the catalog flow (`MyGardenStore` add/remove). Falls back to the plain
    /// legacy detail if the plant isn't in our cache (shouldn't happen, but
    /// keeps the navigation safe).
    @ViewBuilder
    private func detailDestination(for plant: Plant) -> some View {
        if let catalog = gardenVM.explorePlants.first(where: { $0.id == plant.id }) {
            let variant = gardenVM.variant(for: catalog, zone: usdaZone, state: stateCode)
            let adapted = CatalogPlantAdapter.adapt(catalog, variant: variant)
            PlantDetailView(
                plant: adapted,
                gardenVM: gardenVM,
                taskVM: taskVM,
                onAdd: { gardenVM.addToCatalogGarden(catalog) },
                onRemove: { gardenVM.removeFromCatalogGarden(catalog) },
                isInGardenOverride: { gardenVM.isInCatalogGarden(catalog) }
            )
        } else {
            PlantDetailView(plant: plant, gardenVM: gardenVM, taskVM: taskVM)
        }
    }

    // MARK: - Derived data

    /// CatalogPlants adapted into legacy `Plant` shape so the existing card
    /// views can render them without changes. Variant is `nil` here — the
    /// detail view fetches the full guide on tap.
    private var adaptedPlants: [Plant] {
        gardenVM.explorePlants.map { CatalogPlantAdapter.adapt($0, variant: nil) }
    }

    private var plantsByType: [(String, [Plant])] {
        groupPlants(by: { $0.type?.capitalized ?? "Other" })
    }

    private var plantsByLocation: [(String, [Plant])] {
        groupPlants(by: { $0.indoorOutdoor?.capitalized ?? "Unspecified" })
    }

    private var plantsBySun: [(String, [Plant])] {
        groupPlants(by: { $0.sunRequirements ?? "Unspecified" })
    }

    private func groupPlants(by keyPath: (Plant) -> String) -> [(String, [Plant])] {
        Dictionary(grouping: adaptedPlants, by: keyPath)
            .sorted { $0.key < $1.key }
            .filter { !$0.value.isEmpty }
    }

    // MARK: - Loading

    private var regionKey: String { "\(usdaZone)|\(stateCode)" }

    private func loadIfNeeded() async {
        guard !usdaZone.isEmpty, !stateCode.isEmpty else { return }
        await gardenVM.loadExplorePlants(zone: usdaZone, state: stateCode)
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
