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
        loadReminders()
    }
    
    // MARK: - 数据加载
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
    private func setupDefaultPetFilter(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.name)])
        
        do {
            let pets = try modelContext.fetch(descriptor)
            if let firstPet = pets.first {
                selectedPetFilter = .specific(firstPet)
                logger.info("🐾 提醒模块默认选中宠物: \(firstPet.name)")
            }
        } catch {
            logger.error("获取宠物列表失败: \(error.localizedDescription)")
            // 如果获取失败，保持默认的 .all 设置
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
    
    func setPetFilter(_ filter: PetFilter) {
        selectedPetFilter = filter
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