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
        case .rabbit:
            return "pet_rabbit"
        case .hamster:
            return "pet_hamster"
        case .tortoise:
            return "pet_tortoise"
        case .snake:
            return "pet_snake"
        case .guineaPig:
            return "pet_guinea_pig"
        case .bird:
            return "pet_bird"
        case .lizard:
            return "pet_lizard"
        case .fish:
            return "pet_fish" 
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
        case .rabbit:
            return .pink
        case .hamster:
            return .brown
        case .guineaPig:
            return Color(red: 0.8, green: 0.6, blue: 0.4) // 浅棕色
        case .bird:
            return .cyan
        case .lizard:
            return .green
        case .tortoise:
            return Color(red: 0.4, green: 0.6, blue: 0.4) // 橄榄绿
        case .fish:
            return Color(red: 0.2, green: 0.6, blue: 0.8) // 海蓝色
        case .snake:
            return Color(red: 0.5, green: 0.7, blue: 0.3) // 草绿色
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
        case .rabbit:
            return "hare.fill"
        case .hamster:
            return "pawprint.fill"
        case .guineaPig:
            return "pawprint.fill"
        case .bird:
            return "bird.fill"
        case .lizard:
            return "lizard.fill"
        case .tortoise:
            return "tortoise.fill"
        case .fish:
            return "fish.fill"
        case .snake:
            return "lizard.fill" // 蛇使用蜥蜴图标，因为没有专门的蛇图标
        }
    }
}
