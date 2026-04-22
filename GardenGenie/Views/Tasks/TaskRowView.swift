import SwiftUI

/// A single task row with a completion toggle — blue/pink accent palette.
struct TaskRowView: View {
    let task: GardenTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? AppTheme.Colors.accentBlue : AppTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            Image(systemName: task.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentBlue)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.accentBlue.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.isCompleted, color: AppTheme.Colors.textTertiary)
                    .foregroundStyle(task.isCompleted ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                Text(task.dueDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Text(task.plantName)
                .pillTag(color: AppTheme.Colors.accentPink)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        TaskRowView(task: MockData.tasks[0]) {}
        TaskRowView(task: MockData.tasks[1]) {}
    }
    .padding()
    .background(AppTheme.Colors.cardBackground)
    .preferredColorScheme(.dark)
}
