import SwiftUI

/// The "My Garden" tab: two horizontal carousels — Featured + Needs Care —
/// with a dark top bar matching the card-based aesthetic.
struct MyGardenView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel
    @State private var showSettings = false
    @State private var featuredOrder: [Plant] = []

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    topBar
                    featuredSection
                    needsCareSection
                    Spacer(minLength: 80)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant, gardenVM: gardenVM, taskVM: taskVM)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(gardenVM: gardenVM, taskVM: taskVM)
            }
            .onAppear {
                if featuredOrder.isEmpty {
                    featuredOrder = gardenVM.plants
                }
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

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "Featured", subtitle: "Plants you're growing this season")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(featuredOrder) { plant in
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

    // MARK: - Needs Care Section

    private var needsCareSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "Needs Care", subtitle: "Plants due for water or attention")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(plantsNeedingCare) { plant in
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

    /// Plants with pending tasks due within the next 3 days.
    private var plantsNeedingCare: [Plant] {
        let threeDays = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let urgentPlantIDs = Set(
            taskVM.pendingTasks
                .filter { $0.dueDate <= threeDays }
                .map(\.plantID)
        )
        let result = gardenVM.plants.filter { urgentPlantIDs.contains($0.id) }
        // Fallback: if no urgent tasks, show all plants so the section isn't empty
        return result.isEmpty ? gardenVM.plants : result
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
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
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

#Preview {
    MyGardenView(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
