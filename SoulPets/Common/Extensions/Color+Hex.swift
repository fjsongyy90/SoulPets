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
    /// 应用背景色 - 适应深色模式
    static let appBackground = Color(
        light: Color(hex: "FDFBF8"), 
        dark: Color(hex: "1C1C1E")
    )
    
    /// 应用主强调色 - 适应深色模式
    static let appAccent = Color(
        light: Color(hex: "E5B487"),
        dark: Color(hex: "E5B487")
    )
    
    /// 卡片背景色 - 适应深色模式
    static let cardBackground = Color(
        light: .white,
        dark: Color(hex: "2C2C2E")
    )
    
    /// 分割线颜色 - 适应深色模式
    static let dividerColor = Color(
        light: Color.gray.opacity(0.2),
        dark: Color.gray.opacity(0.3)
    )
}

// MARK: - 深色模式颜色初始化器
extension Color {
    /// 创建支持深色模式的动态颜色
    /// - Parameters:
    ///   - light: 浅色模式下的颜色
    ///   - dark: 深色模式下的颜色
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
} 