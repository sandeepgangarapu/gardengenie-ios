import SwiftUI

/// A single task row with a completion toggle. Tapping the body navigates to the
/// appropriate detail view; the checkbox toggles completion without navigating.
struct TaskRowView: View {
    let task: GardenTask
    let onToggle: () -> Void

    private var isOverdue: Bool {
        !task.isCompleted && task.dueDate < Calendar.current.startOfDay(for: .now)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? AppTheme.Colors.accentBlue : AppTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            Image.symbol(task.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentBlue)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.accentBlue.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.isCompleted, color: AppTheme.Colors.textTertiary)
                    .foregroundStyle(task.isCompleted ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                if task.recurrence.isRecurring {
                    RecurrenceBadge(recurrence: task.recurrence)
                }
            }

            Spacer()

            Text(task.plantName)
                .pillTag(color: AppTheme.Colors.accentPink)
        }
        .contentShape(Rectangle())
    }
}

/// Compact pill showing a recurring task's cadence (e.g., "Weekly", "Every 3 days").
struct RecurrenceBadge: View {
    let recurrence: TaskRecurrence

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2.weight(.bold))
            Text(recurrence.displayName)
        }
        .pillTag(color: AppTheme.Colors.accentBlue)
    }
}