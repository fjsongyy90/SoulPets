import Foundation
import UIKit
import StoreKit
import MessageUI

/// 设置服务类，处理所有设置相关的业务逻辑
final class SettingsService {
    
    // MARK: - 静态属性
    
    /// 获取应用版本号
    static var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0"
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
        let urlString = "https://soulpets.app/privacy-policy"
        openWebURL(urlString)
    }
    
    /// 打开服务条款
    static func openTermsOfService() {
        let urlString = "https://soulpets.app/terms-of-service"
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