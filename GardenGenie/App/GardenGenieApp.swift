import SwiftUI

@main
struct GardenGenieApp: App {
    @State private var gardenVM = GardenViewModel()
    @State private var taskVM = TaskViewModel(tasks: MockData.tasks)

    var body: some Scene {
        WindowGroup {
            MainTabView(gardenVM: gardenVM, taskVM: taskVM)
                .preferredColorScheme(.dark)
        }
    }
}
