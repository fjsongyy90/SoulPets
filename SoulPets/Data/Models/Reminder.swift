import Foundation
import SwiftData

/// 重复单位枚举
enum RepeatUnit: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

@Model
final class Reminder {
    // MARK: - 属性
    var id: UUID
    var startDate: Date
    var notes: String?
    var repeatInterval: Int?
    var repeatUnit: RepeatUnit?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship(deleteRule: .nullify)
    var tag: Tag
    
    @Relationship(deleteRule: .nullify)
    var pets: [Pet]?
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderCompletion.reminder)
    var completions: [ReminderCompletion]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        startDate: Date,
        notes: String? = nil,
        repeatInterval: Int? = nil,
        repeatUnit: RepeatUnit? = nil,
        tag: Tag,
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
    // MARK: - 属性
    var id: UUID
    var completionDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship(deleteRule: .nullify)
    var reminder: Reminder
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        completionDate: Date,
        reminder: Reminder,
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
        guard let interval = repeatInterval, let unit = repeatUnit else { return false }
        
        // 计算从开始日期到给定日期经过的单位数
        var components: DateComponents
        switch unit {
        case .daily:
            components = calendar.dateComponents([.day], from: startDate, to: date)
            guard let days = components.day else { return false }
            return days % interval == 0
            
        case .weekly:
            components = calendar.dateComponents([.weekOfYear], from: startDate, to: date)
            guard let weeks = components.weekOfYear else { return false }
            return weeks % interval == 0
            
        case .monthly:
            components = calendar.dateComponents([.month], from: startDate, to: date)
            guard let months = components.month else { return false }
            return months % interval == 0
            
        case .yearly:
            components = calendar.dateComponents([.year], from: startDate, to: date)
            guard let years = components.year else { return false }
            return years % interval == 0
        }
    }
    
    /// 生成提醒标题
    var title: String {
        return tag.name
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