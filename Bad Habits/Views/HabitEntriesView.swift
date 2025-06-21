import SwiftUI

struct HabitEntriesView: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    @State private var showingAddColumn = false
    @State private var showingAddCategory = false
    @State private var showingSettings = false
    @State private var entryToEdit: HabitEntry?
    @Namespace private var scrollNamespace // For scrolling
    @State private var isPanelMinimized = false
    @State private var currentWeekStart: Date = Calendar.current.startOfWeek(for: Date())
    @State private var showingMetrics = false
    @State private var scrollPosition: CGFloat = 0 // Track scroll position
    @State private var shouldMaintainScrollPosition = false // Flag to maintain position

    var body: some View {
        NavigationView {
            ZStack {
                Color.grayLightBg.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            // Inline Edit Entry Panel
                            if let entry = entryToEdit {
                                InlineEditEntryPanel(
                                    entry: entry,
                                    onSave: { updatedEntry in
                                        viewModel.updateEntry(updatedEntry)
                                        entryToEdit = nil
                                    },
                                    onCancel: {
                                        entryToEdit = nil
                                    },
                                    isMinimized: $isPanelMinimized
                                )
                                .id("editEntryPanel")
                            } else {
                                VStack(alignment: .leading, spacing: 0) {
                                    AddEntryPanel(isMinimized: $isPanelMinimized)
                                        .environmentObject(viewModel)
                                }
                            }
                            // Recent Entries
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Entries")
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.grayPrimary)
                                    Text(weekRangeString(for: currentWeekStart))
                                        .font(.subheadline)
                                        .foregroundColor(.graySecondary)
                                }
                                if entriesForCurrentWeek.isEmpty {
                                    HStack {
                                        Spacer()
                                        Text("No entries for this week!")
                                            .foregroundColor(Color.graySecondary)
                                            .font(.headline)
                                            .padding(.vertical, 32)
                                        Spacer()
                                    }
                                } else {
                                    ForEach(entriesForCurrentWeek) { entry in
                                        ModernHabitEntryCard(entry: entry) {
                                            entryToEdit = entry
                                        } onDelete: {
                                            viewModel.deleteEntry(entry)
                                        }
                                    }
                                }
                                // Navigation buttons at the bottom
                                HStack(spacing: 32) {
                                    Button(action: {
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                        shouldMaintainScrollPosition = true
                                        currentWeekStart = earliestWeekStart
                                    }) {
                                        Image(systemName: "chevron.left.2")
                                            .font(.title2)
                                            .foregroundColor({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                                return currentWeekStart > earliestWeekStart ? .primaryBlue : .grayTertiary
                                            }())
                                            .frame(width: 48, height: 48)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                                return currentWeekStart > earliestWeekStart ? Color.primaryBlue : Color.grayBorder
                                            }(), lineWidth: 2))
                                    }
                                    .disabled({
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                        return currentWeekStart <= earliestWeekStart
                                    }())
                                    
                                    Button(action: {
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                        let prev = previousWeek(from: currentWeekStart)
                                        if prev >= earliestWeekStart {
                                            shouldMaintainScrollPosition = true
                                            currentWeekStart = prev
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.title2)
                                            .foregroundColor({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                                return currentWeekStart > earliestWeekStart ? .primaryBlue : .grayTertiary
                                            }())
                                            .frame(width: 48, height: 48)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                                return currentWeekStart > earliestWeekStart ? Color.primaryBlue : Color.grayBorder
                                            }(), lineWidth: 2))
                                    }
                                    .disabled({
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let earliestWeekStart = calendar.startOfWeek(for: calendar.date(byAdding: .year, value: -1, to: today)!)
                                        return currentWeekStart <= earliestWeekStart
                                    }())
                                    
                                    Button(action: {
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let latestWeekStart = calendar.startOfWeek(for: today)
                                        let next = nextWeek(from: currentWeekStart)
                                        if next <= latestWeekStart {
                                            shouldMaintainScrollPosition = true
                                            currentWeekStart = next
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .foregroundColor({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let latestWeekStart = calendar.startOfWeek(for: today)
                                                return currentWeekStart < latestWeekStart ? .primaryBlue : .grayTertiary
                                            }())
                                            .frame(width: 48, height: 48)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let latestWeekStart = calendar.startOfWeek(for: today)
                                                return currentWeekStart < latestWeekStart ? Color.primaryBlue : Color.grayBorder
                                            }(), lineWidth: 2))
                                    }
                                    .disabled({
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let latestWeekStart = calendar.startOfWeek(for: today)
                                        return currentWeekStart >= latestWeekStart
                                    }())
                                    
                                    Button(action: {
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let latestWeekStart = calendar.startOfWeek(for: today)
                                        shouldMaintainScrollPosition = true
                                        currentWeekStart = latestWeekStart
                                    }) {
                                        Image(systemName: "chevron.right.2")
                                            .font(.title2)
                                            .foregroundColor({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let latestWeekStart = calendar.startOfWeek(for: today)
                                                return currentWeekStart < latestWeekStart ? .primaryBlue : .grayTertiary
                                            }())
                                            .frame(width: 48, height: 48)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke({
                                                let calendar = Calendar.current
                                                let today = Date()
                                                let latestWeekStart = calendar.startOfWeek(for: today)
                                                return currentWeekStart < latestWeekStart ? Color.primaryBlue : Color.grayBorder
                                            }(), lineWidth: 2))
                                    }
                                    .disabled({
                                        let calendar = Calendar.current
                                        let today = Date()
                                        let latestWeekStart = calendar.startOfWeek(for: today)
                                        return currentWeekStart >= latestWeekStart
                                    }())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                                .alignmentGuide(.bottom) { d in d[.bottom] }
                            }
                            .id("entriesSection")
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
                            .padding(.horizontal)
                            Spacer(minLength: 24)
                                .id("bottomSpacer")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Dismiss keyboard when tapping on content
                            hideKeyboard()
                        }
                    }
                    .onChange(of: entryToEdit) { newValue in
                        if newValue != nil {
                            isPanelMinimized = false
                            withAnimation {
                                proxy.scrollTo("editEntryPanel", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: currentWeekStart) { newValue in
                        if shouldMaintainScrollPosition {
                            // Immediately scroll to bottom without any animation
                            DispatchQueue.main.async {
                                withAnimation(.none) {
                                    proxy.scrollTo("bottomSpacer", anchor: .bottom)
                                }
                                shouldMaintainScrollPosition = false
                            }
                        }
                    }
                }
                .onAppear {
                    // Start maximized if no entries, otherwise minimized
                    isPanelMinimized = !viewModel.entries.isEmpty
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
                .sheet(isPresented: $showingMetrics) {
                    MetricsView()
                }
            }
        }
    }

    // Helper to get all week start dates from entries
    private var allWeekStartDates: [Date] {
        let calendar = Calendar.current
        let weekStarts = Set(viewModel.entries.map { calendar.startOfWeek(for: $0.date) })
        return weekStarts.sorted(by: >)
    }

    // Helper to get entries for the current week
    private var entriesForCurrentWeek: [HabitEntry] {
        let calendar = Calendar.current
        let weekStart = currentWeekStart
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return viewModel.entries.filter { $0.date >= weekStart && $0.date < weekEnd }
            .sorted(by: { $0.date > $1.date })
    }

    // Helper to format week range
    private func weekRangeString(for weekStart: Date) -> String {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd/yyyy"
        return "Week of \(formatter.string(from: weekStart))–\(formatter.string(from: weekEnd))"
    }

    // Helper to get next/previous week
    func previousWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -7, to: date) ?? date
    }
    func nextWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 7, to: date) ?? date
    }
}

