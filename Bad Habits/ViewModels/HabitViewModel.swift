import Foundation
import SwiftUI

class HabitViewModel: ObservableObject {
    @Published var entries: [HabitEntry] = []
    @Published var customColumns: [CustomColumn] = []
    @Published var categories: [HabitCategory] = HabitCategory.defaultCategories
    @Published var habitName: String = ""
    
    private let entriesKey = "habitEntries"
    private let columnsKey = "customColumns"
    private let categoriesKey = "customCategories"
    private let habitNameKey = "habitName"
    
    init() {
        loadData()
    }
    
    func addEntry(_ entry: HabitEntry) {
        entries.append(entry)
        saveData()
    }
    
    func updateEntry(_ entry: HabitEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveData()
        }
    }
    
    func deleteEntry(_ entry: HabitEntry) {
        entries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    func addCustomColumn(name: String, type: CustomColumnType) {
        let column = CustomColumn(name: name, type: type)
        customColumns.append(column)
        saveData()
    }
    
    func addCategory(name: String) {
        let category = HabitCategory(name: name, isCustom: true)
        categories.append(category)
        saveData()
    }
    
    func deleteCategory(_ category: HabitCategory) {
        guard category.isCustom else { return }
        categories.removeAll { $0.id == category.id }
        saveData()
    }
    
    func updateHabitName(_ name: String) {
        habitName = name
        saveData()
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
        UserDefaults.standard.set(habitName, forKey: habitNameKey)
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
        habitName = UserDefaults.standard.string(forKey: habitNameKey) ?? ""
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