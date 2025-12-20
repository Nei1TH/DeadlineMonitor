import SwiftUI

// MARK: - 1. Model

/// Represents a single deadline item.
/// Conforms to `Identifiable` for use in Lists, and `Codable` for JSON serialization.
struct DeadlineItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetDate: Date
    var createdDate: Date
    var isCompleted: Bool
    var completedDate: Date? // Records when the item was marked as completed

    init(id: UUID = UUID(), title: String, targetDate: Date, createdDate: Date = Date(), isCompleted: Bool = false, completedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.createdDate = createdDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
}

// MARK: - 2. ViewModel

/// Defines available sorting options for the deadline list.
enum SortOption: CaseIterable {
    case addedOrder
    case titleAZ
    case dateNearest
    
    /// Returns the next sort option in the cycle (for toggle button).
    var next: SortOption {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let nextIdx = (idx + 1) % all.count
        return all[nextIdx]
    }
    
    var iconName: String {
        switch self {
        case .addedOrder: return "list.bullet"
        case .titleAZ: return "textformat"
        case .dateNearest: return "clock"
        }
    }
    
    var description: String {
        switch self {
        case .addedOrder: return "Added Order"
        case .titleAZ: return "Title (A-Z)"
        case .dateNearest: return "Date (Nearest)"
        }
    }
}

/// Defines filtering options (Active vs Completed).
enum FilterOption: String, CaseIterable, Identifiable {
    case active = "Active"
    case completed = "Completed"
    
    var id: String { self.rawValue }
}

/// The ViewModel responsible for managing deadline data, sorting, filtering, and time updates.
class DeadlineViewModel: ObservableObject {
    @Published var deadlines: [DeadlineItem] = []
    @Published var now = Date()
    @Published var sortOption: SortOption = .addedOrder {
        didSet {
            sortDeadlines()
        }
    }
    @Published var filterOption: FilterOption = .active

    private var timer: Timer?
    private let jsonManager: JSONManager

    /// Returns the list of deadlines filtered by the selected `filterOption`.
    var filteredDeadlines: [DeadlineItem] {
        let filtered: [DeadlineItem]
        switch filterOption {
        case .active:
            filtered = deadlines.filter { !$0.isCompleted }
        case .completed:
            filtered = deadlines.filter { $0.isCompleted }
        }
        return filtered
    }

    init(fileURL: URL) {
        self.jsonManager = JSONManager(fileURL: fileURL)
        startTimer()
        loadData()
    }
    
    /// Loads data from the JSON file.
    /// If the file is empty or doesn't exist, it loads mock data for demonstration.
    func loadData() {
        let items = jsonManager.load()
        if items.isEmpty {
            if !jsonManager.fileExists() {
                addMockData()
            } else {
                deadlines = []
            }
        } else {
            deadlines = items
            cleanupOldCompletedItems() // Auto-delete old completed items
            sortDeadlines()
        }
    }
    
    /// Removes completed items that are older than 30 days.
    func cleanupOldCompletedItems() {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let initialCount = deadlines.count
        
        deadlines.removeAll { item in
            if let completedDate = item.completedDate {
                return item.isCompleted && completedDate < thirtyDaysAgo
            }
            return false
        }
        
        if deadlines.count != initialCount {
            print("🧹 Cleaned up \(initialCount - deadlines.count) old completed items.")
            saveData()
        }
    }
    
    /// Persists the current list of deadlines to the JSON file.
    func saveData() {
        jsonManager.save(items: deadlines)
    }