// AddEntryPanel is a copy of AddEntryView but as an inline panel, not a modal
struct AddEntryPanel: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    @State private var category: HabitCategory? = nil
    @State private var notes = ""
    @State private var customFields: [String: CustomFieldValue] = [:]
    @State private var date = Date()
    @State private var showingDatePicker = false
    @Binding var isMinimized: Bool
    @State private var showReasonError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Add entry")
                    .font(.title)
                    .bold()
                Spacer()
                Image(systemName: isMinimized ? "chevron.down" : "chevron.up")
                    .foregroundColor(.grayTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isMinimized.toggle()
            }
            if !isMinimized {
                // Reason Picker (with error highlight)
                Menu {
                    ForEach(viewModel.categories) { cat in
                        Button(cat.name.capitalized) { category = cat; showReasonError = false }
                    }
                } label: {
                    HStack {
                        Text(category?.name.capitalized ?? "Select reason")
                            .foregroundColor(category == nil ? .grayTertiary : .grayPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.grayTertiary)
                    }
                    .padding()
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(showReasonError ? Color.errorRed : Color.grayBorder, lineWidth: 1.5))
                }
                if showReasonError {
                    Text("Please select a reason.")
                        .font(.caption)
                        .foregroundColor(.errorRed)
                        .padding(.leading, 4)
                }
                // Date & Time
                HStack(spacing: 16) {
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text(date, formatter: dateTimeFormatter)
                                .foregroundColor(.grayPrimary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.grayTertiary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                    }
                }
                .sheet(isPresented: $showingDatePicker) {
                    VStack {
                        DatePicker("Select Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                        Button("Done") { showingDatePicker = false }
                            .padding()
                    }
                    .presentationDetents([.medium])
                }
                // Notes (with placeholder)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                        .foregroundColor(.grayPrimary)
                    if notes.isEmpty {
                        Text("Add additional notes")
                            .foregroundColor(.grayTertiary)
                            .font(.body)
                            .padding(.leading, 14)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                // Custom Fields
                if !viewModel.customColumns.isEmpty {
                    ForEach(viewModel.customColumns) { column in
                        CustomFieldInput(
                            column: column,
                            value: Binding(
                                get: { customFields[column.name] ?? .string("") },
                                set: { customFields[column.name] = $0 }
                            )
                        )
                        .modifier(CustomFieldStyle())
                    }
                }
                // Add Entry Button
                Button(action: {
                    if category == nil {
                        showReasonError = true
                        return
                    }
                    let entry = HabitEntry(
                        date: date,
                        category: category!,
                        notes: notes,
                        customFields: customFields
                    )
                    viewModel.addEntry(entry)
                    // Reset fields
                    notes = ""
                    customFields = [:]
                    date = Date()
                    category = nil
                    showReasonError = false
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Entry")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.grayCardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
    }
}

struct ModernHabitEntryCard: View {
    let entry: HabitEntry
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category.name.capitalized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primaryBlue)
                    .padding(.bottom, 2)
                Text("\(entry.date, formatter: isoDateTimeFormatter)")
                    .font(.system(size: 15))
                    .foregroundColor(.graySecondary)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.system(size: 15))
                        .foregroundColor(.grayPrimary)
                        .padding(.top, 2)
                }
                if !entry.customFields.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(entry.customFields.keys.sorted()), id: \.self) { key in
                            if let value = entry.customFields[key] {
                                switch value {
                                case .string(let str):
                                    if !str.isEmpty {
                                        HStack(spacing: 4) {
                                            Text(key + ":")
                                                .font(.caption)
                                                .foregroundColor(.graySecondary)
                                            Text(str)
                                                .font(.caption)
                                                .foregroundColor(.grayPrimary)
                                        }
                                    }
                                case .boolean(let bool):
                                    HStack(spacing: 4) {
                                        Text(key + ":")
                                            .font(.caption)
                                            .foregroundColor(.graySecondary)
                                        Text(bool ? "Yes" : "No")
                                            .font(.caption)
                                            .foregroundColor(.grayPrimary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: { onEdit?() }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.grayTertiary)
                        .font(.system(size: 18, weight: .medium))
                }
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.errorRed)
                        .font(.system(size: 18, weight: .medium))
                }
            }
        }
        .padding(20)
        .background(Color.grayCardBg)
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.vertical, 6)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

