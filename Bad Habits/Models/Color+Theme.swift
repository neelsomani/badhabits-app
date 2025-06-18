import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    static let primaryBlue = Color(hex: "#3b82f6")
    static let primaryBlueHover = Color(hex: "#2563eb")
    static let primaryBluePressed = Color(hex: "#1d4ed8")
    static let secondaryBlue = Color(hex: "#dbeafe")
    static let badgeText = Color(hex: "#1e40af")
    static let successGreen = Color(hex: "#10b981")
    static let successGreenLight = Color(hex: "#d1fae5")
    static let warningOrange = Color(hex: "#f59e0b")
    static let warningOrangeLight = Color(hex: "#fef3c7")
    static let errorRed = Color(hex: "#ef4444")
    static let errorRedLight = Color(hex: "#fee2e2")
    static let grayPrimary = Color(hex: "#111827")
    static let graySecondary = Color(hex: "#374151")
    static let grayTertiary = Color(hex: "#6b7280")
    static let grayDisabled = Color(hex: "#9ca3af")
    static let grayBorder = Color(hex: "#d1d5db")
    static let grayLightBg = Color(hex: "#f3f4f6")
    static let grayCardBg = Color(hex: "#f9fafb")
} 