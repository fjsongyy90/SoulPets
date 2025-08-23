import SwiftUI
import SwiftData
import OSLog

/// 宠物筛选状态枚举
enum PetFilterState: Equatable {
    case all
    case specific(Pet)
    
    var displayName: String {
        switch self {
        case .all:
            return String(localized: "All Pets")
        case .specific(let pet):
            return pet.name
        }
    }
    
    var pet: Pet? {
        switch self {
        case .all:
            return nil
        case .specific(let pet):
            return pet
        }
    }
    
    static func == (lhs: PetFilterState, rhs: PetFilterState) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.specific(let pet1), .specific(let pet2)):
            return pet1.id == pet2.id
        default:
            return false
        }
    }
}

/// 应用全局状态管理
@MainActor
class AppState: ObservableObject {
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AppState")
    /// Home页当前选中的宠物
    @Published var selectedPet: Pet?
    
    /// 各个页面的宠物筛选状态
    @Published var recordsPageFilter: PetFilterState?
    @Published var remindersPageFilter: PetFilterState?
    @Published var weightPageFilter: Pet?
    
    /// 标记各页面是否已经被用户主动修改过筛选
    @Published var recordsFilterManuallyChanged: Bool = false
    @Published var remindersFilterManuallyChanged: Bool = false
    @Published var weightFilterManuallyChanged: Bool = false
    
    /// 单例实例
    static let shared = AppState()
    
    private init() {}
    
    // MARK: - Home页宠物管理
    
