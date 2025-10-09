import Foundation
import SwiftData
import OSLog

/// 体重图表时间范围枚举
enum WeightChartTimeRange: String, CaseIterable {
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case all = "All"
    
    var localizedString: String {
        switch self {
        case .threeMonths: return String(localized: "3 Months")
        case .sixMonths: return String(localized: "6 Months")
        case .oneYear: return String(localized: "1 Year")
        case .all: return String(localized: "All")
        }
    }
}

/// 体重管理视图模型
@MainActor
class WeightViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightViewModel")
    
    // MARK: - Published Properties
    @Published var selectedPet: Pet?
    @Published var weightEntries: [Weight] = []
    @Published var activeWeightGoal: WeightGoal?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: WeightChartTimeRange = .sixMonths
    
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
        formatter.negativePrefix = "-"
        
        let unit = selectedPet?.weightUnitPreference ?? .kg
        let trendValue = unit == .kg ? trend : trend * 2.20462
        
        if let formattedValue = formatter.string(from: NSNumber(value: trendValue)) {
            return "\(formattedValue) \(unit.rawValue)"
        }
        
        return "--"
    }
    
    /// 体重变化趋势类型
    enum WeightTrendType {
        case increase, decrease, noChange, noData
    }
    
    /// 获取体重变化趋势类型
    var weightTrendType: WeightTrendType {
        guard let trend = weightTrend else { return .noData }
        
        if trend > 0 {
            return .increase
        } else if trend < 0 {
            return .decrease
        } else {
            return .noChange
        }
    }
    
    /// 格式化当前体重文本
    var formattedCurrentWeight: String {
        guard let latest = latestWeight else { return "--" }
        return latest.formattedWeight()
    }
    
    /// 格式化当前体重日期
    var formattedCurrentWeightDate: String {
        guard let latest = latestWeight else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: latest.date)
    }
    
    /// 格式化目标状态文本
    var formattedGoalStatusText: String {
        guard let goal = activeWeightGoal else { 
            return String(localized: "Set a weight goal to track progress")
        }
        return goal.formattedGoal
    }
    
    /// 格式化目标进度文本
    var formattedGoalProgressText: String {
        guard let goal = activeWeightGoal else { return "" }
        let progress = goal.calculateProgress() ?? 0.0
        return String(format: "%.0f%%", progress)
    }
    
    /// 格式化目标剩余天数文本
    var formattedGoalRemainingDays: String {
        guard let goal = activeWeightGoal else { return "" }
        let days = goal.remainingDays
        if days > 0 {
            return String(format: String(localized: "%d days left"), days)
        } else if days == 0 {
            return String(localized: "Target date is today")
        } else {
            return String(localized: "Target date has passed")
        }
    }
    
    /// 是否有目标设置
    var hasActiveGoal: Bool {
        return activeWeightGoal != nil
    }
    
    /// 目标按钮文本
    var goalButtonText: String {
        return hasActiveGoal ? String(localized: "Edit Goal") : String(localized: "Set Goal")
    }
    
    /// 获取图表空状态文本
    var chartEmptyStateText: String {
        return String(localized: "Not enough data for chart")
    }
    
    /// 获取历史记录空状态文本
    var historyEmptyStateText: String {
        return String(localized: "No weight records yet")
    }
    
    /// 图表数据（根据选择的时间范围显示）
    var chartData: [Weight] {
        let filteredEntries: [Weight]
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .threeMonths:
            // 3个月前的同一天
            if let startDate = calendar.date(byAdding: .month, value: -3, to: Date()) {
                filteredEntries = self.weightEntries.filter { $0.date >= startDate }
            } else {
                filteredEntries = self.weightEntries
            }
        case .sixMonths:
            // 6个月前的同一天
            if let startDate = calendar.date(byAdding: .month, value: -6, to: Date()) {
                filteredEntries = self.weightEntries.filter { $0.date >= startDate }
            } else {
                filteredEntries = self.weightEntries
            }
        case .oneYear:
            // 1年前的同一天
            if let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) {
                filteredEntries = self.weightEntries.filter { $0.date >= startDate }
            } else {
                filteredEntries = self.weightEntries
            }
        case .all:
            // 显示全部数据
            filteredEntries = self.weightEntries
        }
        
        // 按日期升序排列，用于图表显示
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        logger.debug("图表数据：时间范围\(self.selectedTimeRange.rawValue)，总共\(self.weightEntries.count)条记录，筛选后\(filteredEntries.count)条，排序后\(sortedEntries.count)条")
        return sortedEntries
    }
    
    // MARK: - 初始化
    init() {
        // 延迟初始化，避免并发问题
        Task { @MainActor in
            // 使用AppState的宠物筛选同步机制
            let appState = AppState.shared
            selectedPet = appState.getWeightPageFilter()
        }
    }
    
    // MARK: - 数据加载
    
    /// 加载指定宠物的体重数据
    /// - Parameters:
    ///   - pet: 目标宠物
    ///   - modelContext: 数据上下文
    ///   - showLoading: 是否显示加载动画（仅首次/切换宠物时）
    func loadWeightData(for pet: Pet, modelContext: ModelContext, showLoading: Bool = false) {
        logger.info("🐾 开始加载宠物体重数据: \(pet.name)")
        if showLoading { isLoading = true }
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
                if showLoading { self.isLoading = false }
                
                logger.info("✅ 成功加载体重数据: \(weights.count)条记录")
                if let goal = goal {
                    let unitStr = goal.unit?.rawValue ?? "kg"
                    logger.info("🎯 找到活跃体重目标: 目标\(goal.targetWeight)\(unitStr)，到期日期\(goal.targetDate)")
                    logger.info("📊 目标进度: \(String(format: "%.1f", goal.calculateProgress() ?? 0.0))%")
                } else {
                    logger.info("❌ 未找到活跃体重目标")
                }
            }
        }
    }
    
    /// 设置选中的宠物（用户主动选择）
    func setSelectedPet(_ pet: Pet, modelContext: ModelContext) {
        // 用户主动更改筛选，更新AppState
        let appState = AppState.shared
        appState.setWeightPageFilter(pet)
        
        // 加载新宠物的数据
        loadWeightData(for: pet, modelContext: modelContext, showLoading: true)
    }
    
    /// 刷新当前宠物的体重数据
    func refreshData(modelContext: ModelContext) {
        logger.info("🔄 刷新体重数据")
        guard let pet = selectedPet else { 
            logger.warning("⚠️ 刷新数据时宠物为空")
            return 
        }
        // 返回页面时的刷新不显示loading，避免闪烁
        loadWeightData(for: pet, modelContext: modelContext, showLoading: false)
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
    
    /// 格式化体重目标进度文本（保持向后兼容）
    func formattedGoalProgress() -> String {
        return formattedGoalProgressText.isEmpty ? "无目标" : formattedGoalProgressText
    }
    
    // MARK: - 新增的UI支持方法
    
    /// 最新体重记录的日期文本
    var latestWeightDateText: String {
        guard let latest = latestWeight else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: latest.date)
    }
    
    /// 体重变化的比较周期文本
    var weightChangeComparisonText: String {
        guard weightEntries.count >= 2 else { return "" }
        
        let latest = weightEntries[0]
        let previous = weightEntries[1]
        
        let daysDiff = Calendar.current.dateComponents([.day], from: previous.date, to: latest.date).day ?? 0
        
        if daysDiff <= 7 {
            return "vs last week"
        } else if daysDiff <= 30 {
            return "vs last month"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "since \(formatter.string(from: previous.date))"
        }
    }
    
    /// 完整的体重变化描述文本（包含比较周期）
    var formattedWeightChangeWithContext: String {
        let trendText = formattedWeightTrend
        let contextText = weightChangeComparisonText
        
        if trendText == "--" || contextText.isEmpty {
            return trendText
        }
        
        return "\(trendText) (\(contextText))"
    }
    
    /// 体重目标的剩余天数
    var goalRemainingDays: Int? {
        guard let goal = activeWeightGoal else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day
    }
    
    /// 体重目标的行动建议文本
    var goalActionSuggestion: String {
        guard let goal = activeWeightGoal,
              let current = latestWeight else { return "" }
        
        let currentWeight = current.weightInKg
        let targetWeight = goal.targetWeight
        
        if abs(currentWeight - targetWeight) <= 0.2 {
            return "Almost there! Keep it up"
        } else if currentWeight < targetWeight {
            return "Need to gain weight"
        } else {
            return "Need to lose weight"
        }
    }
} 