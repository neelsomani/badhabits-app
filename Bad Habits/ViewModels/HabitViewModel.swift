import Foundation
import SwiftUI
import Combine

class HabitViewModel: ObservableObject {
    @Published var entries: [HabitEntry] = []
    @Published var customColumns: [CustomColumn] = []
    @Published var categories: [HabitCategory] = HabitCategory.defaultCategories
    
    // Google Drive service
    let googleDriveService: GoogleDriveService
    
    private let entriesKey = "habitEntries"
    private let columnsKey = "customColumns"
    private let categoriesKey = "customCategories"
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Feature Flags
    
    static func isAIInsightsEnabled() -> Bool {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let aiInsightsEnabled = plist["AIInsightsEnabled"] as? Bool else {
            return false // Default to false if not found
        }
        return aiInsightsEnabled
    }
    
    init() {
        self.googleDriveService = GoogleDriveService()
        loadData()
        setupGoogleDriveSync()
        
        // Connect the service to this ViewModel
        googleDriveService.setViewModel(self)
        
        // Observe changes to the Google Drive service
        googleDriveService.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }
    
    deinit {
        // Save to Google Drive when app closes
        if googleDriveService.isAuthenticated {
            googleDriveService.pushDataToDrive(entries: entries)
        }
    }
    
    // MARK: - Google Drive Sync
    
    private func setupGoogleDriveSync() {
        // Listen for data updates from Google Drive
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGoogleDriveUpdate),
            name: .updateLocalData,
            object: nil
        )
        
        // Listen for authentication restoration
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationRestored),
            name: .authenticationRestored,
            object: nil
        )
        
        // Note: Authentication state will be restored asynchronously in GoogleDriveService.init()
        // Data will be pulled automatically after successful authentication restoration
    }
    
    @objc private func handleGoogleDriveUpdate(_ notification: Notification) {
        if let remoteEntries = notification.object as? [HabitEntry] {
            DispatchQueue.main.async {
                self.entries = remoteEntries
                self.saveData()
            }
        }
    }
    
    @objc private func handleAuthenticationRestored(_ notification: Notification) {
        // Authentication restored, data sync will begin automatically
    }
    
    func signInToGoogleDrive() {
        googleDriveService.signIn()
    }
    
    func signOutFromGoogleDrive() {
        googleDriveService.signOut()
    }
    
    func syncWithGoogleDrive() {
        googleDriveService.pullDataFromDrive()
    }
    
    func pushToGoogleDrive() {
        googleDriveService.pushDataToDrive(entries: entries)
    }
    
    func clearGoogleDriveError() {
        googleDriveService.clearError()
    }
    
    // MARK: - Google Drive Bindings
    
    // MARK: - Data Sync Helpers
    
    func getLocalEntries() -> [HabitEntry] {
        return entries
    }
    
    func addEntry(_ entry: HabitEntry) {
        entries.append(entry)
        saveData()
        pushToGoogleDrive()
    }
    
    func updateEntry(_ entry: HabitEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveData()
            pushToGoogleDrive()
        }
    }
    
    func deleteEntry(_ entry: HabitEntry) {
        entries.removeAll { $0.id == entry.id }
        saveData()
        pushToGoogleDrive()
    }
    
    func addCustomColumn(name: String, type: CustomColumnType) {
        let column = CustomColumn(name: name, type: type)
        customColumns.append(column)
        saveData()
        pushToGoogleDrive()
    }
    
    func addCategory(name: String) {
        let category = HabitCategory(name: name, isCustom: true)
        categories.append(category)
        saveData()
        pushToGoogleDrive()
    }
    
    func deleteCategory(_ category: HabitCategory) {
        guard category.isCustom else { return }
        categories.removeAll { $0.id == category.id }
        saveData()
        pushToGoogleDrive()
    }
    
    func clearAllData() {
        entries.removeAll()
        categories = HabitCategory.defaultCategories
        customColumns.removeAll()
        
        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: entriesKey)
        UserDefaults.standard.removeObject(forKey: columnsKey)
        UserDefaults.standard.removeObject(forKey: categoriesKey)
        
        // Disconnect from Google Drive
        signOutFromGoogleDrive()
    }
    
    // MARK: - Analytics
    
    func eventsThisWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        return entries.filter { $0.date >= startOfWeek }.count
    }
    
    func eventsThisMonth() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        return entries.filter { $0.date >= startOfMonth }.count
    }
    
    func eventsTrailingDays(_ days: Int) -> Int {
        guard days > 0 else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: startOfDay) else { return 0 }
        return entries.filter { $0.date >= startDate }.count
    }
    
    func weeklyEventsOverYear() -> [(Date, Int)] {
        let calendar = Calendar.current
        let today = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        
        var result: [(Date, Int)] = []
        var currentDate = oneYearAgo
        
        while currentDate <= today {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let count = entries.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            result.append((weekStart, count))
            
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }
        
        return result
    }

    // Monthly events over the past year
    func monthlyEventsOverYear() -> [(Date, Int)] {
        let calendar = Calendar.current
        let today = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        var result: [(Date, Int)] = []
        var currentDate = oneYearAgo
        while currentDate <= today {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let count = entries.filter { $0.date >= monthStart && $0.date < monthEnd }.count
            result.append((monthStart, count))
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        return result
    }

    // Reason breakdown for this week
    func reasonBreakdownThisWeek() -> [(String, Int)] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEntries = entries.filter { $0.date >= startOfWeek }
        let grouped = Dictionary(grouping: weekEntries, by: { $0.category.name.capitalized })
        return grouped.map { (key, value) in (key, value.count) }.sorted { $0.0 < $1.0 }
    }

    // Reason breakdown for this month
    func reasonBreakdownThisMonth() -> [(String, Int)] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let monthEntries = entries.filter { $0.date >= startOfMonth }
        let grouped = Dictionary(grouping: monthEntries, by: { $0.category.name.capitalized })
        return grouped.map { (key, value) in (key, value.count) }.sorted { $0.0 < $1.0 }
    }
    
    // Reason breakdown for a specific date range
    func reasonBreakdownForDateRange(startDate: Date, endDate: Date) -> [(String, Int)] {
        let rangeEntries = entries.filter { $0.date >= startDate && $0.date < endDate }
        let grouped = Dictionary(grouping: rangeEntries, by: { $0.category.name.capitalized })
        return grouped.map { (key, value) in (key, value.count) }.sorted { $0.0 < $1.0 }
    }
    
    // Reason breakdown for a specific week (given week start date)
    func reasonBreakdownForWeek(weekStart: Date) -> [(String, Int)] {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return reasonBreakdownForDateRange(startDate: weekStart, endDate: weekEnd)
    }
    
    // Reason breakdown for a specific month (given month start date)
    func reasonBreakdownForMonth(monthStart: Date) -> [(String, Int)] {
        let calendar = Calendar.current
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        return reasonBreakdownForDateRange(startDate: monthStart, endDate: monthEnd)
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
        if let encoded = try? JSONEncoder().encode(customColumns) {
            UserDefaults.standard.set(encoded, forKey: columnsKey)
        }
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([HabitEntry].self, from: data) {
            entries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: columnsKey),
           let decoded = try? JSONDecoder().decode([CustomColumn].self, from: data) {
            customColumns = decoded
        }
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([HabitCategory].self, from: data) {
            categories = decoded
        }
    }
}

struct CustomColumn: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: CustomColumnType
    
    init(id: UUID = UUID(), name: String, type: CustomColumnType) {
        self.id = id
        self.name = name
        self.type = type
    }
}

enum CustomColumnType: String, Codable {
    case string
    case boolean
} 
