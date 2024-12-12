import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var selectedSection: Int = 0
    @State private var showAddTaskView: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(getCurrentTime())
                    .font(.largeTitle)
                    .bold()
                Spacer()
                VStack {
                    Text(getCurrentDay())
                        .font(.title)
                    Text(getCurrentMonth())
                        .font(.title3)
                }
            }
            .padding()
            Picker("Sections", selection: $selectedSection) {
                Text("Próximamente").tag(0)
                Text("Vencidas").tag(1)
                Text("Completadas").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            List {
                if selectedSection == 0 {
                    ForEach(viewModel.upcomingTasks) { task in
                        TaskRow(task: task, viewModel: viewModel)
                    }
                } else if selectedSection == 1 {
                    ForEach(viewModel.overdueTasks) { task in
                        TaskRow(task: task, viewModel: viewModel, isEditable: false)
                    }
                } else if selectedSection == 2 {
                    ForEach(viewModel.completedTasks) { task in
                        TaskRow(task: task, viewModel: viewModel, isEditable: false)
                    }
                }
            }
            .listStyle(PlainListStyle())
            Button(action: {
                showAddTaskView = true
            }) {
                Text("Añadir Tarea")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showAddTaskView) {
                AddTaskView(viewModel: viewModel)
            }
            .padding()
        }
        .onAppear {
            viewModel.cleanOldTasks()
        }
    }
    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    func getCurrentDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }
    func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
}
    #Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}