    /// Starts a timer to update the `now` property every second.
    /// This ensures the countdown timer in the UI stays fresh.
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.now = Date()
        }
    }

    /// Adds sample data for testing purposes.
    func addMockData() {
        let calendar = Calendar.current
        // Mock Data: 16 days, 12 days, 6 days, 3 days
        let d1 = calendar.date(byAdding: .day, value: 16, to: Date())!
        let d2 = calendar.date(byAdding: .day, value: 12, to: Date())!
        let d3 = calendar.date(byAdding: .day, value: 6, to: Date())!
        let d4 = calendar.date(byAdding: .day, value: 3, to: Date())!
        let d5 = calendar.date(byAdding: .day, value: 20, to: Date())!
        let d6 = calendar.date(byAdding: .day, value: 9, to: Date())!
        let d7 = calendar.date(byAdding: .day, value: 2, to: Date())!
        let d8 = calendar.date(byAdding: .hour, value: 5, to: Date())!

        deadlines = [
            DeadlineItem(title: "Semester Project", targetDate: d1),       // Blue (>14)
            DeadlineItem(title: "Mid-term Essay", targetDate: d2),         // Green (>7)
            DeadlineItem(title: "Lab Report", targetDate: d3),             // Orange (>3)
            DeadlineItem(title: "Quiz Preparation", targetDate: d4),       // Red (<=3)
            DeadlineItem(title: "Final Exam", targetDate: d5),
            DeadlineItem(title: "Presentation Slide", targetDate: d6),
            DeadlineItem(title: "Code Review", targetDate: d7),
            DeadlineItem(title: "Team Meeting", targetDate: d8)
        ]
        sortDeadlines()
        saveData()
    }

    func addNewDeadline(title: String, targetDate: Date) {
        deadlines.append(DeadlineItem(title: title, targetDate: targetDate))
        sortDeadlines()
        saveData()
    }

    func updateDeadline(id: UUID, newTitle: String, newTargetDate: Date) {
        if let index = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[index].title = newTitle
            deadlines[index].targetDate = newTargetDate
            sortDeadlines()
            saveData()
        }
    }

    func toggleCompletion(for item: DeadlineItem) {
        if let index = deadlines.firstIndex(where: { $0.id == item.id }) {
            deadlines[index].isCompleted.toggle()
            
            if deadlines[index].isCompleted {
                deadlines[index].completedDate = Date()
            } else {
                deadlines[index].completedDate = nil
            }
            
            saveData()
        }
    }

    func sortDeadlines() {
        switch sortOption {
        case .titleAZ:
            deadlines.sort { $0.title < $1.title }
        case .dateNearest:
            deadlines.sort { $0.targetDate < $1.targetDate }
        case .addedOrder:
            deadlines.sort { $0.createdDate < $1.createdDate }
        }
    }

    /// Formats the remaining time into a human-readable string.
    func timeRemainingString(target: Date) -> String {
        let diff = target.timeIntervalSince(now)
        if diff <= 0 { return "⚠️ Expired" }

        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60

        if days > 0 {
            return "\(days)day \(hours)hour"
        } else {
            return "\(hours)hour \(minutes)min \(seconds)sec"
        }
    }
    
    /// Determines the urgency color based on time remaining.
    /// Blue: > 2 weeks, Green: > 1 week, Orange: > 3 days, Red: <= 3 days.
    func urgencyColor(for item: DeadlineItem) -> Color {
        if item.isCompleted { return .gray }
        
        let diff = item.targetDate.timeIntervalSince(now)
        let days = diff / 86400
        
        if days > 14 {
            return .blue
        } else if days > 7 {
            return .green
        } else if days > 3 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 3. Views

/// View for adding a new deadline.
struct AddDeadlineView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DeadlineViewModel

    @State private var title = ""
    @State private var targetDate = Date().addingTimeInterval(86400) // Default to tomorrow
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Deadline Details")) {
                    TextField("Enter deadline title", text: $title)
                    DatePicker("Select target date", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    HStack {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }

                        Spacer()

                        Button("Add Deadline") {
                            viewModel.addNewDeadline(
                                title: title,
                                targetDate: targetDate
                            )
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(title.isEmpty || targetDate <= Date())
                    }
                }
            }
            .frame(maxWidth: 500)
        }
        .padding()
        .navigationTitle("Add New Deadline")
        }
}


