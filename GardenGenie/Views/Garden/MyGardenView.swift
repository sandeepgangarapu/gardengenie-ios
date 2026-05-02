import SwiftUI

/// The "My Garden" tab: shows the user's saved catalog plants, persisted in
/// `MyGardenStore` (UserDefaults). Plants are added from the Search tab.
struct MyGardenView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @Binding var selectedTab: AppTab
    @AppStorage("usda_zone") private var usdaZone = ""
    @AppStorage("state_code") private var stateCode = ""

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar

                    let saved = gardenVM.myGarden.savedPlants
                    if saved.isEmpty {
                        emptyStateView
                    } else {
                        savedSection(saved)
                        ForEach(plantsByType(saved), id: \.0) { groupName, plants in
                            carouselSection(title: groupName, subtitle: "By type", plants: plants)
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
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

    // MARK: - Sections

    private func savedSection(_ plants: [CatalogPlant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader(
                title: "All Plants",
                subtitle: "\(plants.count) plant\(plants.count == 1 ? "" : "s") in your garden"
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: CatalogPlantNavigation(plant: plant)) {
                            catalogCard(plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func carouselSection(title: String, subtitle: String, plants: [CatalogPlant]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: CatalogPlantNavigation(plant: plant)) {
                            catalogCard(plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    private func catalogCard(_ plant: CatalogPlant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(plant.accentColor.opacity(0.18))
                Image(systemName: plant.displayIconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(plant.accentColor)
            }
            .frame(width: 160, height: 120)

            Text(plant.commonName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            if let type = plant.type {
                Text(type.capitalized)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .frame(width: 160, alignment: .leading)
    }

    // MARK: - Grouping

    private func plantsByType(_ plants: [CatalogPlant]) -> [(String, [CatalogPlant])] {
        Dictionary(grouping: plants, by: { $0.type?.capitalized ?? "Other" })
            .sorted { $0.key < $1.key }
            .filter { !$0.value.isEmpty }
    }

    // MARK: - Header

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
