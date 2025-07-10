import Foundation
import SwiftData

/// 应用外观模式枚举
enum AppearanceMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

@Model
final class UserSettings {
    // MARK: - 属性
    var id: UUID
    var appearance: AppearanceMode
    var userName: String?
    var iCloudSyncEnabled: Bool
    var lastSyncTimestamp: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        appearance: AppearanceMode = .system,
        userName: String? = nil,
        iCloudSyncEnabled: Bool = true,
        lastSyncTimestamp: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appearance = appearance
        self.userName = userName
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.lastSyncTimestamp = lastSyncTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 辅助方法
extension UserSettings {
    /// 获取个性化问候语
    var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        var timeGreeting: String
        if hour < 12 {
            timeGreeting = "早上好"
        } else if hour < 18 {
            timeGreeting = "下午好"
        } else {
            timeGreeting = "晚上好"
        }
        
        if let name = userName, !name.isEmpty {
            return "\(timeGreeting)，\(name)！"
        } else {
            return timeGreeting + "！"
        }
    }
} 