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
    @State private var debounceTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
                    .animation(.snappy, value: gardenVM.isSearching)
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
                .onChange(of: query) { _, newValue in
                    debounceSuggestions(for: newValue)
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    gardenVM.clearSuggestions()
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
        } else if !gardenVM.searchResults.isEmpty {
            resultsList
        } else if !gardenVM.suggestions.isEmpty {
            suggestionsList
        } else {
            hintState
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
        PlantSearchLoadingView(query: query)
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
                if let typeLabel = displayType(plant.type) {
                    Text(typeLabel)
                        .font(.caption)
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

    // MARK: - Suggestions list

    private var suggestionsList: some View {
        List {
            Section {
                ForEach(gardenVM.suggestions) { suggestion in
                    Button {
                        query = suggestion.commonName
                        gardenVM.clearSuggestions()
                        runSearch()
                    } label: {
                        suggestionRow(suggestion)
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                }
            } header: {
                Text("Plants in catalog")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func suggestionRow(_ s: PlantCatalogService.SearchSuggestion) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            let icon = s.iconName ?? Plant.icon(for: s.type)
            let color = Color(hex: Plant.accentHex(for: s.type))
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(
                    color.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(s.commonName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if let typeLabel = displayType(s.type) {
                    Text(typeLabel)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.left")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
    }

    // MARK: - Helpers

    /// Capitalizes the catalog type ("tuber" → "Tuber") and drops empty/unknown.
    private func displayType(_ type: String?) -> String? {
        guard let raw = type?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    // MARK: - Actions

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        debounceTask?.cancel()
        gardenVM.clearSuggestions()
        Task {
            await gardenVM.searchAsync(query: trimmed, zone: usdaZone, state: stateCode)
        }
    }

    private func debounceSuggestions(for text: String) {
        debounceTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            gardenVM.clearSuggestions()
            return
        }
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await gardenVM.updateSuggestions(query: trimmed)
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
