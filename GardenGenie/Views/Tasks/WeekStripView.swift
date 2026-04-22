import SwiftUI

/// Horizontally scrolling strip of day pills for the Tasks tab.
/// Shows today + 28 days forward, with a dot on days that have pending tasks.
struct WeekStripView: View {
    let daysWithTasks: Set<Date>
    @Binding var selectedDay: Date
    var onDayTap: (Date) -> Void = { _ in }

    private let daysForward = 28

    private var days: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        return (0...daysForward).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(days, id: \.self) { day in
                        DayPill(
                            day: day,
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDay),
                            hasTasks: daysWithTasks.contains(Calendar.current.startOfDay(for: day))
                        )
                        .id(day)
                        .onTapGesture {
                            withAnimation(.snappy) {
                                selectedDay = day
                            }
                            onDayTap(day)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .scrollTargetBehavior(.viewAligned)
            .onAppear {
                proxy.scrollTo(Calendar.current.startOfDay(for: selectedDay), anchor: .leading)
            }
            .onChange(of: selectedDay) { _, newValue in
                withAnimation {
                    proxy.scrollTo(Calendar.current.startOfDay(for: newValue), anchor: .center)
                }
            }
        }
    }
}

private struct DayPill: View {
    let day: Date
    let isSelected: Bool
    let hasTasks: Bool

    private var weekday: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: day)
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: day)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(weekday.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.9) : AppTheme.Colors.textTertiary)
            Text(dayNumber)
                .font(.title3.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            Circle()
                .fill(hasTasks ? (isSelected ? .white : AppTheme.Colors.accentPink) : .clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 48, height: 68)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? AppTheme.Colors.accentPink : AppTheme.Colors.cardBackground)
        )
    }
}

#Preview {
    WeekStripView(
        daysWithTasks: [
            Calendar.current.startOfDay(for: .now),
            Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: .now))!
        ],
        selectedDay: .constant(.now)
    )
    .padding(.vertical)
    .background(.black)
    .preferredColorScheme(.dark)
}
