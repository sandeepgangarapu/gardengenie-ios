import Foundation
import Testing
@testable import GardenGenie

struct ReminderPlannerTests {
    let calendar = Calendar(identifier: .gregorian)
    let plantID = UUID()

    func date(_ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func task(_ name: String, on day: Date, done: Bool = false, kind: TaskKind = .care) -> GardenTask {
        GardenTask(name: name, dueDate: day, plantID: plantID, plantName: "Roma tomato",
                   isCompleted: done, iconName: "drop.fill", kind: kind)
    }

    @Test func firesOnTheDueDayAtTheReminderTime() {
        let watering = task("Watering", on: date(14, 0, 0))
        let plan = ReminderPlanner.plan(tasks: [watering], now: date(13, 9), minutes: 8 * 60 + 30, calendar: calendar)

        #expect(plan.count == 1)
        #expect(plan[0].fireDate == date(14, 8, 30))
        #expect(plan[0].title == "Roma tomato")
        #expect(plan[0].body == "Watering is due today.")
        #expect(plan[0].taskID == watering.id)
    }

    @Test func skipsCompletedTasksAndReminderTimesAlreadyPassed() {
        let tasks = [
            task("Already done", on: date(14), done: true),
            task("Due today, 8 AM has passed", on: date(13)),
            task("Yesterday", on: date(12)),
            task("Tomorrow", on: date(14)),
        ]
        let plan = ReminderPlanner.plan(tasks: tasks, now: date(13, 9), minutes: 8 * 60, calendar: calendar)
        #expect(plan.map(\.body) == ["Tomorrow is due today."])
    }

    @Test func todayStillFiresIfTheReminderTimeIsAhead() {
        let plan = ReminderPlanner.plan(tasks: [task("Watering", on: date(13))],
                                        now: date(13, 7), minutes: 8 * 60, calendar: calendar)
        #expect(plan.first?.fireDate == date(13, 8))
    }

    @Test func soonestFirstAndCapped() {
        let tasks = (1...10).reversed().map { task("Task \($0)", on: date(13 + $0)) }
        let plan = ReminderPlanner.plan(tasks: tasks, now: date(13), minutes: 8 * 60, calendar: calendar, limit: 3)
        #expect(plan.map(\.body) == ["Task 1 is due today.", "Task 2 is due today.", "Task 3 is due today."])
    }

    @Test func plantingTasksReadNaturally() {
        let plan = ReminderPlanner.plan(
            tasks: [task("Start Roma tomato seeds indoors", on: date(20), kind: .seedStarting)],
            now: date(13), minutes: 8 * 60, calendar: calendar
        )
        #expect(plan.first?.body == "Today: Start Roma tomato seeds indoors.")
    }

    @Test func sameDayRemindersShareAThread() {
        let plan = ReminderPlanner.plan(tasks: [task("A", on: date(14)), task("B", on: date(14)), task("C", on: date(15))],
                                        now: date(13), minutes: 8 * 60, calendar: calendar)
        #expect(plan[0].threadID == plan[1].threadID)
        #expect(plan[0].threadID != plan[2].threadID)
    }
}