/// View for editing an existing deadline.
struct EditDeadlineView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DeadlineViewModel
    var item: DeadlineItem

    @State private var title: String
    @State private var targetDate: Date
    
    init(viewModel: DeadlineViewModel, item: DeadlineItem) {
        self.viewModel = viewModel
        self.item = item
        _title = State(initialValue: item.title)
        _targetDate = State(initialValue: item.targetDate)
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Edit Deadline Details")) {
                    TextField("Enter deadline title", text: $title)
                    DatePicker("Select target date", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    HStack {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }

                        Spacer()

                        Button("Save Changes") {
                            viewModel.updateDeadline(
                                id: item.id,
                                newTitle: title,
                                newTargetDate: targetDate
                            )
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(title.isEmpty)
                    }
                }
            }
            .frame(maxWidth: 500)
        }
        .padding()
        .navigationTitle("Edit Deadline")
    }
}

/// The main content view displaying the list of deadlines.
struct ContentView: View {
    @StateObject private var viewModel: DeadlineViewModel
    @State private var isShowingAddSheet = false
    @State private var itemToEdit: DeadlineItem?
    
    /// Closure to handle the "Close Vault" action.
    var onClose: () -> Void

    init(fileURL: URL, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DeadlineViewModel(fileURL: fileURL))
        self.onClose = onClose
    }

    var body: some View {
        HStack {
            List {
                // Filter Segmented Control
                Picker("Filter", selection: $viewModel.filterOption) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)
                
                // Deadline List
                ForEach(viewModel.filteredDeadlines) { item in
                    DeadlineRow(item: item, viewModel: viewModel)
                        .padding(.vertical, 8)
                        .contextMenu {
                            Button(action: {
                                itemToEdit = item
                            }) {
                                Text("Edit")
                                Image(systemName: "pencil")
                            }
                            
                            Button(action: {
                                viewModel.toggleCompletion(for: item)
                            }) {
                                Text(item.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                                Image(systemName: item.isCompleted ? "arrow.uturn.backward" : "checkmark")
                            }
                        }
                }
            }
            .navigationTitle("Deadline Monitor")
            // Use SidebarListStyle for standard macOS sidebar appearance
            .listStyle(SidebarListStyle())
            .toolbar {
                // Leading Toolbar Item: Close Vault
                ToolbarItem(placement: .navigation) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle")
                        Text("Close Vault")
                    }
                }
                
                // Trailing Toolbar Items: Sort & Add
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        // Sort Toggle Button
                        Button(action: {
                            viewModel.sortOption = viewModel.sortOption.next
                        }) {
                            Image(systemName: viewModel.sortOption.iconName)
                                .help("Change Sort Order")
                        }
                        
                        // Add Button
                        Button(action: { isShowingAddSheet = true }) {
                            Image(systemName: "plus")
                                .help("Add New Deadline")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddDeadlineView(viewModel: viewModel)
        }
        .sheet(item: $itemToEdit) { item in
            EditDeadlineView(viewModel: viewModel, item: item)
        }
        // Minimum window size
        .frame(minWidth: 400, minHeight: 300)
    }
}

/// A single row view for the deadline list.
struct DeadlineRow: View {
    let item: DeadlineItem
    @ObservedObject var viewModel: DeadlineViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Urgency Indicator Bar
            Capsule()
                .fill(viewModel.urgencyColor(for: item))
                .frame(width: 4)
                .padding(.vertical, 4)
            
            // Title & Due Date
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body) // Normal weight, primary text
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                Text(item.targetDate, style: .date) + Text(" ") + Text(item.targetDate, style: .time)
                    .font(.caption) // Secondary/Caption style
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remaining Time (Primary Visual Element)
            if item.isCompleted {
                Text("Done")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.gray)
            } else {
                Text(viewModel.timeRemainingString(target: item.targetDate))
                    .font(.system(.title3, design: .monospaced)) // Larger, monospaced
                    .fontWeight(.bold) // Semibold or bold
                    .foregroundColor(viewModel.urgencyColor(for: item)) // Urgency color
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

// Preview provider for Xcode Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a dummy URL for preview purposes
        ContentView(fileURL: URL(fileURLWithPath: "/tmp/test.json"), onClose: {})
    }
}
