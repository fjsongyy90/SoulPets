import SwiftUI

// MARK: - PetType Extension
/// PetType 扩展：集中管理宠物类型相关的配置
/// 这样设计便于未来扩展新的宠物类型，只需在一个地方修改
extension PetType {
    /// 默认头像图片名称
    /// - Returns: 对应宠物类型的默认图片资源名称
    var defaultImageName: String {
        switch self {
        case .cat:
            return "pet_cat"
        case .dog:
            return "pet_dog"
        // 未来扩展示例：
        // case .rabbit:
        //     return "pet_rabbit"
        // case .bird:
        //     return "pet_bird"
        }
    }
    
    /// 显示名称（用于本地化）
    /// - Returns: 宠物类型的显示名称
    var displayName: String {
        return self.rawValue
    }
    
    /// 主题色（可选，用于UI展示）
    /// - Returns: 对应宠物类型的主题色
    var themeColor: Color {
        switch self {
        case .cat:
            return .orange
        case .dog:
            return .blue
        // 未来扩展示例：
        // case .rabbit:
        //     return .pink
        // case .bird:
        //     return .cyan
        }
    }
    
    /// SF Symbol 图标名称（用于某些UI场景）
    /// - Returns: 对应的系统图标名称
    var systemIconName: String {
        switch self {
        case .cat:
            return "cat.fill"
        case .dog:
            return "dog.fill"
        // 未来扩展示例：
        // case .rabbit:
        //     return "hare.fill"
        // case .bird:
        //     return "bird.fill"
        }
    }
}
