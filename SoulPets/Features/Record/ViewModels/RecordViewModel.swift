import Foundation
import SwiftData
import SwiftUI
import OSLog

/// 记录模块的视图模型
class RecordViewModel: ObservableObject {
    // MARK: - 属性
    var modelContext: ModelContext
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "RecordViewModel")
    
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
    
    // 照片限制提示
    @Published var showPhotoLimitAlert: Bool = false
    
    // MARK: - 初始化
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // 延迟初始化，避免并发问题
        DispatchQueue.main.async {
            // 使用AppState的宠物筛选同步机制
            let appState = AppState.shared
            let filterState = appState.getRecordsPageFilter()
            
            switch filterState {
            case .all:
                self.isShowingAllPets = true
                self.currentPet = nil
            case .specific(let pet):
                self.isShowingAllPets = false
                self.currentPet = pet
            }
            
            self.loadRecords()
            self.loadRecentlyUsedTags()
        }
    }
    
    // MARK: - 公共方法
    
    /// 设置当前宠物
    @MainActor
    func setCurrentPet(_ pet: Pet, updateAppState: Bool = false) {
        currentPet = pet
        isShowingAllPets = false
        
        // 🔧 关键修复：只有在用户主动操作时才更新AppState
        if updateAppState {
            let appState = AppState.shared
            appState.setRecordsPageFilter(.specific(pet))
        }
        
        loadRecords()
    }
    
    /// 设置显示所有宠物
    @MainActor
    func setShowAllPets(updateAppState: Bool = false) {
        isShowingAllPets = true
        currentPet = nil
        
        // 🔧 关键修复：只有在用户主动操作时才更新AppState
        if updateAppState {
            let appState = AppState.shared
            appState.setRecordsPageFilter(.all)
        }
        
        loadRecords()
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
        
        // 检查非会员照片数量限制
        if !UserPreferencesService.shared.isProMember && !recordPhotos.isEmpty {
            for pet in selectedPets {
                let currentPhotoCount = getPhotoCountForPet(pet)
                let newPhotoCount = currentPhotoCount + recordPhotos.count
                
                if newPhotoCount > UserPreferencesService.shared.maxPhotosPerPet {
                    // 触发照片限制提示
                    showPhotoLimitAlert = true
                    return false
                }
            }
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
            
            // 添加照片 - 使用更低的压缩质量以减少文件大小
            for photo in recordPhotos {
                if let photoData = photo.jpegData(compressionQuality: 0.5) {
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
            
            // 添加照片 - 使用更低的压缩质量以减少文件大小
            for photo in recordPhotos {
                if let photoData = photo.jpegData(compressionQuality: 0.5) {
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
        // 目前先使用空数组，但需要确保过滤掉隐藏的标签
        // 如果有持久化的最近使用标签，需要过滤掉隐藏的标签
        recentlyUsedTags = recentlyUsedTags.filter { !$0.isHidden }
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
    
    /// 获取指定宠物的照片总数
    private func getPhotoCountForPet(_ pet: Pet) -> Int {
        do {
            // 获取包含该宠物的所有记录
            let descriptor = FetchDescriptor<Record>()
            let allRecords = try modelContext.fetch(descriptor)
            
            // 筛选出包含该宠物的记录
            let petRecords = allRecords.filter { record in
                record.pets?.contains(where: { $0.id == pet.id }) == true
            }
            
            // 统计所有照片数量
            var totalPhotoCount = 0
            for record in petRecords {
                if let photos = record.photos {
                    totalPhotoCount += photos.count
                }
            }
            
            return totalPhotoCount
        } catch {
            logger.error("获取宠物照片数量失败: \(error.localizedDescription)")
            return 0
        }
    }
}

/// 记录创建步骤
enum RecordCreationStep {
    case selectPetsAndEvent
    case recordDetails
} 