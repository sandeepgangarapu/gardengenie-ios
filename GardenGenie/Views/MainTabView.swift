import SwiftUI

/// Root tab navigator. Two main tabs plus a native search tab (iOS 26+).
/// The search tab uses `role: .search` which SwiftUI renders as a floating
/// magnifying-glass button at the bottom-right of the tab bar.
struct MainTabView: View {
    @Bindable var gardenVM: GardenViewModel
    @Bindable var taskVM: TaskViewModel

    @State private var selectedTab: AppTab = .myGarden

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Tasks", systemImage: "checklist", value: AppTab.tasks) {
                TasksView(taskVM: taskVM, gardenVM: gardenVM)
            }
            Tab("My Garden", systemImage: "leaf.fill", value: AppTab.myGarden) {
                MyGardenView(gardenVM: gardenVM, taskVM: taskVM, selectedTab: $selectedTab)
            }
            Tab("Explore", systemImage: "binoculars.fill", value: AppTab.explore) {
                ExploreView(gardenVM: gardenVM, taskVM: taskVM)
            }
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchSheet(gardenVM: gardenVM, taskVM: taskVM)
            }
        }
        .tint(AppTheme.Colors.accentPink)
    }
}

/// Identifiers for the main tabs.
enum AppTab: Hashable {
    case tasks
    case myGarden
    case explore
    case search
}

#Preview {
    MainTabView(gardenVM: GardenViewModel(), taskVM: TaskViewModel())
        .preferredColorScheme(.dark)
}