private let modernDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

private let isoDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd 'at' h:mm a"
    formatter.locale = Locale.current
    return formatter
}()

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

struct SettingsView: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    @Binding var showingAddColumn: Bool
    @Binding var showingAddCategory: Bool
    
    @State private var newCategory: String = ""
    @State private var newColumnName: String = ""
    @State private var newColumnType: CustomColumnType = .string
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color.grayLightBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Google Drive Sync Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.googleDriveService.isAuthenticated ? "icloud" : "icloud.slash")
                                .font(.system(size: 32, weight: .regular))
                                .foregroundColor(viewModel.googleDriveService.isAuthenticated ? .green : .grayTertiary)
                            Text("Google Drive Sync")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.grayPrimary)
                        }
                        Text(viewModel.googleDriveService.isAuthenticated ? 
                             "Connected to Google Drive. Data syncs automatically." :
                             "Connect Google Drive to sync your data automatically.")
                            .font(.body)
                            .foregroundColor(.graySecondary)
                        
                        // Note about Google Sheets
                        if viewModel.googleDriveService.isAuthenticated {
                            Text("Note: Data is stored as a Google Sheet called Bad Habits Data.")
                                .font(.caption)
                                .foregroundColor(.grayTertiary)
                                .padding(.top, 4)
                        }
                        
                        // Last Synced information
                        if viewModel.googleDriveService.isAuthenticated, let lastSynced = viewModel.googleDriveService.lastSynced {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.grayTertiary)
                                Text("Last synced: \(lastSynced, formatter: dateTimeFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.graySecondary)
                            }
                        }
                        
                        if viewModel.googleDriveService.isAuthenticated {
                            VStack(spacing: 12) {
                                Button(action: {
                                    viewModel.syncWithGoogleDrive()
                                }) {
                                    HStack {
                                        if viewModel.googleDriveService.isSyncing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                        Text(viewModel.googleDriveService.isSyncing ? "Syncing..." : "Sync Now")
                                    }
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primaryBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.googleDriveService.isSyncing)
                                
                                Button(action: {
                                    viewModel.signOutFromGoogleDrive()
                                }) {
                                    Text("Disconnect Google Drive")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(12)
                                }
                                .disabled(viewModel.googleDriveService.isSyncing)
                            }
                        } else {
                            Button(action: {
                                viewModel.signInToGoogleDrive()
                            }) {
                                HStack {
                                    if viewModel.googleDriveService.isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                    }
                                    Text(viewModel.googleDriveService.isSyncing ? "Connecting..." : "Connect Google Drive")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.googleDriveService.isSyncing)
                        }
                        
                        // Error message
                        if let error = viewModel.googleDriveService.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
                    .padding(.horizontal)
                    
                    // Reason Options Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Reason Options")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.grayPrimary)
                        HStack(spacing: 12) {
                            TextField("Add new reason...", text: $newCategory)
                                .padding(12)
                                .background(Color.grayCardBg)
                                .cornerRadius(8)
                            Button(action: {
                                let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    viewModel.addCategory(name: trimmed)
                                    newCategory = ""
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.primaryBlue)
                                    .cornerRadius(8)
                            }
                        }
                        VStack(spacing: 0) {
                            ForEach(viewModel.categories) { cat in
                                HStack {
                                    Text(cat.name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.grayPrimary)
                                    Spacer()
                                    if cat.isCustom {
                                        Button(action: { viewModel.deleteCategory(cat) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.errorRed)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 8)
                                .background(Color.grayCardBg.opacity(0.5))
                                .cornerRadius(6)
                                .padding(.bottom, 2)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
                    .padding(.horizontal)
                    
                    // Custom Columns Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Custom Columns")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.grayPrimary)
                        TextField("Column name...", text: $newColumnName)
                            .padding(12)
                            .background(Color.grayCardBg)
                            .cornerRadius(8)
                        // Custom dropdown for type
                        Menu {
                            Button("Text") { newColumnType = .string }
                            Button("Yes/No") { newColumnType = .boolean }
                        } label: {
                            HStack {
                                Text(newColumnType == .string ? "Text" : "Yes/No")
                                    .foregroundColor(.primaryBlue)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.grayTertiary)
                            }
                            .padding()
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                        }
                        Button(action: {
                            let trimmed = newColumnName.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                viewModel.addCustomColumn(name: trimmed, type: newColumnType)
                                newColumnName = ""
                                newColumnType = .string
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Column")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        // List custom columns with delete button
                        VStack(spacing: 0) {
                            ForEach(viewModel.customColumns) { column in
                                HStack {
                                    Text(column.name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.grayPrimary)
                                    Spacer()
                                    Button(action: { viewModel.customColumns.removeAll { $0.id == column.id } }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.errorRed)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 8)
                                .background(Color.grayCardBg.opacity(0.5))
                                .cornerRadius(6)
                                .padding(.bottom, 2)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
                    .padding(.horizontal)
                    
                    // Delete Account Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.errorRed)
                            Text("Delete Account")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.errorRed)
                        }
                        Text("This will permanently delete all your data including entries, categories, and custom columns. This action cannot be undone.")
                            .font(.body)
                            .foregroundColor(.grayPrimary)
                        Button(action: { showDeleteAlert = true }) {
                            Text("Delete All Data")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.errorRed)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(Color.errorRed.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.errorRed.opacity(0.3)))
                    .padding(.horizontal)
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Delete All Data?"),
                            message: Text("This cannot be undone. Are you sure?"),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.clearAllData()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping on content
                    hideKeyboard()
                }
            }
        }
    }
}

