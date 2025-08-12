import Foundation
import UIKit

/// 应用外观模式枚举
enum AppearanceMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

/// 用户设置管理类 - 使用UserDefaults存储
final class UserSettings: ObservableObject {
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let appearance = "user_appearance"
        static let userName = "user_name"
        static let iCloudSyncEnabled = "icloud_sync_enabled"
        static let lastSyncTimestamp = "last_sync_timestamp"
        static let firstLaunchDate = "first_launch_date"
    }
    
    // MARK: - Published Properties
    @Published var appearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }
    
    @Published var userName: String? {
        didSet {
            if let userName = userName {
                UserDefaults.standard.set(userName, forKey: Keys.userName)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.userName)
            }
        }
    }
    
    @Published var iCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
        }
    }
    
    var lastSyncTimestamp: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: Keys.lastSyncTimestamp)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastSyncTimestamp)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastSyncTimestamp)
            }
        }
    }
    
    var firstLaunchDate: Date {
        get {
            let timestamp = UserDefaults.standard.double(forKey: Keys.firstLaunchDate)
            if timestamp > 0 {
                return Date(timeIntervalSince1970: timestamp)
            } else {
                // 首次启动，记录当前时间
                let now = Date()
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Keys.firstLaunchDate)
                return now
            }
        }
    }
    
    // MARK: - Singleton
    static let shared = UserSettings()
    
    // MARK: - 初始化
    private init() {
        // 从UserDefaults加载设置
        let appearanceString = UserDefaults.standard.string(forKey: Keys.appearance) ?? AppearanceMode.system.rawValue
        self.appearance = AppearanceMode(rawValue: appearanceString) ?? .system
        
        self.userName = UserDefaults.standard.string(forKey: Keys.userName)
        self.iCloudSyncEnabled = UserDefaults.standard.object(forKey: Keys.iCloudSyncEnabled) as? Bool ?? true
    }
    
    // MARK: - 便利方法
    
    /// 重置所有设置到默认值
    func resetToDefaults() {
        appearance = .system
        userName = nil
        iCloudSyncEnabled = true
        lastSyncTimestamp = nil
        
        // 不重置firstLaunchDate，因为这是历史记录
    }
    
    /// 应用当前外观设置到应用
    func applyCurrentAppearance() {
        DispatchQueue.main.async {
            self.applyAppearanceToAllWindows(self.appearance)
        }
    }
    
    /// 应用外观设置到所有窗口
    private func applyAppearanceToAllWindows(_ appearance: AppearanceMode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        for window in windowScene.windows {
            switch appearance {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    /// 清除所有UserDefaults中的设置数据
    static func clearAllSettings() {
        let keys = [Keys.appearance, Keys.userName, Keys.iCloudSyncEnabled, Keys.lastSyncTimestamp, Keys.firstLaunchDate]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - 辅助方法
extension UserSettings {
    /// 获取个性化问候语
    var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        var timeGreeting: String
        if hour < 12 {
            timeGreeting = String(localized: "settings.greeting.morning")
        } else if hour < 18 {
            timeGreeting = String(localized: "settings.greeting.afternoon")
        } else {
            timeGreeting = String(localized: "settings.greeting.evening")
        }
        
        if let userName = userName, !userName.isEmpty {
            return "\(timeGreeting), \(userName)!"
        } else {
            return timeGreeting
        }
    }
    
    /// 获取使用应用的天数
    var daysUsing: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        return max(0, days)
    }
} 