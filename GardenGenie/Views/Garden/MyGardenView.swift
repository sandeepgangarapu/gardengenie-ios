import SwiftUI

/// The "My Garden" tab: a searchable grid of plant cards with navigation to detail.
struct MyGardenView: View {
    @Bindable var gardenVM: GardenViewModel
    @State private var showSettings = false

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
                    ForEach(gardenVM.filteredPlants) { plant in
                        NavigationLink(value: plant) {
                            PlantCardView(plant: plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.Colors.secondaryGreen.opacity(0.08).ignoresSafeArea())
            .navigationTitle("My Garden")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.Colors.primaryGreen)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .searchable(text: $gardenVM.searchText, prompt: "Search plants")
        }
    }
}

#Preview {
    MyGardenView(gardenVM: GardenViewModel())
}
