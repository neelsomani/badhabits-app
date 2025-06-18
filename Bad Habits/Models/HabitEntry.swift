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
        HabitCategory(name: "Relax"),
        HabitCategory(name: "Reward"),
        HabitCategory(name: "Focus"),
        HabitCategory(name: "Human Need"),
        HabitCategory(name: "Fun")
    ]
}

struct HabitEntry: Identifiable, Codable, Equatable {
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

extension CustomFieldValue: Equatable {
    static func == (lhs: CustomFieldValue, rhs: CustomFieldValue) -> Bool {
        switch (lhs, rhs) {
        case let (.string(a), .string(b)): return a == b
        case let (.boolean(a), .boolean(b)): return a == b
        default: return false
        }
    }
} 