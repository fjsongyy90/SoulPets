import Foundation
import SwiftData
import OSLog

/// 提醒服务，负责处理提醒相关的业务逻辑
class ReminderService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "Reminder")
    
    /// 获取今日待办提醒
    static func getTodayReminders(modelContext: ModelContext) -> [Reminder] {
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            logger.info("📋 所有提醒总数: \(allReminders.count)")
            
            // 筛选出今天需要执行但尚未完成的提醒
            let todayReminders = allReminders.filter { reminder in
                let needsReminder = reminder.needsReminderOn(date: today)
                let isCompleted = reminder.isCompletedToday
                
                // 特别为生日提醒添加详细日志
                if reminder.tag.code == "planning.birthday" {
                    logger.info("🎂 生日提醒检查: \(reminder.tag.name)")
                    logger.info("  - 开始日期: \(reminder.startDate)")
                    logger.info("  - 检查日期: \(today)")
                    logger.info("  - 需要提醒: \(needsReminder)")
                    logger.info("  - 已完成: \(isCompleted)")
                    logger.info("  - 重复单位: \(reminder.repeatUnit?.rawValue ?? "无")")
                    logger.info("  - 重复间隔: \(reminder.repeatInterval ?? 0)")
                }
                
                return needsReminder && !isCompleted
            }
            
            return todayReminders
        } catch {
            logger.error("获取今日提醒失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取未来的提醒（除今天外的未来7天，以及年度重复提醒）
    static func getUpcomingReminders(modelContext: ModelContext, daysAhead: Int = 7) -> [Reminder] {
        let calendar = Calendar.current
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            logger.info("📋 获取未来提醒: 所有提醒总数 \(allReminders.count)")
            
            var upcomingReminders: [Reminder] = []
            
            // 检查未来7天的每一天（从明天开始）
            for dayOffset in 1...daysAhead {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    continue
                }
                
                // 筛选出在该日期需要提醒的模板
                let remindersForDay = allReminders.filter { reminder in
                    let needsReminder = reminder.needsReminderOn(date: futureDate)
                    let isNotCompletedOnThatDay = !reminder.isCompletedOn(date: futureDate)
                    
                    return needsReminder && isNotCompletedOnThatDay
                }
                
                upcomingReminders.append(contentsOf: remindersForDay)
            }
            
            // 🔧 新增：特别处理年度重复提醒（如生日、领养纪念日）
            let yearlyReminders = allReminders.filter { reminder in
                guard let repeatUnit = reminder.repeatUnit else { return false }
                return repeatUnit == .yearly && !reminder.isCompletedToday
            }
            
            for reminder in yearlyReminders {
                // 计算下一个年度提醒日期
                if let nextYearlyDate = calculateNextYearlyReminderDate(for: reminder, from: today) {
                    // 如果这个年度提醒还没有在upcomingReminders中，就添加它
                    let notAlreadyIncluded = !upcomingReminders.contains { $0.id == reminder.id }
                    
                    if notAlreadyIncluded {
                        upcomingReminders.append(reminder)
                        logger.info("🎂 添加年度提醒: \(reminder.tag.name)，下次日期: \(nextYearlyDate)")
                    }
                }
            }
            
            // 🔧 对于今天已完成的重复提醒，立即显示它们的下一个周期
            let todayCompletedReminders = allReminders.filter { reminder in
                // 检查是否是重复提醒且今天已完成
                let isRepeating = reminder.repeatInterval != nil && reminder.repeatUnit != nil
                let isCompletedToday = reminder.isCompletedToday
                let needsTodayReminder = reminder.needsReminderOn(date: today)
                
                return isRepeating && isCompletedToday && needsTodayReminder
            }
            
            // 为今天已完成的重复提醒计算下一个周期日期
            for reminder in todayCompletedReminders {
                if let nextCycleDate = calculateNextCycleDate(for: reminder, from: today) {
                    // 检查下一个周期是否在未来7天内，且该提醒尚未包含在upcomingReminders中
                    let daysDifference = calendar.dateComponents([.day], from: today, to: nextCycleDate).day ?? 0
                    let isWithinRange = daysDifference > 0 && daysDifference <= daysAhead
                    let notAlreadyIncluded = !upcomingReminders.contains { $0.id == reminder.id }
                    
                    if isWithinRange && notAlreadyIncluded {
                        upcomingReminders.append(reminder)
                        logger.info("🔄 添加已完成重复提醒的下一周期: \(reminder.tag.name)，下次日期: \(nextCycleDate)")
                    }
                }
            }
            
            // 去重，一个模板可能在多个未来日期都有提醒
            let uniqueUpcoming = Array(Set(upcomingReminders))
            
            logger.info("📈 获取未来提醒: 排除今日提醒后剩余 \(uniqueUpcoming.count) 条")
            return uniqueUpcoming
            
        } catch {
            logger.error("获取未来提醒失败: \(error.localizedDescription)")
            return []
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
        // 创建完成记录
        let completion = ReminderCompletion(
            completionDate: Date(),
            reminder: reminder
        )
        
        modelContext.insert(completion)
        
        // 🔧 修复：移除错误的startDate更新逻辑
        // 重复提醒的startDate应该保持不变，只需要记录完成情况即可
        // 显示逻辑会基于重复计算和完成记录来判断是否需要显示
        
        do {
            try modelContext.save()
            logger.info("已将提醒标记为完成: \(reminder.id)")
        } catch {
            logger.error("标记提醒完成时出错: \(error.localizedDescription)")
        }
    }
    
    /// 检查并为新创建的提醒设置通知
    static func setupNotificationsForReminder(reminder: Reminder) {
        guard let pets = reminder.pets else {
            logger.warning("提醒没有关联的宠物，无法设置通知")
            return
        }
        
        // 为每个关联的宠物创建通知
        for pet in pets {
            // 如果是重复提醒，使用重复通知方法
            if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                NotificationService.scheduleRepeatingReminderNotifications(reminder: reminder, pet: pet)
            } else {
                // 单次提醒
                NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
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
    
    /// 完成提醒
    static func completeReminder(_ reminder: Reminder, context: ModelContext) {
        // 创建完成记录
        let completion = ReminderCompletion(completionDate: Date(), reminder: reminder)
        context.insert(completion)
        
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
