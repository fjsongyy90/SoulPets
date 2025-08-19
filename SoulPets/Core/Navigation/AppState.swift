import SwiftUI
import SwiftData

/// 应用全局状态管理
@MainActor
class AppState: ObservableObject {
    /// 当前选中的宠物
    @Published var selectedPet: Pet?
    
    /// 单例实例
    static let shared = AppState()
    
    private init() {}
    
    /// 设置当前选中的宠物
    func setSelectedPet(_ pet: Pet?) {
        selectedPet = pet
    }
    
    /// 获取当前选中的宠物
    func getCurrentPet() -> Pet? {
        return selectedPet
    }
    
    /// 清除选中的宠物
    func clearSelectedPet() {
        selectedPet = nil
    }
}