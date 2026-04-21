import SwiftUI

@main
struct GardenGenieApp: App {
    @State private var gardenVM = GardenViewModel()
    @State private var taskVM = TaskViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(gardenVM: gardenVM, taskVM: taskVM)
        }
    }
}
