import Foundation
import Testing
@testable import GardenGenie

struct TaskScheduleTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()
    let tomato = UUID()
    let basil = UUID()

    /// Fri Nov 13 2026 at `hour`, offset by `days`.
    func day(_ days: Int, _ hour: Int = 9) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: hour))!
        return calendar.date(byAdding: .day, value: days, to: base)!
    }
    var now: Date { day(0, 15) }

    func task(_ name: String, _ due: Date, plant: UUID? = nil, done: Bool = false) -> GardenTask {
        GardenTask(name: name, dueDate: due, plantID: plant ?? tomato, plantName: "Roma tomato",
                   isCompleted: done, iconName: "drop.fill")
    }

    @Test func dueTodayIncludesOverdueOldestFirstAndSkipsDone() {
        let tasks = [
            task("Later today", day(0, 18)),
            task("Overdue", day(-2)),
            task("Done today", day(0), done: true),
            task("Tomorrow", day(1)),
        ]
        #expect(TaskSchedule.dueToday(tasks, now: now, calendar: calendar).map(\.name) == ["Overdue", "Later today"])
        #expect(TaskSchedule.completedToday(tasks, now: now, calendar: calendar).map(\.name) == ["Done today"])
    }

    /// From Friday, "next 7 days" is Saturday through the following Friday.
    @Test func upcomingIsTomorrowThroughSevenDays() {
        let tasks = [
            task("Today", day(0, 20)),
            task("Day 7", day(7)),
            task("Day 8", day(8, 0)),
            task("Day 1", day(1, 6)),
            task("Day 6", day(6, 23)),
            task("Done", day(2), done: true),
        ]
        #expect(TaskSchedule.upcoming(tasks, days: 7, now: now, calendar: calendar).map(\.name) == ["Day 1", "Day 6", "Day 7"])
    }

    @Test func statusPicksTheMostUrgentPendingTask() {
        #expect(TaskSchedule.status(for: tomato, in: [], now: now, calendar: calendar) == .noTasks)
        #expect(TaskSchedule.status(for: tomato, in: [task("Watering", day(-1)), task("Fertilizing", day(0))],
                                    now: now, calendar: calendar) == .overdue("Watering"))
        #expect(TaskSchedule.status(for: tomato, in: [task("Watering", day(0, 7))],
                                    now: now, calendar: calendar) == .dueToday("Watering"))
        #expect(TaskSchedule.status(for: tomato, in: [task("Watering", day(3)), task("Other plant", day(0), plant: basil)],
                                    now: now, calendar: calendar) == .next("Watering", day(3)))
        #expect(TaskSchedule.status(for: tomato, in: [task("Watering", day(0), done: true)],
                                    now: now, calendar: calendar) == .noTasks)
    }

    @Test func shortDayLabels() {
        #expect(TaskSchedule.shortDayLabel(for: day(0, 20), now: now, calendar: calendar) == "Today")
        #expect(TaskSchedule.shortDayLabel(for: day(1), now: now, calendar: calendar) == "Tomorrow")
        #expect(TaskSchedule.shortDayLabel(for: day(2), now: now, calendar: calendar) == "Sun")
        #expect(TaskSchedule.shortDayLabel(for: day(14), now: now, calendar: calendar) == "Nov 27")
    }
}
