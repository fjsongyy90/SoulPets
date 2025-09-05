import Foundation

extension Date {
    /// 将日期转换为人性化的相对时间字符串
    /// - Returns: 相对时间字符串 (Today, Yesterday, Tuesday, Sep 3, Dec 25, 2024)
    func formatRelativeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // 检查是否为今天
        if calendar.isDateInToday(self) {
            return String(localized: "Today")
        }
        
        // 检查是否为昨天
        if calendar.isDateInYesterday(self) {
            return String(localized: "Yesterday")
        }
        
        // 检查是否在过去7天内
        let daysBetween = calendar.dateComponents([.day], from: self, to: now).day ?? 0
        if daysBetween <= 7 && daysBetween > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // 星期几
            return formatter.string(from: self)
        }
        
        // 检查是否在今年
        let currentYear = calendar.component(.year, from: now)
        let dateYear = calendar.component(.year, from: self)
        
        if currentYear == dateYear {
            // 今年内：显示月日 (Sep 3)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else {
            // 往年：显示月日年 (Dec 25, 2024)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: self)
        }
    }
    
    /// 获取用于显示的详细时间字符串（用于悬停或详情页）
    /// - Returns: 完整的日期时间字符串
    func formatDetailedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
