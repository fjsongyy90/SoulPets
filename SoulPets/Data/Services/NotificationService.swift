import Foundation
import UserNotifications
import OSLog
import UIKit

/// 通知服务，负责处理应用的本地通知功能
class NotificationService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "Notification")
    
    /// 请求通知权限
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                logger.error("请求通知权限失败: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if granted {
                logger.info("用户授予了通知权限")
                completion(true)
            } else {
                logger.warning("用户拒绝了通知权限")
                completion(false)
            }
        }
    }
    
    /// 检查通知权限状态
    static func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    /// 为提醒创建本地通知
    static func scheduleReminderNotification(reminder: Reminder, pet: Pet) {
        // 首先检查通知权限
        checkAuthorizationStatus { status in
            guard status == .authorized || status == .provisional else {
                logger.warning("通知权限未授权，无法创建通知。当前状态: \(status.rawValue)")
                return
            }
            
            // 获取标签名称，如果为空则使用默认值
            let tagName = reminder.tag.name.isEmpty ? String(localized: "reminder.default_title") : reminder.tag.name
            
            // 构建通知内容
            let content = UNMutableNotificationContent()
            content.title = "\(pet.name): \(tagName)"
            
        if let notes = reminder.notes, !notes.isEmpty {
            content.body = notes
        } else {
            content.body = getNotificationBodyForTag(tag: reminder.tag, petName: pet.name)
        }
            
            content.sound = .default
            content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
            
            // 为通知设置唯一标识符
            let identifier = "reminder-\(reminder.id.uuidString)-\(pet.id.uuidString)"
            
            // 设置触发器
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.startDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // 创建通知请求
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // 添加通知请求到通知中心
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    logger.error("添加通知失败: \(error.localizedDescription)")
                } else {
                    logger.info("成功为\(pet.name)的\(tagName)添加通知，ID: \(identifier)")
                    logger.debug("通知将在 \(reminder.startDate) 触发")
                }
            }
        }
    }
    
    /// 为重复提醒创建多个通知（用于处理重复提醒）
    static func scheduleRepeatingReminderNotifications(reminder: Reminder, pet: Pet, maxNotifications: Int = 10) {
        // 首先检查通知权限
        checkAuthorizationStatus { status in
            guard status == .authorized || status == .provisional else {
                logger.warning("通知权限未授权，无法创建重复通知。当前状态: \(status.rawValue)")
                return
            }
            
            guard let repeatInterval = reminder.repeatInterval,
                  let repeatUnit = reminder.repeatUnit else {
                // 如果不是重复提醒，则只创建一次性通知
                scheduleReminderNotification(reminder: reminder, pet: pet)
                return
            }
            
            let calendar = Calendar.current
            
            // 创建多个未来的通知实例（最多10个）
            for i in 0..<maxNotifications {
                if let nextDate = calendar.date(byAdding: repeatUnit.calendarComponent, value: repeatInterval * i, to: reminder.startDate) {
                    // 只为未来的日期创建通知
                    if nextDate > Date() {
                        scheduleIndividualNotification(reminder: reminder, pet: pet, triggerDate: nextDate, instanceIndex: i)
                    }
                } else {
                    break
                }
            }
        }
    }
    
    /// 创建单个通知实例
    private static func scheduleIndividualNotification(reminder: Reminder, pet: Pet, triggerDate: Date, instanceIndex: Int) {
        let tagName = reminder.tag.name.isEmpty ? String(localized: "reminder.default_title") : reminder.tag.name
        
        // 构建通知内容
        let content = UNMutableNotificationContent()
        content.title = "\(pet.name): \(tagName)"
        
        if let notes = reminder.notes, !notes.isEmpty {
            content.body = notes
        } else {
            content.body = String(localized: "notification.reminder_body", defaultValue: "是时候给\(pet.name)进行\(tagName)了")
        }
        
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // 为通知设置唯一标识符（包含实例索引）
        let identifier = "reminder-\(reminder.id.uuidString)-\(pet.id.uuidString)-\(instanceIndex)"
        
        // 设置触发器
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知请求到通知中心
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("添加重复通知失败: \(error.localizedDescription)")
            } else {
                logger.info("成功为\(pet.name)的\(tagName)添加重复通知，ID: \(identifier)，触发时间: \(triggerDate)")
            }
        }
    }
    
    /// 根据标识符移除特定通知
    static func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("移除通知: \(identifier)")
    }
    
    /// 移除与特定提醒相关的所有通知
    static func removeNotificationsForReminder(reminderId: UUID) {
        let reminderIdentifierPrefix = "reminder-\(reminderId.uuidString)"
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request in
                request.identifier.hasPrefix(reminderIdentifierPrefix) ? request.identifier : nil
            }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                logger.info("移除了提醒ID \(reminderId) 的 \(identifiersToRemove.count) 个通知")
            }
        }
    }
    
    /// 清除所有待处理的通知
    static func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("移除了所有待处理的通知")
    }
    
    /// 根据标签获取通知文案
    static func getNotificationBodyForTag(tag: Tag, petName: String) -> String {
        // 根据标签的code获取对应的本地化文案
        let localizationKey = "notification.tag.\(tag.code)"
        let localizedText = String(localized: LocalizedStringResource(stringLiteral: localizationKey))
        
        // 如果找不到特定标签的文案，则使用默认文案
        if localizedText == localizationKey {
            return String(localized: "notification.reminder_body", defaultValue: "是时候给\(petName)进行\(tag.name)了")
        }
        
        return localizedText
    }
    
    /// 获取所有待处理的通知（用于调试）
    static func logPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            logger.info("当前待处理的通知数量: \(requests.count)")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    logger.debug("通知ID: \(request.identifier), 触发时间: \(String(describing: trigger.nextTriggerDate()))")
                }
            }
        }
    }
} 