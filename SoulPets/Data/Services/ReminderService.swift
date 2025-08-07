import Foundation
import SwiftData
import OSLog

/// 提醒服务，负责处理提醒相关的业务逻辑
class ReminderService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "Reminder")
    
    /// 获取今日待办提醒
    static func getTodayReminders(modelContext: ModelContext) -> [Reminder] {
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            
            // 筛选出今天需要执行但尚未完成的提醒
            let todayReminders = allReminders.filter { reminder in
                reminder.needsReminderOn(date: today) && !reminder.isCompletedToday
            }
            
            return todayReminders
        } catch {
            logger.error("获取今日提醒失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取未来的提醒（除今天外的未来7天）
    static func getUpcomingReminders(modelContext: ModelContext, daysAhead: Int = 7) -> [Reminder] {
        let calendar = Calendar.current
        let today = Date()
        let allRemindersDescriptor = FetchDescriptor<Reminder>()
        
        do {
            // 获取所有提醒模板
            let allReminders = try modelContext.fetch(allRemindersDescriptor)
            
            // 先获取今日的提醒ID，避免重复
            let todayReminderIds = Set(getTodayReminders(modelContext: modelContext).map { $0.id })
            
            var upcomingReminders: [Reminder] = []
            
            // 检查未来7天的每一天（从明天开始）
            for dayOffset in 1...daysAhead {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    continue
                }
                
                // 筛选出在该日期需要提醒的模板，但排除今日已有的提醒
                let remindersForDay = allReminders.filter { reminder in
                    // 排除今日已有的提醒
                    !todayReminderIds.contains(reminder.id) && 
                    reminder.needsReminderOn(date: futureDate)
                }
                
                upcomingReminders.append(contentsOf: remindersForDay)
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
    
    /// 标记提醒为已完成
    static func markReminderAsCompleted(reminder: Reminder, modelContext: ModelContext) {
        // 创建完成记录
        let completion = ReminderCompletion(
            completionDate: Date(),
            reminder: reminder
        )
        
        modelContext.insert(completion)
        
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
            NotificationService.scheduleReminderNotification(reminder: reminder, pet: pet)
        }
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
} 