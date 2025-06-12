import SwiftUI

struct HabitEntriesView: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    @State private var showingAddEntry = false
    @State private var showingAddColumn = false
    @State private var showingAddCategory = false
    @State private var showingSettings = false
    @State private var entryToEdit: HabitEntry?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.entries.sorted(by: { $0.date > $1.date })) { entry in
                    HabitEntryRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            entryToEdit = entry
                        }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle(viewModel.habitName.isEmpty ? "Habit Entries" : "Your Habit: \(viewModel.habitName)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(showingAddColumn: $showingAddColumn, showingAddCategory: $showingAddCategory)
            }
            .sheet(isPresented: $showingAddColumn) {
                AddColumnView()
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $entryToEdit) { entry in
                EditEntryView(entry: entry)
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        let sortedEntries = viewModel.entries.sorted(by: { $0.date > $1.date })
        offsets.forEach { index in
            if let entryToDelete = viewModel.entries.first(where: { $0.id == sortedEntries[index].id }) {
                viewModel.deleteEntry(entryToDelete)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    @Binding var showingAddColumn: Bool
    @Binding var showingAddCategory: Bool
    @State private var habitName: String
    
    init(showingAddColumn: Binding<Bool>, showingAddCategory: Binding<Bool>) {
        self._showingAddColumn = showingAddColumn
        self._showingAddCategory = showingAddCategory
        self._habitName = State(initialValue: HabitViewModel().habitName)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Habit Name")) {
                    TextField("Enter habit name", text: $habitName)
                        .onChange(of: habitName) { newValue in
                            viewModel.updateHabitName(newValue)
                        }
                }
                
                Section(header: Text("Customization")) {
                    Button(action: { 
                        showingAddCategory = true
                    }) {
                        Label("Manage Categories", systemImage: "tag")
                    }
                    
                    Button(action: { 
                        showingAddColumn = true
                    }) {
                        Label("Manage Custom Columns", systemImage: "plus.rectangle.on.rectangle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct HabitEntryRow: View {
    let entry: HabitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.subheadline)
                Text(entry.date, style: .time)
                    .font(.subheadline)
                Spacer()
                Text(entry.category.name)
                    .font(.caption)
                    .padding(4)
                    .background(categoryColor(for: entry.category))
                    .cornerRadius(4)
            }
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.body)
            }
            
            ForEach(Array(entry.customFields.keys.sorted()), id: \.self) { key in
                if let value = entry.customFields[key] {
                    HStack {
                        Text(key)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(value.stringValue)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(for category: HabitCategory) -> Color {
        if category.isCustom {
            return .purple.opacity(0.2)
        }
        switch category.name {
        case "RELAX": return .blue.opacity(0.2)
        case "REWARD": return .green.opacity(0.2)
        case "FOCUS": return .purple.opacity(0.2)
        case "HUMAN NEED": return .orange.opacity(0.2)
        default: return .gray.opacity(0.2)
        }
    }
}

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    
    @State private var category: HabitCategory
    @State private var notes = ""
    @State private var customFields: [String: CustomFieldValue] = [:]
    @State private var date = Date()
    @State private var showingDatePicker = false
    
    init() {
        _category = State(initialValue: HabitCategory.defaultCategories[0])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date & Time")) {
                    HStack {
                        Text(date, style: .date)
                        Spacer()
                        Text(date, style: .time)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingDatePicker.toggle()
                    }
                    
                    if showingDatePicker {
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .onChange(of: date) { _ in
                                showingDatePicker = false
                            }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("Custom Fields")) {
                    ForEach(viewModel.customColumns) { column in
                        CustomFieldInput(
                            column: column,
                            value: Binding(
                                get: { customFields[column.name] ?? .string("") },
                                set: { customFields[column.name] = $0 }
                            )
                        )
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let entry = HabitEntry(
                        date: date,
                        category: category,
                        notes: notes,
                        customFields: customFields
                    )
                    viewModel.addEntry(entry)
                    dismiss()
                }
            )
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    
    @State private var categoryName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)
                }
                
                Section(header: Text("Existing Categories")) {
                    ForEach(viewModel.categories) { category in
                        HStack {
                            Text(category.name)
                            if category.isCustom {
                                Spacer()
                                Button(action: { viewModel.deleteCategory(category) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button("Add") {
                    viewModel.addCategory(name: categoryName)
                    categoryName = ""
                }
                .disabled(categoryName.isEmpty)
            )
        }
    }
}

struct CustomFieldInput: View {
    let column: CustomColumn
    @Binding var value: CustomFieldValue
    
    var body: some View {
        switch column.type {
        case .string:
            TextField(column.name, text: Binding(
                get: {
                    if case .string(let str) = value {
                        return str
                    }
                    return ""
                },
                set: { value = .string($0) }
            ))
        case .boolean:
            Toggle(column.name, isOn: Binding(
                get: {
                    if case .boolean(let bool) = value {
                        return bool
                    }
                    return false
                },
                set: { value = .boolean($0) }
            ))
        }
    }
}

struct AddColumnView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    
    @State private var columnName = ""
    @State private var columnType: CustomColumnType = .string
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Column Details")) {
                    TextField("Column Name", text: $columnName)
                    Picker("Type", selection: $columnType) {
                        Text("Text").tag(CustomColumnType.string)
                        Text("Yes/No").tag(CustomColumnType.boolean)
                    }
                }
            }
            .navigationTitle("Add Column")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    viewModel.addCustomColumn(name: columnName, type: columnType)
                    dismiss()
                }
                .disabled(columnName.isEmpty)
            )
        }
    }
}

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    
    let entry: HabitEntry
    @State private var category: HabitCategory
    @State private var notes: String
    @State private var customFields: [String: CustomFieldValue]
    @State private var date: Date
    @State private var showingDatePicker = false
    
    init(entry: HabitEntry) {
        self.entry = entry
        _category = State(initialValue: entry.category)
        _notes = State(initialValue: entry.notes)
        _customFields = State(initialValue: entry.customFields)
        _date = State(initialValue: entry.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date & Time")) {
                    HStack {
                        Text(date, style: .date)
                        Spacer()
                        Text(date, style: .time)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingDatePicker.toggle()
                    }
                    
                    if showingDatePicker {
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .onChange(of: date) { _ in
                                showingDatePicker = false
                            }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("Custom Fields")) {
                    ForEach(viewModel.customColumns) { column in
                        CustomFieldInput(
                            column: column,
                            value: Binding(
                                get: { customFields[column.name] ?? .string("") },
                                set: { customFields[column.name] = $0 }
                            )
                        )
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let updatedEntry = HabitEntry(
                        id: entry.id,
                        date: date,
                        category: category,
                        notes: notes,
                        customFields: customFields
                    )
                    viewModel.updateEntry(updatedEntry)
                    dismiss()
                }
            )
        }
    }
} 