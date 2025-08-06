import Foundation
import SwiftData
import SwiftUI
import OSLog

/// 记录模块的视图模型
class RecordViewModel: ObservableObject {
    // MARK: - 属性
    var modelContext: ModelContext
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "RecordViewModel")
    
    // 记录列表状态
    @Published var records: [Record] = []
    @Published var searchText: String = ""
    @Published var selectedPets: [Pet] = []
    @Published var currentPet: Pet?
    @Published var selectedTag: Tag?
    @Published var isShowingAllPets: Bool = true
    @Published var isLoading: Bool = false
    
    // 添加记录状态
    @Published var currentStep: RecordCreationStep = .selectPetsAndEvent
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
        
        // 如果只有一只宠物，自动设置为当前宠物
        let descriptor = FetchDescriptor<Pet>()
        if let pets = try? modelContext.fetch(descriptor), pets.count == 1 {
            self.currentPet = pets.first
        }
        
        loadRecords()
        loadRecentlyUsedTags()
    }
    
    // MARK: - 公共方法
    
    /// 设置当前宠物
    func setCurrentPet(_ pet: Pet) {
        currentPet = pet
        if !isShowingAllPets {
            loadRecords()
        }
    }
    
    /// 加载标签数据（用于标签管理后刷新）
    func loadTags() {
        loadRecentlyUsedTags()
        logger.info("重新加载标签数据")
    }
    
    /// 加载记录
    func loadRecords() {
        isLoading = true
        
        // 根据当前筛选条件获取记录
        if isShowingAllPets {
            // 显示所有宠物的所有记录
            records = RecordService.getAllRecords(modelContext: modelContext)
        } else if let pet = currentPet {
            // 显示包含该宠物的所有记录（包括多宠物记录）
            records = RecordService.getAllRecords(forPet: pet, modelContext: modelContext)
        } else {
            records = []
        }
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            records = records.filter { record in
                record.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                record.tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        isLoading = false
    }
    
    /// 切换宠物筛选
    func togglePetFilter(isAllPets: Bool) {
        isShowingAllPets = isAllPets
        loadRecords()
    }
    
    /// 按日期筛选记录
    func filterRecordsByDate(_ date: Date) {
        isLoading = true
        
        // 创建日期范围（从当天开始到当天结束）
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 获取基础记录集合
        var baseRecords: [Record]
        if isShowingAllPets {
            // 显示所有宠物的所有记录
            baseRecords = RecordService.getAllRecords(modelContext: modelContext)
        } else if let pet = currentPet {
            // 显示包含该宠物的所有记录（包括多宠物记录）
            baseRecords = RecordService.getAllRecords(forPet: pet, modelContext: modelContext)
        } else {
            baseRecords = []
        }
        
        // 按日期筛选
        records = baseRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            records = records.filter { record in
                record.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                record.tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        isLoading = false
    }
    
    /// 按标签筛选记录
    func filterRecordsByTag(_ tag: Tag) {
        isLoading = true
        
        // 获取基础记录集合
        var baseRecords: [Record]
        if isShowingAllPets {
            // 显示所有宠物的所有记录
            baseRecords = RecordService.getAllRecords(modelContext: modelContext)
        } else if let pet = currentPet {
            // 显示包含该宠物的所有记录（包括多宠物记录）
            baseRecords = RecordService.getAllRecords(forPet: pet, modelContext: modelContext)
        } else {
            baseRecords = []
        }
        
        // 按标签筛选
        records = baseRecords.filter { record in
            record.tag.id == tag.id
        }
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            records = records.filter { record in
                record.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                record.tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        isLoading = false
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
        guard let selectedTag = selectedTag,
              !selectedPets.isEmpty else {
            logger.error("保存记录失败：缺少必要信息")
            return false
        }
        
        do {
            // 创建记录
            let record = Record(
                timestamp: recordDate,
                notes: recordNotes.isEmpty ? nil : recordNotes,
                tag: selectedTag,
                pets: selectedPets
            )
            
            // 插入到数据库
            modelContext.insert(record)
            
            // 添加照片
            for photo in recordPhotos {
                if let photoData = photo.jpegData(compressionQuality: 0.7) {
                    let recordPhoto = RecordPhoto(
                        photoData: photoData,
                        record: record
                    )
                    modelContext.insert(recordPhoto)
                }
            }
            
            // 保存更改
            try modelContext.save()
            
            // 更新最近使用的标签
            updateRecentlyUsedTag(selectedTag)
            
            // 立即刷新记录列表
            loadRecords()
            
            // 重置表单
            resetForm()
            
            logger.info("成功保存记录")
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
    
    // MARK: - 记录管理
    
    /// 创建记录
    func createRecord() async -> Bool {
        guard let selectedTag = selectedTag,
              !selectedPets.isEmpty else {
            logger.error("创建记录失败：缺少必要信息")
            return false
        }
        
        do {
            // 创建记录
            let record = Record(
                timestamp: recordDate,
                notes: recordNotes,
                tag: selectedTag,
                pets: selectedPets
            )
            
            // 插入到数据库
            modelContext.insert(record)
            
            // 添加照片
            for photo in recordPhotos {
                if let photoData = photo.jpegData(compressionQuality: 0.8) {
                    let recordPhoto = RecordPhoto(
                        photoData: photoData,
                        record: record
                    )
                    modelContext.insert(recordPhoto)
                    logger.info("成功为记录添加照片: \(recordPhoto.id)")
                }
            }
            
            // 保存更改
            try modelContext.save()
            
            // 更新最近使用的标签
            updateRecentlyUsedTag(selectedTag)
            
            logger.info("成功创建记录")
            
            // 立即刷新记录列表
            await MainActor.run {
                loadRecords()
            }
            
            return true
        } catch {
            logger.error("创建记录失败: \(error.localizedDescription)")
            return false
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
        selectedPets = []
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