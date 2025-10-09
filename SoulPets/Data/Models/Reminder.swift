import Foundation
import SwiftData

/// 重复单位枚举
enum RepeatUnit: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    /// 获取对应的 Calendar.Component
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily:
            return .day
        case .weekly:
            return .weekOfYear
        case .monthly:
            return .month
        case .yearly:
            return .year
        }
    }
}

@Model
final class Reminder {
    // MARK: - 属性 (CloudKit要求所有属性可选或有默认值)
    var id: UUID = UUID()
    var startDate: Date = Date()
    var notes: String?
    var repeatInterval: Int?
    var repeatUnit: RepeatUnit?  // CloudKit要求枚举类型必须可选(已经是可选)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系 (CloudKit要求关系可选)
    @Relationship(deleteRule: .nullify)
    var tag: Tag?
    
    // inverse已在Pet.reminders定义
    var pets: [Pet]?
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderCompletion.reminder)
    var completions: [ReminderCompletion]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        notes: String? = nil,
        repeatInterval: Int? = nil,
        repeatUnit: RepeatUnit? = nil,
        tag: Tag? = nil,
        pets: [Pet]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.notes = notes
        self.repeatInterval = repeatInterval
        self.repeatUnit = repeatUnit
        self.tag = tag
        self.pets = pets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ReminderCompletion {
    // MARK: - 属性 (CloudKit要求所有属性可选或有默认值)
    var id: UUID = UUID()
    var completionDate: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系 (CloudKit要求关系可选，inverse已在Reminder.completions定义)
    var reminder: Reminder?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        completionDate: Date = Date(),
        reminder: Reminder? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.completionDate = completionDate
        self.reminder = reminder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 提醒辅助方法
extension Reminder {
    /// 检查提醒是否在指定日期已完成
    func isCompletedOn(date: Date) -> Bool {
        guard let completions = completions else { return false }
        
        let calendar = Calendar.current
        return completions.contains { completion in
            calendar.isDate(completion.completionDate, inSameDayAs: date)
        }
    }
    
    /// 检查提醒是否今天已完成
    var isCompletedToday: Bool {
        return isCompletedOn(date: Date())
    }
    
    /// 计算给定日期是否需要提醒
    func needsReminderOn(date: Date) -> Bool {
        let calendar = Calendar.current
        
        // 如果日期早于开始日期，无需提醒
        if calendar.compare(date, to: startDate, toGranularity: .day) == .orderedAscending {
            return false
        }
        
        // 如果不是重复提醒
        if repeatInterval == nil || repeatUnit == nil {
            // 只有在开始日期当天需要提醒
            return calendar.isDate(date, inSameDayAs: startDate)
        }
        
        // 处理重复提醒
        guard let interval = repeatInterval, let unit = repeatUnit, interval > 0 else { return false }
        
        // 计算从开始日期到给定日期经过的单位数
        switch unit {
        case .daily:
            let components = calendar.dateComponents([.day], from: startDate, to: date)
            guard let days = components.day, days >= 0 else { return false }
            return days % interval == 0
            
        case .weekly:
            // 检查是否在同一周的同一天
            let startWeekday = calendar.component(.weekday, from: startDate)
            let targetWeekday = calendar.component(.weekday, from: date)
            
            if startWeekday != targetWeekday {
                return false
            }
            
            let components = calendar.dateComponents([.weekOfYear], from: startDate, to: date)
            guard let weeks = components.weekOfYear, weeks >= 0 else { return false }
            return weeks % interval == 0
            
        case .monthly:
            // 检查是否在同一月的同一天
            let startDay = calendar.component(.day, from: startDate)
            let targetDay = calendar.component(.day, from: date)
            
            // 处理月末日期的特殊情况
            let daysInTargetMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
            
            let effectiveTargetDay = min(startDay, daysInTargetMonth)
            
            if targetDay != effectiveTargetDay {
                return false
            }
            
            let components = calendar.dateComponents([.month], from: startDate, to: date)
            guard let months = components.month, months >= 0 else { return false }
            return months % interval == 0
            
        case .yearly:
            // 对于年度重复，检查月日是否匹配
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            let targetComponents = calendar.dateComponents([.month, .day], from: date)
            
            guard let startMonth = startComponents.month, let startDay = startComponents.day,
                  let targetMonth = targetComponents.month, let targetDay = targetComponents.day else {
                return false
            }
            
            // 检查是否是同一个月日
            if startMonth == targetMonth && startDay == targetDay {
                // 🔧 修复：对于年度重复，只要月日匹配且目标日期不早于起始日期即可
                // 不需要严格按年份间隔计算，因为生日每年都应该提醒
                let startYear = calendar.component(.year, from: startDate)
                let targetYear = calendar.component(.year, from: date)
                
                // 目标年份必须大于等于起始年份
                if targetYear >= startYear {
                    // 计算年份差
                    let yearDifference = targetYear - startYear
                    return yearDifference % interval == 0
                }
            }
            
            return false
        }
    }
    
    /// 生成提醒标题
    var title: String {
        return tag?.name ?? ""
    }
    
    /// 格式化重复规则为易读文本
    var repeatRuleText: String? {
        guard let interval = repeatInterval, let unit = repeatUnit else {
            return nil
        }
        
        if interval == 1 {
            switch unit {
            case .daily:
                return String(localized: "Every day")
            case .weekly:
                return String(localized: "Every week")
            case .monthly:
                return String(localized: "Every month")
            case .yearly:
                return String(localized: "Every year")
            }
        } else {
            switch unit {
            case .daily:
                return String(localized: "Every \(interval) days")
            case .weekly:
                return String(localized: "Every \(interval) weeks")
            case .monthly:
                return String(localized: "Every \(interval) months")
            case .yearly:
                return String(localized: "Every \(interval) years")
            }
        }
    }
} 