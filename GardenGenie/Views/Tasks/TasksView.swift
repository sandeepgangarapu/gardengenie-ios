import SwiftUI

/// The "Tasks" tab: sectioned list of pending and completed garden tasks.
struct TasksView: View {
    @Bindable var taskVM: TaskViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Upcoming") {
                    if taskVM.pendingTasks.isEmpty {
                        Text("No upcoming tasks — nice work!")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(taskVM.pendingTasks) { task in
                            TaskRowView(task: task) {
                                withAnimation(.snappy) {
                                    taskVM.toggleCompletion(for: task.id)
                                }
                            }
                        }
                    }
                }

                if !taskVM.completedTasks.isEmpty {
                    Section("Completed") {
                        ForEach(taskVM.completedTasks) { task in
                            TaskRowView(task: task) {
                                withAnimation(.snappy) {
                                    taskVM.toggleCompletion(for: task.id)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tasks")
        }
    }
}

#Preview {
    TasksView(taskVM: TaskViewModel())
}
