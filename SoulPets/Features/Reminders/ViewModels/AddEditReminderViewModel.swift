import Foundation
import SwiftData
import OSLog

@Observable
class AddEditReminderViewModel {
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "AddEditReminderViewModel")
    
    // MARK: - 编辑状态
    var isEditing: Bool = false
    var reminderToEdit: Reminder?
    
    // MARK: - 表单数据
    var selectedPets: [Pet] = []
    var selectedTag: Tag?
    var startDate = Date()
    var notes = ""
    var isRepeating = false
    var repeatInterval = 1
    var repeatUnit: RepeatUnit = .weekly
    
    // MARK: - UI 状态
    var availableTags: [Tag] = []
    var isLoading = false
    var errorMessage: String?
    var showingTagSelection = false
    var showingPetSelection = false
    
    // MARK: - 验证状态
    var isFormValid: Bool {
        !selectedPets.isEmpty && selectedTag != nil
    }
    
    // MARK: - 初始化
    init() {}
    
    init(reminder: Reminder) {
        setupForEditing(reminder)
    }
    
    // MARK: - 设置编辑模式
    func setupForEditing(_ reminder: Reminder) {
        isEditing = true
        reminderToEdit = reminder
        
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
    func loadAvailableTags(from modelContext: ModelContext) {
        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<Tag>()
                let allTags = try modelContext.fetch(descriptor)
                
                // 根据选择的宠物过滤标签
                if self.selectedPets.isEmpty {
                    self.availableTags = allTags.filter { !$0.isHidden && $0.defaultIsReminder }
                } else {
                    // 获取所有选择宠物的共同标签
                    let petTypes = Set(self.selectedPets.map { $0.petType })
                    self.availableTags = allTags.filter { tag in
                        !tag.isHidden &&
                        tag.defaultIsReminder &&
                        petTypes.allSatisfy { petType in
                            tag.isApplicableTo(petType: petType)
                        }
                    }
                }
                
                logger.info("加载了 \(self.availableTags.count) 个可用标签")
                
            } catch {
                logger.error("加载标签失败: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - 宠物选择
    func togglePetSelection(_ pet: Pet) {
        if selectedPets.contains(where: { $0.id == pet.id }) {
            selectedPets.removeAll { $0.id == pet.id }
        } else {
            selectedPets.append(pet)
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
            errorMessage = String(localized: "error.invalid_form")
            return false
        }
        
        guard let tag = selectedTag else {
            errorMessage = String(localized: "error.no_tag_selected")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
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
            isLoading = false
            return true
            
        } catch {
            logger.error("保存提醒失败: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - 重置表单
    func resetForm() {
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
            return String(localized: "reminder.no_repeat")
        }
        
        if repeatInterval == 1 {
            return String(localized: "reminder.repeat_every_\(repeatUnit.rawValue.lowercased())")
        } else {
            return String(localized: "reminder.repeat_every_x_\(repeatUnit.rawValue.lowercased())")
                .replacingOccurrences(of: "%d", with: "\(repeatInterval)")
        }
    }
} 