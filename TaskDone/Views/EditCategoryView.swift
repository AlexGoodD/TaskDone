import SwiftUI
import CoreData

struct EditCategoryView: View {
    @Binding var category: TaskCategory
    @State private var tempCategory: TaskCategory
    @State private var categoryColor: Color
    @State private var hasUnsavedChanges = false
    @State private var showAlert = false
    @State private var newTaskTitle: String = ""
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: TaskViewModel
    
    init(category: Binding<TaskCategory>) {
        self._category = category
        self._tempCategory = State(initialValue: category.wrappedValue)
        self._categoryColor = State(initialValue: Color(hex: category.wrappedValue.color))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            categoryNameField
            taskCounter
            Divider().padding(.horizontal)
            taskList
        }
        .padding(.top)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ColorPicker("Select Color", selection: $categoryColor)
                    .labelsHidden()
                    .onChange(of: categoryColor) { newColor in
                        tempCategory.color = UIColor(newColor).toHexString()
                        hasUnsavedChanges = true
                    }

                Button(action: {
                    viewModel.saveCategoryChanges(category: category, tempCategory: tempCategory)
                    hasUnsavedChanges = false
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "tray.full")
                        .foregroundColor(categoryColor)
                }
            }
        }
    }
    
    private var categoryNameField: some View {
        TextField("category-name", text: $tempCategory.name)
            .font(.title)
            .foregroundColor(categoryColor)
            .fontWeight(.semibold)
            .padding(.horizontal)
            .onChange(of: tempCategory.name) { _ in
                hasUnsavedChanges = true
            }
    }
    
    private var taskCounter: some View {
        HStack {
            let completedTasks = category.tasks.filter { $0.isCompleted }.count
            let totalTasks = category.tasks.count
            Text(String(format: NSLocalizedString("%d counter-task-of %d counter-tasks", comment: "Task counters"), completedTasks, totalTasks))
                .font(.subheadline)
                .bold()
                .foregroundColor(categoryColor)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var taskList: some View {
    ScrollView {
        VStack(spacing: 10) {
            ForEach(tempCategory.tasksArray, id: \.id) { task in
                taskRow(task: task)
            }
            newTaskRow
        }
    }
}
    
    private func taskRow(task: Task) -> some View {
        HStack {
            Button(action: {
                if !task.title.isEmpty && task.title != "task-add" {
                    viewModel.toggleTaskCompletion(taskId: task.id)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                    .foregroundColor(categoryColor)
                    .bold()
            }
            .disabled(task.title.isEmpty || task.title == "task-add")
            
            let taskTitleBinding = Binding(
                get: { task.title },
                set: { newValue in
                    if newValue.isEmpty {
                        viewModel.removeTask(task: task, from: tempCategory)
                    } else {
                        viewModel.updateTaskTitle(task: task, newTitle: newValue)
                    }
                    hasUnsavedChanges = true
                }
            )
            
            TextField("task-add", text: taskTitleBinding)
                .foregroundColor(categoryColor)
                .placeholder(when: task.title.isEmpty) {
                    Text("task-add").foregroundColor(categoryColor)
                }
                .strikethrough(task.isCompleted)
            Spacer()
        }
        .opacity(task.isCompleted ? 0.5 : 1.0)
        .padding(.horizontal)
    }
    
    private var newTaskRow: some View {
        HStack {
            Button(action: {
                let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTitle.isEmpty {
                    addNewTask(title: trimmedTitle)
                    newTaskTitle = ""
                }
            }) {
                Image(systemName: "square")
                    .foregroundColor(categoryColor)
                    .bold()
            }
            TextEditor(text: $newTaskTitle)
                .frame(height: 40)
                .foregroundColor(categoryColor)
                .onChange(of: newTaskTitle) { newValue in
                    if newValue.contains("\n") {
                        let trimmedTitle = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedTitle.isEmpty {
                            addNewTask(title: trimmedTitle)
                        }
                        newTaskTitle = ""
                    }
                }
                .onSubmit {
                    let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTitle.isEmpty {
                        addNewTask(title: trimmedTitle)
                        newTaskTitle = ""
                    }
                }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func addNewTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        let newTask = Task(context: viewModel.context)
        newTask.id = UUID()
        newTask.title = title
        newTask.isCompleted = false
        newTask.creationDate = Date() // Fecha de creación
        newTask.category = tempCategory
        tempCategory.addToTasks(newTask)
        hasUnsavedChanges = true
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
