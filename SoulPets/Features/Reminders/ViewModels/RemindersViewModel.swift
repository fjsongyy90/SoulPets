import Foundation
import SwiftData
import OSLog

@Observable
class RemindersViewModel {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "RemindersViewModel")
    
    // MARK: - 状态属性
    var todayReminders: [Reminder] = []
    var upcomingReminders: [Reminder] = []
    var completedReminders: [Reminder] = []
    var selectedPet: Pet?
    var showingCompletedReminders = false
    var isLoading = false
    var errorMessage: String?
    var searchText: String = ""
    
    // MARK: - 筛选状态
    enum FilterType: String, CaseIterable {
        case upcoming = "Upcoming"
        case completed = "Completed"
        
        var localizedName: String {
            switch self {
            case .upcoming:
                return String(localized: "filter.upcoming")
            case .completed:
                return String(localized: "filter.completed")
            }
        }
    }
    
    var selectedFilter: FilterType = .upcoming
    
    // MARK: - 宠物筛选
    enum PetFilter {
        case all
        case specific(Pet)
        
        var displayName: String {
            switch self {
            case .all:
                return String(localized: "filter.all_pets")
            case .specific(let pet):
                return pet.name
            }
        }
    }
    
    var selectedPetFilter: PetFilter = .all
    
    // MARK: - 初始化
    init() {
        // 延迟加载，避免并发问题
        DispatchQueue.main.async {
            // 初始化时不加载数据，等待modelContext传入
        }
    }
    
    // MARK: - 数据加载
    @MainActor
    func loadReminders(from modelContext: ModelContext? = nil) {
        guard let context = modelContext else { return }
        
        // 首次加载时设置默认宠物筛选（如果当前是显示所有宠物）
        if selectedPetFilter.isAll {
            setupDefaultPetFilter(modelContext: context)
        }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // 获取今日待办提醒
                self.todayReminders = ReminderService.getTodayReminders(modelContext: context)
                self.logger.info("📅 Today Reminders: \(self.todayReminders.count)")
                for reminder in self.todayReminders {
                    self.logger.info("  - Today: \(reminder.tag.name) (ID: \(reminder.id.uuidString.prefix(8)))")
                }
                
                // 获取未来提醒
                self.upcomingReminders = ReminderService.getUpcomingReminders(modelContext: context)
                self.logger.info("🔮 Upcoming Reminders: \(self.upcomingReminders.count)")
                for reminder in self.upcomingReminders {
                    self.logger.info("  - Upcoming: \(reminder.tag.name) (ID: \(reminder.id.uuidString.prefix(8)))")
                }
                
                // 获取已完成提醒
                self.completedReminders = ReminderService.getReminders(isCompleted: true, modelContext: context)
                self.logger.info("✅ Completed Reminders: \(self.completedReminders.count)")
                
                // 检查重复ID
                let todayIds = Set(self.todayReminders.map { $0.id })
                let upcomingIds = Set(self.upcomingReminders.map { $0.id })
                let intersection = todayIds.intersection(upcomingIds)
                if !intersection.isEmpty {
                    self.logger.error("🚨 发现重复ID: \(intersection)")
                }
                
                self.logger.info("成功加载提醒数据 - 今日: \(self.todayReminders.count), 未来: \(self.upcomingReminders.count), 已完成: \(self.completedReminders.count)")
                
            } catch {
                self.logger.error("加载提醒数据失败: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - 设置默认宠物筛选
    @MainActor
    private func setupDefaultPetFilter(modelContext: ModelContext) {
        // 使用AppState的宠物筛选同步机制
        let appState = AppState.shared
        let filterState = appState.getRemindersPageFilter()
        
        switch filterState {
        case .all:
            selectedPetFilter = .all
            logger.info("🐾 提醒模块同步选择: 所有宠物")
        case .specific(let pet):
            selectedPetFilter = .specific(pet)
            logger.info("🐾 提醒模块同步选择宠物: \(pet.name)")
        }
    }
    
    // MARK: - 筛选逻辑
    var filteredTodayReminders: [Reminder] {
        filterReminders(todayReminders)
    }
    
    var filteredUpcomingReminders: [Reminder] {
        filterReminders(upcomingReminders)
    }
    
    var filteredCompletedReminders: [Reminder] {
        filterReminders(completedReminders)
    }
    
    private func filterReminders(_ reminders: [Reminder]) -> [Reminder] {
        var filtered = reminders
        
        // 按宠物筛选
        switch selectedPetFilter {
        case .all:
            break // 不过滤
        case .specific(let pet):
            filtered = filtered.filter { reminder in
                guard let pets = reminder.pets else { return false }
                return pets.contains(where: { $0.id == pet.id })
            }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { reminder in
                // 搜索标签名称
                let tagMatches = reminder.tag.name.localizedCaseInsensitiveContains(searchText)
                
                // 搜索备注
                let notesMatches = reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                
                // 搜索宠物名称
                let petMatches = reminder.pets?.contains { pet in
                    pet.name.localizedCaseInsensitiveContains(searchText)
                } ?? false
                
                return tagMatches || notesMatches || petMatches
            }
        }
        
        return filtered
    }
    
    // MARK: - 提醒操作
    func markReminderAsCompleted(_ reminder: Reminder, modelContext: ModelContext) {
        // 标记提醒为完成（对于重复提醒会更新到下一个周期）
        ReminderService.markReminderAsCompleted(reminder: reminder, modelContext: modelContext)
        
        // 立即重新加载数据以反映更改
        Task { @MainActor in
            loadReminders(from: modelContext)
            logger.info("已标记提醒为完成并刷新数据: \(reminder.title)")
        }
    }
    
    func deleteReminder(_ reminder: Reminder, modelContext: ModelContext) {
        Task { @MainActor in
            do {
                // 移除相关通知
                NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
                
                // 从数据库删除
                modelContext.delete(reminder)
                try modelContext.save()
                
                // 更新应用角标
                NotificationService.updateApplicationBadge(modelContext: modelContext)
                
                // 重新加载数据
                self.loadReminders(from: modelContext)
                
                self.logger.info("已删除提醒: \(reminder.title)")
                
            } catch {
                self.logger.error("删除提醒失败: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - 筛选器操作
    func setFilter(_ filter: FilterType) {
        selectedFilter = filter
    }
    
    @MainActor
    func setPetFilter(_ filter: PetFilter, updateAppState: Bool = false) {
        selectedPetFilter = filter
        
        // 🔧 关键修复：只有在用户主动操作时才更新AppState
        if updateAppState {
            let appState = AppState.shared
            switch filter {
            case .all:
                appState.setRemindersPageFilter(.all)
            case .specific(let pet):
                appState.setRemindersPageFilter(.specific(pet))
            }
        }
    }
    
    // MARK: - 提醒完成后创建记录
    func showCreateRecordFromReminder(_ reminder: Reminder, modelContext: ModelContext) -> Record? {
        return ReminderService.createRecordFromReminder(reminder: reminder, modelContext: modelContext)
    }
    
    // MARK: - 空状态检查
    var isEmpty: Bool {
        switch selectedFilter {
        case .upcoming:
            return filteredTodayReminders.isEmpty && filteredUpcomingReminders.isEmpty
        case .completed:
            return filteredCompletedReminders.isEmpty
        }
    }
    
    // MARK: - 今日待办数量
    var todayReminderCount: Int {
        filteredTodayReminders.count
    }
}

// MARK: - PetFilter Extension
extension RemindersViewModel.PetFilter {
    var isAll: Bool {
        switch self {
        case .all:
            return true
        case .specific:
            return false
        }
    }
}
