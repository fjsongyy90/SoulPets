import Foundation
import UserNotifications
import OSLog

/// 通知服务，负责处理应用的本地通知功能
class NotificationService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "Notification")
    
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
        guard let tag = reminder.tag.name else {
            logger.error("无法为提醒创建通知：标签名为空")
            return
        }
        
        // 构建通知内容
        let content = UNMutableNotificationContent()
        content.title = "\(pet.name): \(tag)"
        
        if let notes = reminder.notes, !notes.isEmpty {
            content.body = notes
        } else {
            content.body = "是时候给\(pet.name)进行\(tag)了"
        }
        
        content.sound = .default
        
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
                logger.info("成功为\(pet.name)的\(tag)添加通知，ID: \(identifier)")
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
} 