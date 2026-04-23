import SwiftUI

@main
struct GardenGenieApp: App {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var gardenVM = GardenViewModel()
    @State private var taskVM = TaskViewModel(tasks: MockData.tasks)

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView(gardenVM: gardenVM, taskVM: taskVM)
                } else {
                    OnboardingCoordinator()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
