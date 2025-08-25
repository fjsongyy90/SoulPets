import Foundation
import UIKit
import StoreKit
import MessageUI
import SwiftData
import os.log

/// 设置服务类，处理所有设置相关的业务逻辑
final class SettingsService {
    
    private static let logger = Logger(subsystem: "com.soulpets.app", category: "SettingsService")
    
    // MARK: - 静态属性
    
    /// 获取应用版本号
    static var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0"
        }
        // 确保版本号格式为x.y.z
        let components = version.components(separatedBy: ".")
        if components.count == 2 {
            return "\(version).0"  // 如果是x.y格式，添加.0
        }
        return version
    }
    
    /// 获取应用构建版本号
    static var buildVersion: String {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "1"
        }
        return build
    }
    
    /// 获取完整版本信息
    static var fullVersionString: String {
        return "\(appVersion) (\(buildVersion))"
    }
    
    /// 检查是否为Debug模式
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 通用设置
    
    /// 打开系统通知设置
    static func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Debug功能：重置数据
    
    /// 重置数据选项
    enum ResetDataOption: String, CaseIterable {
        case userDefaults = "UserDefaults"
        case database = "Database"
        case cacheFiles = "Cache Files"
        
        var localizedTitle: String {
            switch self {
            case .userDefaults:
                return String(localized: "settings.debug.reset.userdefaults")
            case .database:
                return String(localized: "settings.debug.reset.database")
            case .cacheFiles:
                return String(localized: "settings.debug.reset.cache")
            }
        }
        
        var description: String {
            switch self {
            case .userDefaults:
                return String(localized: "settings.debug.reset.userdefaults.description")
            case .database:
                return String(localized: "settings.debug.reset.database.description")
            case .cacheFiles:
                return String(localized: "settings.debug.reset.cache.description")
            }
        }
    }
    
    /// 执行重置操作
    static func resetData(options: Set<ResetDataOption>, modelContext: ModelContext? = nil) {
        guard isDebugMode else {
            logger.warning("重置数据功能只能在Debug模式下使用")
            return
        }
        
        logger.info("开始重置数据，选项: \(options.map { $0.rawValue }.joined(separator: ", "))")
        
        for option in options {
            switch option {
            case .userDefaults:
                resetUserDefaults()
            case .database:
                resetDatabase(modelContext: modelContext)
            case .cacheFiles:
                resetCacheFiles()
            }
        }
        
        // 如果重置了数据库，重新初始化预设数据
        if options.contains(.database), let modelContext = modelContext {
            logger.info("重新初始化预设数据")
            Task { @MainActor in
                await ModelRegistration.initializeDatabase(modelContext: modelContext)
                logger.info("预设数据重新初始化完成")
            }
        }
        
        logger.info("数据重置完成")
    }
    
    /// 重置UserDefaults
    private static func resetUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            logger.error("无法获取Bundle ID")
            return
        }
        
        do {
            // 使用新的UserSettings清理方法
            UserSettings.clearAllSettings()
            
            // 清理应用的所有UserDefaults数据
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            
            logger.info("UserDefaults 重置成功")
        } catch {
            logger.error("重置UserDefaults时出错: \(error.localizedDescription)")
        }
    }
    
    /// 重置数据库
    private static func resetDatabase(modelContext: ModelContext?) {
        guard let modelContext = modelContext else {
            logger.error("ModelContext 为空，无法重置数据库")
            return
        }
        
        do {
            // 删除所有数据
            try deleteAllData(in: modelContext)
            logger.info("数据库重置成功")
        } catch {
            logger.error("重置数据库时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除所有数据
    private static func deleteAllData(in modelContext: ModelContext) throws {
        logger.info("开始删除所有数据")
        
        // 使用批量删除，一次性删除每种类型的所有实体
        
        // 删除所有记录完成
        logger.info("删除提醒完成记录...")
        try modelContext.delete(model: ReminderCompletion.self)
        logger.info("提醒完成记录删除完成")
        
        // 删除所有记录照片
        logger.info("删除记录照片...")
        try modelContext.delete(model: RecordPhoto.self)
        logger.info("记录照片删除完成")
        
        // 删除所有记录
        logger.info("删除记录...")
        try modelContext.delete(model: Record.self)
        logger.info("记录删除完成")
        
        // 删除所有提醒
        logger.info("删除提醒...")
        try modelContext.delete(model: Reminder.self)
        logger.info("提醒删除完成")
        
        // 删除所有体重目标
        logger.info("删除体重目标...")
        try modelContext.delete(model: WeightGoal.self)
        logger.info("体重目标删除完成")
        
        // 删除所有体重记录
        logger.info("删除体重记录...")
        try modelContext.delete(model: Weight.self)
        logger.info("体重记录删除完成")
        
        // 删除所有宠物
        logger.info("删除宠物...")
        try modelContext.delete(model: Pet.self)
        logger.info("宠物删除完成")
        
        // 删除所有标签
        logger.info("删除标签...")
        try modelContext.delete(model: Tag.self)
        logger.info("标签删除完成")
        
        // 最终保存
        try modelContext.save()
        logger.info("所有数据删除完成")
    }
    
    /// 重置缓存文件
    private static func resetCacheFiles() {
        let fileManager = FileManager.default
        
        // 清理缓存目录
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let cacheContents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
                for cacheFile in cacheContents {
                    try fileManager.removeItem(at: cacheFile)
                }
                logger.info("缓存文件清理成功")
            } catch {
                logger.error("清理缓存文件时出错: \(error.localizedDescription)")
            }
        }
        
        // 清理临时目录
        let tempDirectory = fileManager.temporaryDirectory
        do {
            let tempContents = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for tempFile in tempContents {
                try? fileManager.removeItem(at: tempFile)
            }
            logger.info("临时文件清理成功")
        } catch {
            logger.error("清理临时文件时出错: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 支持与反馈
    
    /// 功能建议 - 打开邮件应用
    static func suggestFeature() {
        let email = "feedback@soulpets.app"
        let subject = String(localized: "settings.support.suggest_feature.email_subject")
        let body = String(localized: "settings.support.suggest_feature.email_body")
        
        // 尝试打开邮件应用
        if let emailURL = createEmailURL(to: email, subject: subject, body: body) {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
                return
            }
        }
        
        // 如果无法打开邮件应用，复制邮箱地址到剪贴板
        UIPasteboard.general.string = email
        
        // 这里可以显示一个提示，告知用户邮箱地址已复制
        // 在实际应用中，你可能需要通过通知或其他方式显示这个提示
        print("Email address copied to clipboard: \(email)")
    }
    
    /// 在 App Store 中评分
    static func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        // 使用新的 API（iOS 18.0+）或旧的 API
        if #available(iOS 18.0, *) {
            // 使用新的 AppStore API
            // 注意：这个 API 在 iOS 18.0 中引入，但可能需要导入 AppStore 框架
            // 暂时继续使用旧 API，直到新 API 完全稳定
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    /// 分享应用
    static func shareApp() {
        let appStoreURL = "https://apps.apple.com/app/soulpets/id123456789" // 替换为实际的 App Store URL
        let shareText = String(localized: "settings.support.share_app.text")
        let fullText = "\(shareText) \(appStoreURL)"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [fullText],
            applicationActivities: nil
        )
        
        // 对于 iPad，需要设置 popover 的源
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, 
                                      y: rootViewController.view.bounds.midY, 
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
    
    // MARK: - 关于
    
    /// 打开隐私政策
    static func openPrivacyPolicy() {
        let urlString = String(localized: "settings.about.privacy_policy_url")
        openWebURL(urlString)
    }
    
    /// 打开服务条款
    static func openTermsOfService() {
        let urlString = String(localized: "settings.about.terms_of_service_url")
        openWebURL(urlString)
    }
    
    // MARK: - 私有辅助方法
    
    /// 创建邮件 URL
    private static func createEmailURL(to email: String, subject: String, body: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }
    
    /// 打开网页 URL
    private static func openWebURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Cannot open URL: \(urlString)")
        }
    }
}

// MARK: - 邮件相关的扩展
extension SettingsService {
    
    /// 检查是否可以发送邮件
    static var canSendMail: Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    /// 创建邮件编辑器（如果需要在应用内发送邮件）
    static func createMailComposer(to email: String, subject: String, body: String) -> MFMailComposeViewController? {
        guard canSendMail else { return nil }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        
        return mailComposer
    }
} 