struct HabitEntryRow: View {
    let entry: HabitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.system(.body, design: .default))
                Text(entry.date, style: .time)
                    .font(.system(.body, design: .default))
                Spacer()
                Text(entry.category.name.capitalized)
                    .font(.system(.caption, design: .default))
                    .padding(4)
                    .background(categoryColor(for: entry.category))
                    .cornerRadius(4)
            }
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.system(.body, design: .default))
            }
            
            ForEach(Array(entry.customFields.keys.sorted()), id: \.self) { key in
                if let value = entry.customFields[key] {
                    HStack {
                        Text(key)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.graySecondary)
                        Text(value.stringValue)
                            .font(.system(.caption, design: .default))
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.grayCardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.grayBorder))
        .padding(4)
    }
    
    private func categoryColor(for category: HabitCategory) -> Color {
        if category.isCustom {
            return .purple.opacity(0.2)
        }
        switch category.name {
        case "Relax": return .blue.opacity(0.2)
        case "Reward": return .green.opacity(0.2)
        case "Focus": return .purple.opacity(0.2)
        case "Fun": return .orange.opacity(0.2)
        case "Human Need": return .orange.opacity(0.2)
        default: return .gray.opacity(0.2)
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HabitViewModel
    
    @State private var categoryName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.grayLightBg.ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
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
                                            .foregroundColor(Color.errorRed)
                                    }
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
            VStack(alignment: .leading, spacing: 8) {
                Text(column.name)
                    .font(.caption)
                    .foregroundColor(.graySecondary)
                TextField(column.name, text: Binding(
                    get: {
                        if case .string(let str) = value {
                            return str
                        }
                        return ""
                    },
                    set: { value = .string($0) }
                ))
            }
        case .boolean:
            HStack {
                Text(column.name)
                    .font(.body)
                    .foregroundColor(.grayPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: {
                        if case .boolean(let bool) = value {
                            return bool
                        }
                        return false
                    },
                    set: { value = .boolean($0) }
                ))
                .labelsHidden()
            }
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
            ZStack {
                Color.grayLightBg.ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                Form {
                    Section(header: Text("Column Details")) {
                        TextField("Column Name", text: $columnName)
                        Picker("Type", selection: $columnType) {
                            Text("Text").tag(CustomColumnType.string)
                            Text("Yes/No").tag(CustomColumnType.boolean)
                        }
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

struct InlineEditEntryPanel: View {
    @EnvironmentObject private var viewModel: HabitViewModel
    let entry: HabitEntry
    var onSave: (HabitEntry) -> Void
    var onCancel: () -> Void
    @Binding var isMinimized: Bool
    @State private var category: HabitCategory
    @State private var notes: String
    @State private var customFields: [String: CustomFieldValue]
    @State private var date: Date
    @State private var showingDatePicker = false

    init(entry: HabitEntry, onSave: @escaping (HabitEntry) -> Void, onCancel: @escaping () -> Void, isMinimized: Binding<Bool>) {
        self.entry = entry
        self.onSave = onSave
        self.onCancel = onCancel
        self._isMinimized = isMinimized
        _category = State(initialValue: entry.category)
        _notes = State(initialValue: entry.notes)
        _customFields = State(initialValue: entry.customFields)
        _date = State(initialValue: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Edit entry")
                    .font(.title)
                    .bold()
                Spacer()
                Button(action: { isMinimized.toggle() }) {
                    Image(systemName: isMinimized ? "chevron.down" : "chevron.up")
                        .foregroundColor(.grayTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isMinimized.toggle()
            }
            if !isMinimized {
                // Reason Picker (no header)
                Menu {
                    ForEach(viewModel.categories) { cat in
                        Button(cat.name.capitalized) { category = cat }
                    }
                } label: {
                    HStack {
                        Text(category.name.capitalized)
                            .foregroundColor(.grayPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.grayTertiary)
                    }
                    .padding()
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                }
                // Date & Time
                HStack(spacing: 16) {
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text(date, formatter: dateTimeFormatter)
                                .foregroundColor(.grayPrimary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.grayTertiary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                    }
                }
                .sheet(isPresented: $showingDatePicker) {
                    VStack {
                        DatePicker("Select Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                        Button("Done") { showingDatePicker = false }
                            .padding()
                    }
                    .presentationDetents([.medium])
                }
                // Notes (with placeholder)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
                        .foregroundColor(.grayPrimary)
                    if notes.isEmpty {
                        Text("Add additional notes")
                            .foregroundColor(.grayTertiary)
                            .font(.body)
                            .padding(.leading, 14)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                    }
                }
                // Custom Fields
                if !viewModel.customColumns.isEmpty {
                    ForEach(viewModel.customColumns) { column in
                        CustomFieldInput(
                            column: column,
                            value: Binding(
                                get: { customFields[column.name] ?? .string("") },
                                set: { customFields[column.name] = $0 }
                            )
                        )
                        .modifier(CustomFieldStyle())
                    }
                }
                // Cancel/Save Buttons
                HStack {
                    Button(action: { onCancel() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.grayPrimary)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.grayBorder))
                    }
                    Button(action: {
                        let updatedEntry = HabitEntry(
                            id: entry.id,
                            date: date,
                            category: category,
                            notes: notes,
                            customFields: customFields
                        )
                        onSave(updatedEntry)
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Update")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.grayCardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.grayBorder))
        .padding(.horizontal)
    }
}

// Custom modifier for custom field style
struct CustomFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grayBorder))
            .padding(.vertical, 4)
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

// Helper function to hide keyboard
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
} 