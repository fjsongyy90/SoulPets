import Foundation
import SwiftData
import OSLog

/// 体重管理视图模型
@MainActor
class WeightViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "WeightViewModel")
    
    // MARK: - Published Properties
    @Published var selectedPet: Pet?
    @Published var weightEntries: [Weight] = []
    @Published var activeWeightGoal: WeightGoal?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 计算属性
    
    /// 是否有体重数据
    var hasWeightData: Bool {
        !weightEntries.isEmpty
    }
    
    /// 最新体重记录
    var latestWeight: Weight? {
        weightEntries.first
    }
    
    /// 体重变化趋势
    var weightTrend: Double? {
        guard weightEntries.count >= 2 else { return nil }
        let latest = weightEntries[0].weightInKg
        let previous = weightEntries[1].weightInKg
        return latest - previous
    }
    
    /// 格式化的体重变化文本
    var formattedWeightTrend: String {
        guard let trend = weightTrend else { return "--" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        
        let unit = selectedPet?.weightUnitPreference ?? .kg
        let trendValue = unit == .kg ? trend : trend * 2.20462
        
        if let formattedValue = formatter.string(from: NSNumber(value: abs(trendValue))) {
            let arrow = trend > 0 ? "↑" : "↓"
            return "\(arrow) \(formattedValue) \(unit.rawValue)"
        }
        
        return "--"
    }
    
    /// 图表数据（显示所有记录，按时间升序）
    var chartData: [Weight] {
        // 按日期升序排列，用于图表显示
        let sortedEntries = self.weightEntries.sorted { $0.date < $1.date }
        logger.debug("图表数据：总共\(self.weightEntries.count)条记录，排序后\(sortedEntries.count)条")
        return sortedEntries
    }
    
    // MARK: - 初始化
    init() {}
    
    // MARK: - 数据加载
    
    /// 加载指定宠物的体重数据
    func loadWeightData(for pet: Pet, modelContext: ModelContext) {
        logger.info("开始加载宠物体重数据: \(pet.name)")
        isLoading = true
        errorMessage = nil
        
        Task {
            // 加载体重记录
            let weights = WeightService.getWeightEntries(for: pet, modelContext: modelContext)
            
            // 加载活跃的体重目标
            let goal = WeightService.getActiveWeightGoal(for: pet, modelContext: modelContext)
            
            await MainActor.run {
                self.selectedPet = pet
                self.weightEntries = weights
                self.activeWeightGoal = goal
                self.isLoading = false
                
                logger.info("成功加载体重数据: \(weights.count)条记录")
                if let goal = goal {
                    logger.info("找到活跃体重目标: 目标\(goal.targetWeight)kg，到期日期\(goal.targetDate)")
                } else {
                    logger.info("未找到活跃体重目标")
                }
            }
        }
    }
    
    /// 刷新当前宠物的体重数据
    func refreshData(modelContext: ModelContext) {
        guard let pet = selectedPet else { return }
        loadWeightData(for: pet, modelContext: modelContext)
    }
    
    // MARK: - 体重操作
    
    /// 添加新的体重记录
    func addWeight(weightInUnit: Double, unit: WeightUnit, date: Date, modelContext: ModelContext) {
        guard let pet = selectedPet else {
            logger.error("尝试添加体重记录时宠物为空")
            return
        }
        
        WeightService.addWeight(
            pet: pet,
            weightInUnit: weightInUnit,
            unit: unit,
            date: date,
            modelContext: modelContext
        )
        
        // 刷新数据
        refreshData(modelContext: modelContext)
    }
    
    /// 更新体重记录
    func updateWeight(_ weight: Weight, newWeightInUnit: Double, unit: WeightUnit, newDate: Date, modelContext: ModelContext) {
        WeightService.updateWeight(
            weight: weight,
            newWeightInUnit: newWeightInUnit,
            unit: unit,
            newDate: newDate,
            modelContext: modelContext
        )
        
        // 刷新数据
        refreshData(modelContext: modelContext)
    }
    
    /// 删除体重记录
    func deleteWeight(_ weight: Weight, modelContext: ModelContext) {
        WeightService.deleteWeight(weight: weight, modelContext: modelContext)
        
        // 刷新数据
        refreshData(modelContext: modelContext)
    }
    
    // MARK: - 体重目标操作
    
    /// 创建体重目标
    func createWeightGoal(targetWeight: Double, unit: WeightUnit, targetDate: Date, modelContext: ModelContext) {
        guard let pet = selectedPet else {
            logger.error("尝试创建体重目标时宠物为空")
            return
        }
        
        WeightService.createWeightGoal(
            pet: pet,
            targetWeight: targetWeight,
            unit: unit,
            targetDate: targetDate,
            modelContext: modelContext
        )
        
        // 刷新数据
        refreshData(modelContext: modelContext)
    }
    
    /// 取消当前体重目标
    func cancelWeightGoal(modelContext: ModelContext) {
        guard let goal = activeWeightGoal else { return }
        
        goal.isActive = false
        goal.updatedAt = Date()
        
        do {
            try modelContext.save()
            logger.info("成功取消体重目标")
            refreshData(modelContext: modelContext)
        } catch {
            logger.error("取消体重目标失败: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 工具方法
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    /// 获取体重目标进度百分比
    func getGoalProgress() -> Double {
        return activeWeightGoal?.calculateProgress() ?? 0.0
    }
    
    /// 格式化体重目标进度文本
    func formattedGoalProgress() -> String {
        guard activeWeightGoal != nil else { return "无目标" }
        let progress = getGoalProgress()
        return String(format: "%.0f%%", progress)
    }
} 