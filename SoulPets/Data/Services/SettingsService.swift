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
        // 首先尝试从UserDefaults获取保存的版本号
        if let savedVersion = UserDefaults.standard.string(forKey: "app_version") {
            return savedVersion
        }
        
        // 如果UserDefaults中没有，则从Bundle获取
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0"
        }
        
        // 将版本号保存到UserDefaults中
        UserDefaults.standard.set(version, forKey: "app_version")
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
        
        // 使用新的UserSettings清理方法
        UserSettings.clearAllSettings()
        
        // 清理应用的所有UserDefaults数据
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
        
        logger.info("UserDefaults 重置成功")
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
        let email = "support@soulpets.app"
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
    @MainActor
    static func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        // 使用新的 API（iOS 18.0+）或旧的 API（iOS 14.0-17.x）
        if #available(iOS 18.0, *) {
            // iOS 18.0+ 使用新的 AppStore API（需要在主线程调用）
            AppStore.requestReview(in: scene)
        } else {
            // iOS 14.0-17.x 使用旧的 SKStoreReviewController API
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    /// 分享应用
    static func shareApp() {
        // 🔧 修复：异步执行分享操作，避免阻塞主线程
        DispatchQueue.main.async {
            let appStoreURL = "https://apps.apple.com/app/soulpets/id123456789" // 替换为实际的 App Store URL
            let shareText = String(localized: "settings.support.share_app.text")
            let fullText = "\(shareText) \(appStoreURL)"
            
            // 🔧 修复：更好的方式获取当前视图控制器
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                logger.error("无法获取当前视图控制器来显示分享界面")
                return
            }
            
            // 🔧 修复：获取最顶层的视图控制器
            let topViewController = getTopViewController(from: rootViewController)
            
            let activityVC = UIActivityViewController(
                activityItems: [fullText],
                applicationActivities: nil
            )
            
            // 🔧 新增：设置完成回调，减少系统错误
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                if let error = error {
                    logger.error("分享操作出错: \(error.localizedDescription)")
                } else if completed {
                    logger.info("分享操作完成")
                } else {
                    logger.info("分享操作被取消")
                }
            }
            
            // 对于 iPad，需要设置 popover 的源
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topViewController.view
                popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, 
                                          y: topViewController.view.bounds.midY, 
                                          width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // 🔧 修复：添加短暂延迟，让UI完全准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                topViewController.present(activityVC, animated: true) {
                    logger.info("分享应用界面已显示")
                }
            }
        }
    }
    
    /// 获取最顶层的视图控制器
    private static func getTopViewController(from rootViewController: UIViewController) -> UIViewController {
        if let presentedViewController = rootViewController.presentedViewController {
            return getTopViewController(from: presentedViewController)
        }
        
        if let navigationController = rootViewController as? UINavigationController {
            return getTopViewController(from: navigationController.visibleViewController ?? navigationController)
        }
        
        if let tabBarController = rootViewController as? UITabBarController {
            return getTopViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }
        
        return rootViewController
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
