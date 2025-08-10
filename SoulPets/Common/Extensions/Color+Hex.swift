import SwiftUI

extension Color {
    /// 通过十六进制字符串创建颜色
    /// - Parameter hex: 十六进制颜色字符串，支持 "#RRGGBB" 或 "RRGGBB" 格式
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 应用主题颜色
extension Color {
    /// 应用背景色
    static let appBackground = Color(hex: "FDFBF8")
    
    /// 应用主强调色
    static let appAccent = Color(hex: "E5B487")
    
    /// 卡片背景色
    static let cardBackground = Color.white
    
    /// 分割线颜色
    static let dividerColor = Color.gray.opacity(0.2)
} 