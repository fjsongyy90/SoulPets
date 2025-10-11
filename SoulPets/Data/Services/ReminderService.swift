import Foundation
import SwiftData
import OSLog

/// 提醒服务，负责处理提醒相关的业务逻辑
class ReminderService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "Reminder")
    
    /// 获取今日待办提醒（包含逾期未完成 + 今日到期未完成）
    static func getTodayReminders(modelContext: ModelContext) -> [Reminder] {
        let today = Date()
        let calendar = Calendar.current
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            logger.info("📋 所有提醒总数: \(allReminders.count)")
            
            var todayReminders: [Reminder] = []
            
            for reminder in allReminders {
                // 检查是否有未完成的提醒（逾期 + 今日）
                if let nextReminderDate = getNextReminderDate(for: reminder, from: today) {
                    // 如果下一次提醒日期是今天或之前（逾期），且未完成
                    let comparison = calendar.compare(nextReminderDate, to: today, toGranularity: .day)
                    if (comparison == .orderedSame || comparison == .orderedAscending) && !reminder.isCompletedOn(date: nextReminderDate) {
                        todayReminders.append(reminder)
                        logger.info("📅 今日待办: \(reminder.tag?.name ?? "未知") - 日期: \(nextReminderDate)")
                    }
                }
            }
            
            return todayReminders
        } catch {
            logger.error("获取今日提醒失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取未来安排提醒（明天及以后的提醒）
    static func getUpcomingReminders(modelContext: ModelContext, daysAhead: Int = 30) -> [Reminder] {
        let calendar = Calendar.current
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            logger.info("📋 获取未来提醒: 所有提醒总数 \(allReminders.count)")
            
            var upcomingReminders: [Reminder] = []
            
            for reminder in allReminders {
                // 获取每个提醒的下一次发生日期
                // 🔧 getNextReminderDate 现在已经智能到可以自动跳过所有已完成的日期
                if let nextReminderDate = getNextReminderDate(for: reminder, from: today) {
                    // 如果下一次提醒日期是明天或以后
                    let comparison = calendar.compare(nextReminderDate, to: today, toGranularity: .day)
                    if comparison == .orderedDescending {
                        // 检查是否在指定天数范围内
                        let daysDifference = calendar.dateComponents([.day], from: today, to: nextReminderDate).day ?? 0
                        if daysDifference <= daysAhead {
                            upcomingReminders.append(reminder)
                            logger.info("📈 未来安排: \(reminder.tag?.name ?? "未知") - 日期: \(nextReminderDate)")
                        }
                    }
                }
            }
            
            logger.info("📈 获取未来提醒: 共 \(upcomingReminders.count) 条")
            return upcomingReminders
            
        } catch {
            logger.error("获取未来提醒失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取提醒的下一次发生日期（核心方法）
    static func getNextReminderDate(for reminder: Reminder, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        
        // 如果是单次提醒
        if reminder.repeatInterval == nil || reminder.repeatUnit == nil {
            return reminder.startDate
        }
        
        // 如果是重复提醒，计算下一次发生的日期
        guard let interval = reminder.repeatInterval, 
              let unit = reminder.repeatUnit,
              interval > 0 else { 
            return reminder.startDate
        }
        
        // 从起始日期开始计算
        var nextDate = reminder.startDate
        
        // 🔧 核心修改：循环的条件是 "日期早于今天" 或者 "这个日期已经被完成了"
        // 这样它就会一直往后计算，直到找到一个未来的、且尚未完成的日期
        while calendar.compare(nextDate, to: date, toGranularity: .day) == .orderedAscending 
              || reminder.isCompletedOn(date: nextDate) {
            switch unit {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: interval, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: interval, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: interval, to: nextDate) ?? nextDate
            }
        }
        
        return nextDate
    }
    
    /// 计算角标数字：逾期未完成 + 今日到期未完成的总数
    static func calculateBadgeCount(modelContext: ModelContext) -> Int {
        let today = Date()
        let calendar = Calendar.current
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            var badgeCount = 0
            
            for reminder in allReminders {
                if let nextReminderDate = getNextReminderDate(for: reminder, from: today) {
                    // 如果下一次提醒日期是今天或之前（逾期），且未完成
                    let comparison = calendar.compare(nextReminderDate, to: today, toGranularity: .day)
                    if (comparison == .orderedSame || comparison == .orderedAscending) && !reminder.isCompletedOn(date: nextReminderDate) {
                        badgeCount += 1
                    }
                }
            }
            
            logger.info("📱 计算角标数字: \(badgeCount)")
            return badgeCount
            
        } catch {
            logger.error("计算角标数字失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 计算年度重复提醒的下一个提醒日期
    private static func calculateNextYearlyReminderDate(for reminder: Reminder, from date: Date) -> Date? {
        guard reminder.repeatUnit == .yearly else { return nil }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        
        // 获取提醒的月日
        let startComponents = calendar.dateComponents([.month, .day], from: reminder.startDate)
        guard let month = startComponents.month, let day = startComponents.day else { return nil }
        
        // 计算今年的提醒日期
        guard let thisYearDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: day)) else {
            return nil
        }
        
        // 如果今年的日期还没过，返回今年的日期；否则返回明年的日期
        if thisYearDate > date {
            return thisYearDate
        } else {
            return calendar.date(from: DateComponents(year: currentYear + 1, month: month, day: day))
        }
    }
    
    /// 计算重复提醒的下一个周期日期
    private static func calculateNextCycleDate(for reminder: Reminder, from date: Date) -> Date? {
        guard let interval = reminder.repeatInterval, 
              let unit = reminder.repeatUnit,
              interval > 0 else { 
            return nil 
        }
        
        let calendar = Calendar.current
        
        switch unit {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: interval, to: date)
        }
    }
    
    /// 标记提醒为已完成
    static func markReminderAsCompleted(reminder: Reminder, modelContext: ModelContext) {
        // 获取提醒应该完成的日期（对于逾期提醒，使用应该完成的日期而不是当前日期）
        let completionDate = getNextReminderDate(for: reminder) ?? Date()
        
        // 创建完成记录
        let completion = ReminderCompletion(
            completionDate: completionDate,
            reminder: reminder
        )
        
        modelContext.insert(completion)
        
        do {
            try modelContext.save()
            logger.info("✅ 已将提醒标记为完成: \(reminder.id), 完成日期: \(completionDate)")
            
            // 🔧 关键修复：取消该提醒的所有待处理通知
            NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
            logger.info("🔔 已取消提醒ID \(reminder.id) 的所有通知")
            
            // 🔧 如果是重复提醒，为下一个周期重新创建通知
            if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                // 重新设置通知（根据宠物数量选择策略）
                if let pets = reminder.pets, !pets.isEmpty {
                    if pets.count == 1 {
                        // 单宠物：使用原有逻辑
                        NotificationService.scheduleRepeatingReminderNotifications(reminder: reminder, pet: pets[0])
                    } else {
                        // 多宠物：只发送一条通知
                        NotificationService.scheduleRepeatingReminderNotificationsForMultiplePets(reminder: reminder)
                    }
                    logger.info("🔔 已为重复提醒的未来周期重新创建通知")
                }
            }
            
            // 更新应用角标
            NotificationService.updateApplicationBadge(modelContext: modelContext)
        } catch {
            logger.error("标记提醒完成时出错: \(error.localizedDescription)")
        }
    }
    
    /// 检查并为新创建的提醒设置通知
    static func setupNotificationsForReminder(reminder: Reminder) {
        guard let pets = reminder.pets, !pets.isEmpty else {
            logger.warning("提醒没有关联的宠物，无法设置通知")
            return
        }
        
        // 🔧 修复：根据宠物数量选择通知策略
        if pets.count == 1 {
            // 单宠物：使用原有逻辑
            let pet = pets[0]
            if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                NotificationService.scheduleRepeatingReminderNotifications(reminder: reminder, pet: pet)
            } else {
                NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
            }
        } else {
            // 多宠物：只发送一条通知，包含所有宠物信息
            if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                NotificationService.scheduleRepeatingReminderNotificationsForMultiplePets(reminder: reminder)
            } else {
                NotificationService.scheduleReminderNotificationForMultiplePets(reminder: reminder)
            }
        }
        
        // 调试：记录待处理的通知
        #if DEBUG
        NotificationService.logPendingNotifications()
        #endif
    }
    
    /// 获取特定宠物的所有提醒
    static func getRemindersForPet(pet: Pet, modelContext: ModelContext) -> [Reminder] {
        // 首先获取所有提醒
        let descriptor = FetchDescriptor<Reminder>()
        
        do {
            let allReminders = try modelContext.fetch(descriptor)
            
            // 然后在内存中过滤
            return allReminders.filter { reminder in
                guard let pets = reminder.pets else { return false }
                return pets.contains(where: { $0.id == pet.id })
            }
        } catch {
            logger.error("获取宠物提醒时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 根据完成情况获取提醒
    static func getReminders(isCompleted: Bool, modelContext: ModelContext) -> [Reminder] {
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            
            // 在内存中进行过滤，避免在谓词中使用可选链
            if isCompleted {
                // 获取已完成的提醒
                return allReminders.filter { reminder in
                    return reminder.isCompletedOn(date: today)
                }
            } else {
                // 获取未完成的提醒
                return allReminders.filter { reminder in
                    return reminder.needsReminderOn(date: today) && !reminder.isCompletedOn(date: today)
                }
            }
        } catch {
            logger.error("获取提醒时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取最近完成的提醒（显示在Completed列表中）
    /// - Parameters:
    ///   - modelContext: 数据上下文
    ///   - daysBack: 显示最近多少天内完成的提醒，默认30天
    /// - Returns: 最近完成的提醒列表，按完成日期降序排列
    static func getRecentlyCompletedReminders(modelContext: ModelContext, daysBack: Int = 30) -> [Reminder] {
        let calendar = Calendar.current
        let today = Date()
        
        // 计算起始日期（例如30天前）的开始时间（00:00:00）
        let startOfToday = calendar.startOfDay(for: today)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: startOfToday) else {
            logger.error("无法计算起始日期")
            return []
        }
        
        logger.info("📅 查询最近完成的提醒: 从 \(startDate) 到 \(today)")
        
        do {
            // 获取所有提醒
            let allRemindersDescriptor = FetchDescriptor<Reminder>()
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            logger.info("📋 总共有 \(allReminders.count) 个提醒")
            
            // 存储已完成的提醒及其最近完成日期
            var completedRemindersWithDate: [(reminder: Reminder, completionDate: Date)] = []
            
            for reminder in allReminders {
                // 获取该提醒的所有完成记录
                guard let completions = reminder.completions, !completions.isEmpty else { 
                    logger.debug("提醒 \(reminder.tag?.name ?? "未知") 没有完成记录")
                    continue 
                }
                
                logger.debug("提醒 \(reminder.tag?.name ?? "未知") 有 \(completions.count) 条完成记录")
                
                // 找出最近30天内的完成记录（使用日期比较）
                let recentCompletions = completions.filter { completion in
                    let compDate = calendar.startOfDay(for: completion.completionDate)
                    let isAfterStart = calendar.compare(compDate, to: startDate, toGranularity: .day) != .orderedAscending
                    let isBeforeToday = calendar.compare(compDate, to: startOfToday, toGranularity: .day) != .orderedDescending
                    
                    logger.debug("  - 完成日期: \(completion.completionDate), 是否在范围内: \(isAfterStart && isBeforeToday)")
                    return isAfterStart && isBeforeToday
                }
                
                // 如果有最近的完成记录，取最新的一条
                if let latestCompletion = recentCompletions.sorted(by: { $0.completionDate > $1.completionDate }).first {
                    completedRemindersWithDate.append((reminder: reminder, completionDate: latestCompletion.completionDate))
                    logger.info("✅ 找到已完成提醒: \(reminder.tag?.name ?? "未知"), 完成日期: \(latestCompletion.completionDate)")
                }
            }
            
            // 按完成日期降序排列（最近完成的在前面）
            let sortedReminders = completedRemindersWithDate
                .sorted { $0.completionDate > $1.completionDate }
                .map { $0.reminder }
            
            logger.info("📋 获取最近完成的提醒: 共 \(sortedReminders.count) 条")
            return sortedReminders
            
        } catch {
            logger.error("获取最近完成的提醒失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 创建从提醒完成到记录的桥梁
    static func createRecordFromReminder(reminder: Reminder, modelContext: ModelContext) -> Record? {
        guard let pets = reminder.pets, !pets.isEmpty else {
            logger.warning("提醒没有关联的宠物，无法创建记录")
            return nil
        }
        
        // 创建新记录
        let newRecord = Record(
            timestamp: Date(),
            notes: reminder.notes,
            tag: reminder.tag,
            pets: pets
        )
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            logger.info("成功从提醒创建记录: \(newRecord.id)")
            return newRecord
        } catch {
            logger.error("从提醒创建记录时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 完成提醒（旧方法，保留用于兼容性）
    static func completeReminder(_ reminder: Reminder, context: ModelContext) {
        // 创建完成记录
        let completion = ReminderCompletion(completionDate: Date(), reminder: reminder)
        context.insert(completion)
        
        // 🔧 先取消当前的所有通知
        NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
        logger.info("🔔 已取消提醒ID \(reminder.id) 的所有通知")
        
        // 如果是重复提醒，计算下一次提醒时间
        if let repeatInterval = reminder.repeatInterval, let repeatUnit = reminder.repeatUnit {
            // 计算下一次提醒时间
            if let nextDate = Calendar.current.date(byAdding: repeatUnit.calendarComponent, value: repeatInterval, to: reminder.startDate) {
                // 更新提醒的下一次到期日期
                reminder.startDate = nextDate
                
                // 为新的提醒日期创建通知
                if let pets = reminder.pets, !pets.isEmpty {
                    for pet in pets {
                        NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
                    }
                    logger.info("🔔 已为重复提醒的下一个周期创建通知")
                }
            }
        }
        
        do {
            try context.save()
            // 更新应用角标
            NotificationService.updateApplicationBadge(modelContext: context)
        } catch {
            logger.error("完成提醒时保存失败: \(error)")
        }
    }
} 
