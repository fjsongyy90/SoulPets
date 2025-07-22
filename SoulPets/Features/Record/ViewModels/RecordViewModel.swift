import Foundation
import SwiftData
import SwiftUI
import OSLog

/// 记录模块的视图模型
class RecordViewModel: ObservableObject {
    // MARK: - 属性
    private var modelContext: ModelContext
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "RecordViewModel")
    
    // 记录列表状态
    @Published var records: [Record] = []
    @Published var searchText: String = ""
    @Published var selectedPets: [Pet] = []
    @Published var isShowingAllPets: Bool = true
    @Published var isLoading: Bool = false
    
    // 添加记录状态
    @Published var currentStep: RecordCreationStep = .selectPetsAndEvent
    @Published var selectedTag: Tag?
    @Published var recordDate: Date = Date()
    @Published var recordNotes: String = ""
    @Published var recordPhotos: [UIImage] = []
    @Published var recordCost: String = ""
    
    // 表单验证
    @Published var formIsValid: Bool = false
    
    // 最近使用的标签
    @Published var recentlyUsedTags: [Tag] = []
    
    // MARK: - 初始化
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecords()
        loadRecentlyUsedTags()
    }
    
    // MARK: - 公共方法
    
    /// 加载记录
    func loadRecords() {
        isLoading = true
        
        if isShowingAllPets {
            records = RecordService.getAllRecords(modelContext: modelContext)
        } else if let pet = selectedPets.first {
            records = RecordService.getAllRecords(forPet: pet, modelContext: modelContext)
        } else {
            records = []
        }
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            records = RecordService.searchRecords(withKeyword: searchText, modelContext: modelContext)
        }
        
        isLoading = false
    }
    
    /// 切换宠物筛选
    func togglePetFilter(isAllPets: Bool) {
        isShowingAllPets = isAllPets
        loadRecords()
    }
    
    /// 选择宠物
    func togglePetSelection(pet: Pet) {
        if let index = selectedPets.firstIndex(where: { $0.id == pet.id }) {
            selectedPets.remove(at: index)
        } else {
            selectedPets.append(pet)
        }
        validateForm()
    }
    
    /// 选择标签
    func selectTag(_ tag: Tag) {
        selectedTag = tag
        validateForm()
    }
    
    /// 验证表单
    func validateForm() {
        switch currentStep {
        case .selectPetsAndEvent:
            formIsValid = !selectedPets.isEmpty && selectedTag != nil
        case .recordDetails:
            formIsValid = true // 详情页面的所有字段都是可选的
        }
    }
    
    /// 进入下一步
    func moveToNextStep() {
        if currentStep == .selectPetsAndEvent && formIsValid {
            currentStep = .recordDetails
        }
    }
    
    /// 返回上一步
    func moveToPreviousStep() {
        if currentStep == .recordDetails {
            currentStep = .selectPetsAndEvent
        }
    }
    
    /// 保存记录
    func saveRecord() -> Bool {
        guard formIsValid else { return false }
        
        guard let tag = selectedTag else {
            logger.error("保存记录失败：未选择标签")
            return false
        }
        
        do {
            // 创建记录
            let newRecord = Record(
                timestamp: recordDate,
                notes: recordNotes.isEmpty ? nil : recordNotes,
                tag: tag,
                pets: selectedPets
            )
            
            // 添加到数据库
            modelContext.insert(newRecord)
            
            // 保存照片
            for image in recordPhotos {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    RecordService.addPhotoToRecord(record: newRecord, photoData: imageData, modelContext: modelContext)
                }
            }
            
            // 保存到数据库
            try modelContext.save()
            
            // 更新最近使用的标签
            updateRecentlyUsedTag(tag)
            
            // 重置表单
            resetForm()
            
            logger.info("成功创建记录")
            return true
            
        } catch {
            logger.error("保存记录时出错: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除记录
    func deleteRecord(_ record: Record) {
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            loadRecords()
            logger.info("成功删除记录")
        } catch {
            logger.error("删除记录时出错: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 私有方法
    
    /// 重置表单
    private func resetForm() {
        currentStep = .selectPetsAndEvent
        selectedTag = nil
        recordDate = Date()
        recordNotes = ""
        recordPhotos = []
        recordCost = ""
        formIsValid = false
    }
    
    /// 加载最近使用的标签
    private func loadRecentlyUsedTags() {
        // 这里应该从UserDefaults或其他持久化存储中加载最近使用的标签
        // 目前先使用空数组
        recentlyUsedTags = []
    }
    
    /// 更新最近使用的标签
    private func updateRecentlyUsedTag(_ tag: Tag) {
        // 检查标签是否已在列表中
        if let index = recentlyUsedTags.firstIndex(where: { $0.id == tag.id }) {
            // 如果已存在，移到列表顶部
            recentlyUsedTags.remove(at: index)
            recentlyUsedTags.insert(tag, at: 0)
        } else {
            // 如果不存在，添加到列表顶部
            recentlyUsedTags.insert(tag, at: 0)
            
            // 保持列表不超过5个
            if recentlyUsedTags.count > 5 {
                recentlyUsedTags.removeLast()
            }
        }
        
        // 这里应该将更新后的列表保存到UserDefaults或其他持久化存储中
    }
}

/// 记录创建步骤
enum RecordCreationStep {
    case selectPetsAndEvent
    case recordDetails
} 