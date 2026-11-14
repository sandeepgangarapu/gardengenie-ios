import SwiftUI
import UserNotifications

@main
struct GardenGenieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var gardenVM = GardenViewModel()
    @State private var taskVM = TaskViewModel.shared
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, phase in
            // Picks up permission changes made in iOS Settings and keeps the
            // next 60 reminders queued as days go by.
            guard phase == .active else { return }
            // Recurring tasks missed while away land on today (this persists,
            // which also resyncs reminders when anything moved).
            taskVM.rollForwardRecurringTasks()
            ReminderScheduler.shared.sync(taskVM.tasks)
        }
    }
}

/// Registers reminder actions and routes notification responses to the task list.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Must be set before launch finishes so action taps that launch the
        // app in the background are delivered.
        UNUserNotificationCenter.current().delegate = self
        ReminderScheduler.shared.registerCategories()
        TaskViewModel.shared.onPersist = { tasks in
            ReminderScheduler.shared.sync(tasks)
        }
        return true
    }

    // The completion-handler forms are used on purpose. With the `async` forms,
    // the handler is called back off the main thread when the method returns,
    // and UIKit aborts after a notification action
    // (`_performBlockAfterCATransactionCommitSynchronizes`).

    /// Show reminders as banners even while the app is open.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        let taskID = (response.notification.request.content.userInfo[ReminderPlanner.taskIDKey] as? String)
            .flatMap(UUID.init(uuidString:))
        // The handler isn't annotated Sendable, but it's only ever invoked once,
        // on the main queue, which is what the system expects.
        nonisolated(unsafe) let done = completionHandler
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let taskID { Self.handle(action: action, taskID: taskID) }
            }
            done()
        }
    }

    @MainActor
    private static func handle(action: String, taskID: UUID) {
        switch action {
        case ReminderScheduler.doneActionID:
            TaskViewModel.shared.markDone(taskID)
        case ReminderScheduler.tomorrowActionID:
            TaskViewModel.shared.snoozeToTomorrow(taskID)
        default:
            break // A plain tap just opens the app.
        }
    }
}
