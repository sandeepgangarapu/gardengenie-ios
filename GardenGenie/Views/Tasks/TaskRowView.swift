import SwiftUI

/// A single task row with a completion toggle.
struct TaskRowView: View {
    let task: GardenTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? AppTheme.Colors.primaryGreen : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: task.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryGreen)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.primaryGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                Text(task.dueDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(task.plantName)
                .pillTag(color: AppTheme.Colors.secondaryGreen)
        }
        .contentShape(Rectangle())
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

#Preview {
    List {
        TaskRowView(task: MockData.tasks[0]) {}
        TaskRowView(task: MockData.tasks[1]) {}
    }
}
