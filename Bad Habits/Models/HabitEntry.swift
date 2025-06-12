import Foundation

struct HabitCategory: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let isCustom: Bool
    
    init(id: UUID = UUID(), name: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.isCustom = isCustom
    }
    
    static let defaultCategories: [HabitCategory] = [
        HabitCategory(name: "RELAX"),
        HabitCategory(name: "REWARD"),
        HabitCategory(name: "FOCUS"),
        HabitCategory(name: "HUMAN NEED")
    ]
}

struct HabitEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let category: HabitCategory
    let notes: String
    var customFields: [String: CustomFieldValue]
    
    init(id: UUID = UUID(), date: Date = Date(), category: HabitCategory, notes: String = "", customFields: [String: CustomFieldValue] = [:]) {
        self.id = id
        self.date = date
        self.category = category
        self.notes = notes
        self.customFields = customFields
    }
}

enum CustomFieldValue: Codable {
    case string(String)
    case boolean(Bool)
    
    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .boolean(let value): return value ? "Yes" : "No"
        }
    }
} 