    /// 设置Home页当前选中的宠物
    func setSelectedPet(_ pet: Pet?) {
        let petName = pet?.name ?? "nil"
        logger.info("🏠 Home页设置选中宠物: \(petName)")
        
        selectedPet = pet
        
        // 🔧 关键修复：当Home页宠物变化时，自动同步未手动修改的页面
        // 使用 DispatchQueue.main.async 确保状态更新能被正确观察到
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            logger.info("📊 检查各页面筛选状态:")
            logger.info("  - Records手动修改: \(self.recordsFilterManuallyChanged)")
            logger.info("  - Reminders手动修改: \(self.remindersFilterManuallyChanged)")
            logger.info("  - Weight手动修改: \(self.weightFilterManuallyChanged)")
            
            if !self.recordsFilterManuallyChanged {
                let newFilter: PetFilterState = pet != nil ? .specific(pet!) : .all
                self.recordsPageFilter = newFilter
                logger.info("🔄 Records页面筛选同步为: \(newFilter.displayName)")
            } else {
                logger.info("⏭️ Records页面已手动修改，跳过同步")
            }
            
            if !self.remindersFilterManuallyChanged {
                let newFilter: PetFilterState = pet != nil ? .specific(pet!) : .all
                self.remindersPageFilter = newFilter
                logger.info("🔄 Reminders页面筛选同步为: \(newFilter.displayName)")
            } else {
                logger.info("⏭️ Reminders页面已手动修改，跳过同步")
            }
            
            if !self.weightFilterManuallyChanged {
                self.weightPageFilter = pet
                logger.info("🔄 Weight页面筛选同步为: \(petName)")
            } else {
                logger.info("⏭️ Weight页面已手动修改，跳过同步")
            }
        }
    }
    
    /// 获取Home页当前选中的宠物
    func getCurrentPet() -> Pet? {
        return selectedPet
    }
    
    /// 清除Home页选中的宠物
    func clearSelectedPet() {
        selectedPet = nil
        
        // 如果各页面的筛选还没有被用户主动修改过，则同步更新
        if !recordsFilterManuallyChanged {
            recordsPageFilter = .all
        }
        
        if !remindersFilterManuallyChanged {
            remindersPageFilter = .all
        }
        
        if !weightFilterManuallyChanged {
            weightPageFilter = nil
        }
    }
    
    /// 当Home页宠物发生变化时，同步更新其他页面的筛选状态（仅限未手动修改的页面）
    func syncFiltersWithHomePage() {
        // 如果各页面的筛选还没有被用户主动修改过，则同步更新
        if !recordsFilterManuallyChanged {
            recordsPageFilter = selectedPet != nil ? .specific(selectedPet!) : .all
        }
        
        if !remindersFilterManuallyChanged {
            remindersPageFilter = selectedPet != nil ? .specific(selectedPet!) : .all
        }
        
        if !weightFilterManuallyChanged {
            weightPageFilter = selectedPet
        }
    }
    
    // MARK: - 记录页面筛选管理
    
    /// 设置记录页面的宠物筛选（用户主动操作）
    func setRecordsPageFilter(_ filter: PetFilterState) {
        logger.info("👆 用户主动设置Records页面筛选: \(filter.displayName)")
        recordsPageFilter = filter
        recordsFilterManuallyChanged = true
        logger.info("✅ Records页面标记为手动修改")
    }
    
    /// 获取记录页面的宠物筛选，如果未设置则使用Home页的选择
    func getRecordsPageFilter() -> PetFilterState {
        // 如果用户已经手动修改过，直接返回当前筛选
        if recordsFilterManuallyChanged, let filter = recordsPageFilter {
            return filter
        }
        
        // 如果没有手动修改过，总是同步Home页的选择
        let filter: PetFilterState = selectedPet != nil ? .specific(selectedPet!) : .all
        
        // 🔧 关键修复：直接设置属性，不调用set方法，避免标记为手动修改
        // 移除重复的日志输出，只在状态真正改变时记录
        if recordsPageFilter != filter {
            DispatchQueue.main.async { [weak self] in
                self?.recordsPageFilter = filter
            }
        }
        
        return filter
    }
    
    // MARK: - 提醒页面筛选管理
    
    /// 设置提醒页面的宠物筛选（用户主动操作）
    func setRemindersPageFilter(_ filter: PetFilterState) {
        logger.info("👆 用户主动设置Reminders页面筛选: \(filter.displayName)")
        remindersPageFilter = filter
        remindersFilterManuallyChanged = true
        logger.info("✅ Reminders页面标记为手动修改")
    }
    
    /// 获取提醒页面的宠物筛选，如果未设置则使用Home页的选择
    func getRemindersPageFilter() -> PetFilterState {
        // 如果用户已经手动修改过，直接返回当前筛选
        if remindersFilterManuallyChanged, let filter = remindersPageFilter {
            return filter
        }
        
        // 如果没有手动修改过，总是同步Home页的选择
        let filter: PetFilterState = selectedPet != nil ? .specific(selectedPet!) : .all
        
        // 🔧 关键修复：直接设置属性，不调用set方法，避免标记为手动修改
        // 移除重复的日志输出，只在状态真正改变时记录
        if remindersPageFilter != filter {
            DispatchQueue.main.async { [weak self] in
                self?.remindersPageFilter = filter
            }
        }
        
        return filter
    }
    
    // MARK: - 体重页面筛选管理
    
    /// 设置体重页面的宠物筛选（用户主动操作）
    func setWeightPageFilter(_ pet: Pet?) {
        weightPageFilter = pet
        weightFilterManuallyChanged = true
    }
    
    /// 获取体重页面的宠物筛选，如果未设置则使用Home页的选择
    func getWeightPageFilter() -> Pet? {
        if weightFilterManuallyChanged {
            return weightPageFilter
        }
        
        // 首次访问，同步Home页的选择
        weightPageFilter = selectedPet
        return selectedPet
    }
    
    // MARK: - 重置方法（用于测试或重置状态）
    
    /// 重置所有筛选状态
    func resetAllFilters() {
        recordsPageFilter = nil
        remindersPageFilter = nil
        weightPageFilter = nil
        recordsFilterManuallyChanged = false
        remindersFilterManuallyChanged = false
        weightFilterManuallyChanged = false
    }
}
