import SwiftUI

/// Catalog-driven search. User types a plant name; on submit we POST to the
/// FastAPI backend (`/plant-guide`) with their region and render the result.
/// Tap navigates into `CatalogPlantDetailView`, where the user can save the
/// plant to their garden.
struct SearchSheet: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""
    @AppStorage("zip_code") private var zipCode = ""

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: CatalogPlantNavigation.self) { dest in
                let variant = gardenVM.variant(for: dest.plant, zone: usdaZone, state: stateCode)
                let adapted = CatalogPlantAdapter.adapt(dest.plant, variant: variant)
                PlantDetailView(
                    plant: adapted,
                    gardenVM: gardenVM,
                    taskVM: taskVM,
                    onAdd: { gardenVM.addToCatalogGarden(dest.plant) },
                    onRemove: { gardenVM.removeFromCatalogGarden(dest.plant) },
                    isInGardenOverride: { gardenVM.isInCatalogGarden(dest.plant) }
                )
            }
        }
        .task { await ensureStateCodeBackfilled() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.textSecondary)

            TextField("Search any plant — \"Roma tomato\", \"lavender\"…", text: $query)
                .focused($isSearchFocused)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .submitLabel(.search)
                .onSubmit { runSearch() }

            if !query.isEmpty {
                Button {
                    query = ""
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Colors.cardBackgroundElevated)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: - Body content

    @ViewBuilder
    private var content: some View {
        if usdaZone.isEmpty || stateCode.isEmpty {
            missingRegionState
        } else if gardenVM.isSearching {
            loadingState
        } else if let err = gardenVM.lastSearchError {
            errorState(err)
        } else if gardenVM.searchResults.isEmpty {
            hintState
        } else {
            resultsList
        }
    }

    // MARK: - States

    private var missingRegionState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 60)
            Image(systemName: "location.slash")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text("Region not set")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("Set your zip code in Settings so we can fetch region-specific care.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.lg)
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 60)
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.Colors.accentPink)
                .scaleEffect(1.4)
            Text("Generating your plant guide…")
                .font(.callout)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text("Cache hits are instant — first lookup of a plant takes ~5–10 s.")
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Spacer()
        }
    }

    private func errorState(_ err: PlantCatalogServiceError) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 40)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.orange)
            Text(err.errorDescription ?? "Something went wrong.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.lg)
            Button("Try again") { runSearch() }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(AppTheme.Colors.accentPink, in: Capsule())
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private var hintState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer().frame(height: 60)
            Image(systemName: "leaf.circle")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(AppTheme.Colors.accentPink.opacity(0.7))
            Text("Search for any plant")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("Region: zone \(usdaZone), \(stateCode)")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Spacer()
        }
    }

    private var resultsList: some View {
        List {
            ForEach(gardenVM.searchResults) { plant in
                NavigationLink(value: CatalogPlantNavigation(plant: plant)) {
                    catalogRow(plant)
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func catalogRow(_ plant: CatalogPlant) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: plant.displayIconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(plant.accentColor)
                .frame(width: 48, height: 48)
                .background(
                    plant.accentColor.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if let scientific = plant.scientificName {
                    Text(scientific)
                        .font(.caption.italic())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
            if gardenVM.isInCatalogGarden(plant) {
                Text("In Garden")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.accentPink)
            }
        }
    }

    // MARK: - Actions

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await gardenVM.searchAsync(query: trimmed, zone: usdaZone, state: stateCode)
        }
    }

    /// One-time backfill for users who onboarded before `state_code` was added.
    /// If we have a zip but no state, look it up.
    private func ensureStateCodeBackfilled() async {
        guard stateCode.isEmpty, !zipCode.isEmpty else { return }
        do {
            let info = try await USDAZoneLookup.zone(for: zipCode)
            if let s = info.state, !s.isEmpty {
                stateCode = s
            }
        } catch {
            // Silent fail — user can re-enter zip in settings if needed.
        }
    }
}

/// Navigation token so we can push CatalogPlantDetailView via NavigationStack value.
struct CatalogPlantNavigation: Hashable {
    let plant: CatalogPlant
}
