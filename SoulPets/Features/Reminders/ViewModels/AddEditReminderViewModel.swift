import Foundation
import SwiftData
import SwiftUI
import OSLog

// MARK: - 步骤枚举
enum ReminderCreationStep: CaseIterable {
    case selectPetsAndEvent
    case reminderDetails
}

class AddEditReminderViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AddEditReminderViewModel")
    
    // MARK: - 步骤管理
    @Published var currentStep: ReminderCreationStep = .selectPetsAndEvent
    
    // MARK: - 编辑状态
    @Published var isEditing: Bool = false
    var reminderToEdit: Reminder?
    
    // MARK: - 表单数据
    @Published var selectedPets: [Pet] = []
    @Published var selectedTag: Tag?
    @Published var startDate = Date()
    @Published var notes = ""
    @Published var isRepeating = false
    @Published var repeatInterval = 1
    @Published var repeatUnit: RepeatUnit = .weekly
    
    // MARK: - UI 状态
    @Published var availableTags: [Tag] = []
    @Published var recentlyUsedTags: [Tag] = [] // 添加最近使用的标签支持
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingTagSelection = false
    @Published var showingPetSelection = false
    
    // MARK: - ModelContext (为了复用Record组件)
    var modelContext: ModelContext?
    
    // MARK: - 验证状态
    var isFormValid: Bool {
        !selectedPets.isEmpty && selectedTag != nil
    }
    
    var isStepOneValid: Bool {
        !selectedPets.isEmpty && selectedTag != nil
    }
    
    // MARK: - 初始化
    init() {}
    
    init(reminder: Reminder) {
        setupForEditing(reminder)
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 步骤导航
    func moveToNextStep() {
        guard isStepOneValid else { return }
        
        switch currentStep {
        case .selectPetsAndEvent:
            currentStep = .reminderDetails
        case .reminderDetails:
            break // 已经是最后一步
        }
    }
    
    func moveToPreviousStep() {
        switch currentStep {
        case .selectPetsAndEvent:
            break // 已经是第一步
        case .reminderDetails:
            currentStep = .selectPetsAndEvent
        }
    }
    
    // MARK: - 设置编辑模式
    func setupForEditing(_ reminder: Reminder) {
        isEditing = true
        reminderToEdit = reminder
        currentStep = .selectPetsAndEvent // 编辑模式从第一步开始，让用户可以修改宠物和事件
        
        selectedPets = reminder.pets ?? []
        selectedTag = reminder.tag
        startDate = reminder.startDate
        notes = reminder.notes ?? ""
        
        if let interval = reminder.repeatInterval, let unit = reminder.repeatUnit {
            isRepeating = true
            repeatInterval = interval
            repeatUnit = unit
        } else {
            isRepeating = false
        }
    }
    
    // MARK: - 数据加载
    func loadAvailableTags(from modelContext: ModelContext? = nil) {
        let context = modelContext ?? self.modelContext
        guard let context = context else { return }
        
        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<Tag>()
                let allTags = try context.fetch(descriptor)
                
                // 根据选择的宠物过滤标签
                if self.selectedPets.isEmpty {
                    self.availableTags = allTags.filter { !$0.isHidden && $0.defaultIsReminder }
                } else {
                    // 获取所有选择宠物的共同标签（过滤掉nil值）
                    let petTypes = Set(self.selectedPets.compactMap { $0.petType })
                    self.availableTags = allTags.filter { tag in
                        !tag.isHidden &&
                        tag.defaultIsReminder &&
                        petTypes.allSatisfy { petType in
                            tag.isApplicableTo(petType: petType)
                        }
                    }
                }
                
                // 加载最近使用的标签（为了复用Record组件）
                self.loadRecentlyUsedTags(from: context)
                
                logger.info("加载了 \(self.availableTags.count) 个可用标签")
                
            } catch {
                logger.error("加载标签失败: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - 加载最近使用的标签 (复用Record组件需要)
    private func loadRecentlyUsedTags(from modelContext: ModelContext) {
        do {
            // 获取最近的提醒记录，提取其中使用的标签
            let descriptor = FetchDescriptor<Reminder>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let recentReminders = try modelContext.fetch(descriptor)
            
            // 获取最近使用的标签，去重并限制数量
            var usedTags: [Tag] = []
            var seenTagIds: Set<UUID> = []
            
            for reminder in recentReminders.prefix(20) { // 最多查看最近20个提醒
                if let tag = reminder.tag,
                   !seenTagIds.contains(tag.id),
                   !tag.isHidden,
                   tag.defaultIsReminder {
                    usedTags.append(tag)
                    seenTagIds.insert(tag.id)
                    
                    if usedTags.count >= 6 { // 最多显示6个最近使用的标签
                        break
                    }
                }
            }
            
            self.recentlyUsedTags = usedTags
            
        } catch {
            logger.error("加载最近使用标签失败: \(error.localizedDescription)")
            self.recentlyUsedTags = []
        }
    }
    
    // MARK: - 宠物选择
    func togglePetSelection(pet: Pet) {
        if selectedPets.contains(where: { $0.id == pet.id }) {
            selectedPets.removeAll { $0.id == pet.id }
        } else {
            selectedPets.append(pet)
        }
        
        // 当宠物选择改变时，重新加载可用标签
        if let context = modelContext {
            loadAvailableTags(from: context)
        }
    }
    
    func isPetSelected(_ pet: Pet) -> Bool {
        selectedPets.contains(where: { $0.id == pet.id })
    }
    
    // MARK: - 标签选择
    func selectTag(_ tag: Tag) {
        selectedTag = tag
        showingTagSelection = false
    }
    
    // MARK: - 加载标签方法 (为了兼容Record组件)
    func loadTags() {
        if let context = modelContext {
            loadAvailableTags(from: context)
        }
    }
    
    // MARK: - 重复设置
    func toggleRepeating() {
        isRepeating.toggle()
    }
    
    func setRepeatInterval(_ interval: Int) {
        repeatInterval = max(1, interval)
    }
    
    func setRepeatUnit(_ unit: RepeatUnit) {
        repeatUnit = unit
    }
    
    // MARK: - 保存提醒
    func saveReminder(modelContext: ModelContext) async -> Bool {
        guard isFormValid else {
            await MainActor.run {
                errorMessage = String(localized: "error.invalid_form")
            }
            return false
        }
        
        guard let tag = selectedTag else {
            await MainActor.run {
                errorMessage = String(localized: "error.no_tag_selected")
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                do {
                    if isEditing, let existingReminder = reminderToEdit {
                        // 更新现有提醒
                        existingReminder.pets = selectedPets
                        existingReminder.tag = tag
                        existingReminder.startDate = startDate
                        existingReminder.notes = notes.isEmpty ? nil : notes
                        existingReminder.repeatInterval = isRepeating ? repeatInterval : nil
                        existingReminder.repeatUnit = isRepeating ? repeatUnit : nil
                        existingReminder.updatedAt = Date()
                        
                        // 更新通知
                        NotificationService.removeNotificationsForReminder(reminderId: existingReminder.id)
                        ReminderService.setupNotificationsForReminder(reminder: existingReminder)
                        
                        logger.info("更新提醒: \(existingReminder.title)")
                    } else {
                        // 创建新提醒
                        let newReminder = Reminder(
                            startDate: startDate,
                            notes: notes.isEmpty ? nil : notes,
                            repeatInterval: isRepeating ? repeatInterval : nil,
                            repeatUnit: isRepeating ? repeatUnit : nil,
                            tag: tag,
                            pets: selectedPets
                        )
                        
                        modelContext.insert(newReminder)
                        
                        // 设置通知
                        ReminderService.setupNotificationsForReminder(reminder: newReminder)
                        
                        logger.info("创建新提醒: \(newReminder.title)")
                    }
                    
                    try modelContext.save()
                    
                    // 更新应用角标
                    NotificationService.updateApplicationBadge(modelContext: modelContext)
                    
                    isLoading = false
                    continuation.resume(returning: true)
                    
                } catch {
                    logger.error("保存提醒失败: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    isLoading = false
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - 重置表单
    func resetForm() {
        currentStep = .selectPetsAndEvent
        selectedPets.removeAll()
        selectedTag = nil
        startDate = Date()
        notes = ""
        isRepeating = false
        repeatInterval = 1
        repeatUnit = .weekly
        errorMessage = nil
        showingTagSelection = false
        showingPetSelection = false
    }
    
    // MARK: - 格式化显示
    var selectedPetsText: String {
        if selectedPets.isEmpty {
            return String(localized: "reminder.select_pets")
        } else if selectedPets.count == 1 {
            return selectedPets.first!.name
        } else {
            return String(localized: "reminder.multiple_pets_selected")
                .replacingOccurrences(of: "%d", with: "\(selectedPets.count)")
        }
    }
    
    var selectedTagText: String {
        selectedTag?.name ?? String(localized: "reminder.select_tag")
    }
    
    var repeatRuleText: String {
        if !isRepeating {
            return ""
        }
        
        if repeatInterval == 1 {
            switch repeatUnit {
            case .daily:
                return String(localized: "Every day")
            case .weekly:
                return String(localized: "Every week")
            case .monthly:
                return String(localized: "Every month")
            case .yearly:
                return String(localized: "Every year")
            }
        } else {
            switch repeatUnit {
            case .daily:
                return String(localized: "Every \(repeatInterval) days")
            case .weekly:
                return String(localized: "Every \(repeatInterval) weeks")
            case .monthly:
                return String(localized: "Every \(repeatInterval) months")
            case .yearly:
                return String(localized: "Every \(repeatInterval) years")
            }
        }
    }
} 