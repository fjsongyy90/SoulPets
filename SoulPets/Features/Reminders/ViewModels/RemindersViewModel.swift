import Foundation
import SwiftData
import OSLog

@Observable
class RemindersViewModel {
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "RemindersViewModel")
    
    // MARK: - 状态属性
    var todayReminders: [Reminder] = []
    var upcomingReminders: [Reminder] = []
    var completedReminders: [Reminder] = []
    var selectedPet: Pet?
    var showingCompletedReminders = false
    var isLoading = false
    var errorMessage: String?
    
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
        loadReminders()
    }
    
    // MARK: - 数据加载
    func loadReminders(from modelContext: ModelContext? = nil) {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // 获取今日待办提醒
                self.todayReminders = ReminderService.getTodayReminders(modelContext: context)
                
                // 获取未来提醒
                self.upcomingReminders = ReminderService.getUpcomingReminders(modelContext: context)
                
                // 获取已完成提醒
                self.completedReminders = ReminderService.getReminders(isCompleted: true, modelContext: context)
                
                logger.info("成功加载提醒数据 - 今日: \(self.todayReminders.count), 未来: \(self.upcomingReminders.count), 已完成: \(self.completedReminders.count)")
                
            } catch {
                logger.error("加载提醒数据失败: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoading = false
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
        switch selectedPetFilter {
        case .all:
            return reminders
        case .specific(let pet):
            return reminders.filter { reminder in
                guard let pets = reminder.pets else { return false }
                return pets.contains(where: { $0.id == pet.id })
            }
        }
    }
    
    // MARK: - 提醒操作
    func markReminderAsCompleted(_ reminder: Reminder, modelContext: ModelContext) {
        Task { @MainActor in
            ReminderService.markReminderAsCompleted(reminder: reminder, modelContext: modelContext)
            
            // 重新加载数据
            loadReminders(from: modelContext)
            
            logger.info("已标记提醒为完成: \(reminder.title)")
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
                
                // 重新加载数据
                loadReminders(from: modelContext)
                
                logger.info("已删除提醒: \(reminder.title)")
                
            } catch {
                logger.error("删除提醒失败: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - 筛选器操作
    func setFilter(_ filter: FilterType) {
        selectedFilter = filter
    }
    
    func setPetFilter(_ filter: PetFilter) {
        selectedPetFilter = filter
    }
    
    // MARK: - 提醒完成后创建记录
    func showCreateRecordFromReminder(_ reminder: Reminder, modelContext: ModelContext) -> Record? {
        return ReminderService.createRecordFromReminder(reminder: reminder, modelContext: modelContext)
    }
    
    // MARK: - 获取显示用的提醒列表
    var displayReminders: [Reminder] {
        switch selectedFilter {
        case .upcoming:
            return filteredTodayReminders + filteredUpcomingReminders
        case .completed:
            return filteredCompletedReminders
        }
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