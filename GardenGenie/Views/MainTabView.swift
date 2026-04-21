import SwiftUI

/// Root tab navigator. Two main tabs plus a floating liquid-glass "Quick Add" button
/// anchored above the tab bar via `tabViewBottomAccessory` (iOS 26+).
struct MainTabView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    @State private var selectedTab: AppTab = .myGarden
    @State private var showQuickAdd = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Tasks", systemImage: "checklist", value: AppTab.tasks) {
                TasksView(taskVM: taskVM)
            }
            Tab("My Garden", systemImage: "leaf.fill", value: AppTab.myGarden) {
                MyGardenView(gardenVM: gardenVM)
            }
        }
        .tint(AppTheme.Colors.primaryGreen)
        .tabViewBottomAccessory {
            quickAddButton
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet()
        }
    }

    // MARK: - Floating Glass Button

    private var quickAddButton: some View {
        Button {
            showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryGreen)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
        .accessibilityLabel("Quick Add")
    }
}

/// Identifiers for the main tabs.
enum AppTab: Hashable {
    case tasks
    case myGarden
}

#Preview {
    MainTabView(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
}
