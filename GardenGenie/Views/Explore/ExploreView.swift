import SwiftUI

/// The "Explore" tab: what to grow in the user's zone right now.
///
/// Sections are timely rather than sorted by attribute: "Plant now",
/// "Start seeds soon", and plants that pair with what's already in the garden.
/// The full list sits underneath as a poster grid, narrowed by filter chips.
/// Every poster has a + to add it without opening it.
///
/// Planting windows live on each plant's regional variant, which `/catalog`
/// doesn't return. They're fetched in the background (and cached), so the
/// timely sections fill in a moment after the list appears.
struct ExploreView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""
    @AppStorage("haptics_enabled") private var hapticsEnabled = true

    @State private var filter: ExploreFilter = .all
    @State private var carePlanTarget: CatalogPlant?
    @State private var isLoadingWindows = false
    @State private var feedbackTick = 0

    enum ExploreFilter: Hashable {
        case all
        case type(String)
        case shadeOK
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    private var currentMonth: Int { Calendar.current.component(.month, from: .now) }

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
            .refreshable { await refresh() }
            .navigationBarHidden(true)
            .sheet(item: $carePlanTarget) { plant in
                CarePlanSheet(
                    plant: CatalogPlantAdapter.adapt(plant, variant: gardenVM.variant(for: plant, zone: usdaZone, state: stateCode)),
                    taskVM: taskVM,
                    refreshPlant: { await gardenVM.regionalPlant(for: plant, zone: usdaZone, state: stateCode) }
                )
            }
            .sensoryFeedback(trigger: feedbackTick) { _, _ in hapticsEnabled ? .success : nil }
            .navigationDestination(for: Plant.self) { plant in
                detailDestination(for: plant)
            }
            .navigationDestination(for: PlantGridDestination.self) { destination in
                PlantGridView(destination: destination)
            }
        }
        .task(id: regionKey) { await refresh() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Explore")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            if !usdaZone.isEmpty, !stateCode.isEmpty {
                Text("Zone \(usdaZone), \(stateCode) · What to grow in \(Date.now.formatted(.dateTime.month(.wide)))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - State machine

    @ViewBuilder
    private var content: some View {
        if usdaZone.isEmpty || stateCode.isEmpty {
            emptyStateCard(icon: "location.slash", title: "Region not set",
                           message: "Set your zip code in Settings so we can show plants for your area.")
        } else if gardenVM.isLoadingExplore && gardenVM.explorePlants.isEmpty {
            VStack(spacing: AppTheme.Spacing.md) {
                ProgressView().controlSize(.large).padding(.top, 60)
                Text("Loading plants for zone \(usdaZone)…")
                    .font(.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        } else if let err = gardenVM.exploreError, gardenVM.explorePlants.isEmpty {
            errorState(err)
        } else if gardenVM.explorePlants.isEmpty {
            emptyStateCard(icon: "leaf.circle", title: "No plants for your zone yet",
                           message: "Search for a plant to add it to the catalog. It'll show up here next time.")
        } else {
            sections
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var sections: some View {
        let plants = filteredPlants
        let plantNow = plants.filter { PlantingCalendar.isPlantingTime(windows(for: $0), month: currentMonth) }
        let plantNowIDs = Set(plantNow.map(\.id))
        let seedsSoon = plants.filter {
            // Four months ahead, so November already shows February seed-starting.
            !plantNowIDs.contains($0.id) && PlantingCalendar.seedStartIsSoon(windows(for: $0), month: currentMonth, withinMonths: 4)
        }
        let pairs = companionPairs(in: plants)

        filterChips

        if !plantNow.isEmpty {
            posterCarousel(
                title: "Plant now",
                subtitle: "Good to get in the ground this month",
                plants: plantNow,
                badge: { windowBadge(for: $0, kind: .plantOut, prefix: "Plant") }
            )
        }
        if !seedsSoon.isEmpty {
            posterCarousel(
                title: "Start seeds soon",
                subtitle: "Seed-starting opens in the next few months",
                plants: seedsSoon,
                badge: { windowBadge(for: $0, kind: .seedIndoors, prefix: "Seeds") }
            )
        }
        if !pairs.isEmpty {
            posterCarousel(
                title: "Pairs with your garden",
                subtitle: "Companions for what you're already growing",
                plants: pairs.map(\.plant),
                badge: { plant in pairs.first { $0.plant.id == plant.id }.map { "With \($0.gardenPlantName)" } }
            )
        }
        if isLoadingWindows && plantNow.isEmpty && seedsSoon.isEmpty {
            HStack(spacing: AppTheme.Spacing.sm) {
                ProgressView().controlSize(.small)
                Text("Checking planting windows for zone \(usdaZone)…")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }

        allPlantsGrid(plants)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                chip("All", .all)
                ForEach(availableTypes, id: \.self) { type in
                    chip(Self.pluralLabel(for: type), .type(type))
                }
                if gardenVM.explorePlants.contains(where: Self.toleratesShade) {
                    chip("Shade-OK", .shadeOK)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    private func chip(_ label: String, _ value: ExploreFilter) -> some View {
        let selected = filter == value
        return Button {
            withAnimation(.snappy) { filter = value }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? AppTheme.Colors.accentPink : AppTheme.Colors.cardBackgroundElevated, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func posterCarousel(
        title: String,
        subtitle: String,
        plants: [CatalogPlant],
        badge: @escaping (CatalogPlant) -> String?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            NavigationLink(value: PlantGridDestination(
                title: title, subtitle: subtitle,
                plants: plants.map { CatalogPlantAdapter.adapt($0, variant: nil) }
            )) {
                sectionHeader(title: title, subtitle: subtitle)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        posterLink(plant, badge: badge(plant), width: 170, height: 224)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func allPlantsGrid(_ plants: [CatalogPlant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader(title: filter == .all ? "All plants" : "Matching plants",
                          subtitle: "\(plants.count) in your zone", chevron: false)
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(plants) { plant in
                    posterLink(plant, badge: nil, width: nil, height: 150)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    private func posterLink(_ plant: CatalogPlant, badge: String?, width: CGFloat?, height: CGFloat) -> some View {
        let inGarden = gardenVM.isInCatalogGarden(plant)
        return NavigationLink(value: CatalogPlantAdapter.adapt(plant, variant: nil)) {
            ExplorePoster(plant: plant, badge: badge, photo: gardenVM.photos.image(for: plant.id),
                          cutout: gardenVM.photos.cutout(for: plant.id),
                          width: width, height: height)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            QuickAddButton(plantName: plant.commonName, isInGarden: inGarden) { quickAdd(plant) }
        }
        .contextMenu {
            if inGarden {
                Button("In Your Garden", systemImage: "checkmark") {}
                    .disabled(true)
                Button("Set Up Care Plan…", systemImage: "calendar.badge.checkmark") { carePlanTarget = plant }
            } else {
                Button("Add to Garden", systemImage: "plus") { quickAdd(plant) }
            }
            ShareLink(item: "\(plant.commonName): \(plant.description ?? "a plant worth growing"). Shared from GardenGenie") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Empty / error states

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
                Task { await refresh() }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(AppTheme.Colors.accentPink, in: Capsule())
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
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

    private func sectionHeader(title: String, subtitle: String, chevron: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Detail routing

    /// Look up the originating `CatalogPlant` so the detail view goes through
    /// the catalog flow (`MyGardenStore` add/remove). Falls back to the plain
    /// legacy detail if the plant isn't in our cache.
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
                isInGardenOverride: { gardenVM.isInCatalogGarden(catalog) },
                refreshPlant: {
                    await gardenVM.regionalPlant(for: catalog, zone: usdaZone, state: stateCode)
                }
            )
        } else {
            PlantDetailView(plant: plant, gardenVM: gardenVM, taskVM: taskVM)
        }
    }

    // MARK: - Actions

    private func quickAdd(_ plant: CatalogPlant) {
        guard !gardenVM.isInCatalogGarden(plant) else { return }
        withAnimation(.snappy) { gardenVM.addToCatalogGarden(plant) }
        feedbackTick += 1
        carePlanTarget = plant
    }

    // MARK: - Derived data

    private var filteredPlants: [CatalogPlant] {
        gardenVM.explorePlants.filter { plant in
            switch filter {
            case .all: return true
            case .type(let type): return plant.type?.lowercased() == type
            case .shadeOK: return Self.toleratesShade(plant)
            }
        }
    }

    /// Plant types present in this zone, most common first.
    private var availableTypes: [String] {
        let counts = Dictionary(grouping: gardenVM.explorePlants.compactMap { $0.type?.lowercased() }, by: { $0 })
            .mapValues(\.count)
        return counts.keys.sorted { (counts[$0]!, $1) > (counts[$1]!, $0) }
    }

    private func windows(for plant: CatalogPlant) -> [SeasonWindow] {
        CatalogPlantAdapter.seasonWindows(gardenVM.variant(for: plant, zone: usdaZone, state: stateCode))
    }

    private func windowBadge(for plant: CatalogPlant, kind: SeasonWindow.Kind, prefix: String) -> String? {
        guard let window = windows(for: plant).first(where: { $0.kind == kind }) else { return nil }
        let names = Calendar.current.shortMonthSymbols
        let start = names[window.startMonth - 1], end = names[window.endMonth - 1]
        return window.startMonth == window.endMonth ? "\(prefix) in \(start)" : "\(prefix) \(start)–\(end)"
    }

    private func companionPairs(in plants: [CatalogPlant]) -> [(plant: CatalogPlant, gardenPlantName: String)] {
        let garden = gardenVM.myGarden.savedPlants.map { (id: $0.id, name: $0.commonName, companions: $0.companionPlants) }
        guard !garden.isEmpty else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: plants.map { ($0.id, $0) })
        return Companions.pairs(candidates: plants.map { (id: $0.id, name: $0.commonName) }, garden: garden)
            .compactMap { pair in byID[pair.candidateID].map { ($0, pair.gardenPlantName) } }
    }

    nonisolated static func toleratesShade(_ plant: CatalogPlant) -> Bool {
        (plant.sunCategory ?? "").lowercased().contains("shade")
    }

    nonisolated static func pluralLabel(for type: String) -> String {
        let word = type.prefix(1).uppercased() + type.dropFirst()
        if word.hasSuffix("s") { return word }
        if word.hasSuffix("y") { return word.dropLast() + "ies" }
        return word + "s"
    }

    // MARK: - Loading

    private var regionKey: String { "\(usdaZone)|\(stateCode)" }

    private func refresh() async {
        guard !usdaZone.isEmpty, !stateCode.isEmpty else { return }
        await gardenVM.loadExplorePlants(zone: usdaZone, state: stateCode)
        await prefetchWindows()
    }

    /// Fetch missing regional variants four at a time. They're cached, so this
    /// only does real work on the first visit (or for newly added plants).
    private func prefetchWindows() async {
        let zone = usdaZone, state = stateCode
        let missing = gardenVM.explorePlants.filter { gardenVM.variant(for: $0, zone: zone, state: state) == nil }
        guard !missing.isEmpty else { return }
        isLoadingWindows = true
        defer { isLoadingWindows = false }
        let viewModel = gardenVM
        await withTaskGroup(of: Void.self) { group in
            var queue = missing.makeIterator()
            for _ in 0..<4 {
                guard let plant = queue.next() else { break }
                group.addTask { _ = await viewModel.ensureVariant(for: plant, zone: zone, state: state) }
            }
            while await group.next() != nil {
                if let plant = queue.next() {
                    group.addTask { _ = await viewModel.ensureVariant(for: plant, zone: zone, state: state) }
                }
            }
        }
    }
}
