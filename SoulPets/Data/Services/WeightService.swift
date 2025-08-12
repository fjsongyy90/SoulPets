import Foundation
import SwiftData
import OSLog

/// 体重服务，负责处理体重相关的业务逻辑
class WeightService {
    private static let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "Weight")
    
    /// 获取宠物的所有体重记录（按日期降序排列）
    static func getWeightEntries(for pet: Pet, modelContext: ModelContext) -> [Weight] {
        // 获取所有体重记录
        let descriptor = FetchDescriptor<Weight>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allWeights = try modelContext.fetch(descriptor)
            
            // 在内存中过滤特定宠物的体重记录
            return allWeights.filter { $0.pet.id == pet.id }
        } catch {
            logger.error("获取宠物体重记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取宠物的最近体重记录
    static func getLatestWeight(for pet: Pet, modelContext: ModelContext) -> Weight? {
        // 获取所有体重记录
        let descriptor = FetchDescriptor<Weight>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allWeights = try modelContext.fetch(descriptor)
            
            // 在内存中过滤并获取最近的一条记录
            return allWeights.filter { $0.pet.id == pet.id }.first
        } catch {
            logger.error("获取宠物最近体重记录时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 添加新的体重记录
    static func addWeight(pet: Pet, weightInUnit: Double, unit: WeightUnit, date: Date, modelContext: ModelContext) {
        // 验证输入参数
        guard weightInUnit.isFinite, weightInUnit > 0, weightInUnit < 1000 else {
            logger.error("无效的体重值: \(weightInUnit)")
            return
        }
        
        // 将体重统一转换为kg存储
        let weightInKg: Double
        if unit == .kg {
            weightInKg = weightInUnit
        } else {
            let converted = weightInUnit / 2.20462
            weightInKg = converted.isFinite && converted > 0 ? converted : weightInUnit
        }
        
        let newWeight = Weight(
            date: date,
            weightInKg: weightInKg,
            pet: pet
        )
        
        modelContext.insert(newWeight)
        
        do {
            try modelContext.save()
            logger.info("成功添加体重记录: \(pet.name), \(weightInUnit) \(unit.rawValue)")
        } catch {
            logger.error("添加体重记录时出错: \(error.localizedDescription)")
        }
    }
    
    /// 更新体重记录
    static func updateWeight(weight: Weight, newWeightInUnit: Double, unit: WeightUnit, newDate: Date, modelContext: ModelContext) {
        // 验证输入参数
        guard newWeightInUnit.isFinite, newWeightInUnit > 0, newWeightInUnit < 1000 else {
            logger.error("无效的体重值: \(newWeightInUnit)")
            return
        }
        
        // 将体重统一转换为kg存储
        let weightInKg: Double
        if unit == .kg {
            weightInKg = newWeightInUnit
        } else {
            let converted = newWeightInUnit / 2.20462
            weightInKg = converted.isFinite && converted > 0 ? converted : newWeightInUnit
        }
        
        weight.weightInKg = weightInKg
        weight.date = newDate
        weight.updatedAt = Date()
        
        do {
            try modelContext.save()
            logger.info("成功更新体重记录: \(weight.id)")
        } catch {
            logger.error("更新体重记录时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除体重记录
    static func deleteWeight(weight: Weight, modelContext: ModelContext) {
        modelContext.delete(weight)
        
        do {
            try modelContext.save()
            logger.info("成功删除体重记录: \(weight.id)")
        } catch {
            logger.error("删除体重记录时出错: \(error.localizedDescription)")
        }
    }
    
    /// 获取宠物的体重变化趋势（最近几条记录的体重差异）
    static func getWeightTrend(pet: Pet, modelContext: ModelContext) -> Double? {
        // 获取所有体重记录
        let descriptor = FetchDescriptor<Weight>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allWeights = try modelContext.fetch(descriptor)
            
            // 在内存中过滤特定宠物的体重记录并获取最近两条
            let recentWeights = allWeights.filter { $0.pet.id == pet.id }.prefix(2)
            
            // 需要至少有两条记录才能计算趋势
            guard recentWeights.count >= 2 else { return nil }
            
            // 获取最新和次新的体重
            let weights = Array(recentWeights)
            let latestWeight = weights[0].weightInKg
            let previousWeight = weights[1].weightInKg
            
            // 计算差异（正值表示增重，负值表示减重）
            return latestWeight - previousWeight
        } catch {
            logger.error("计算体重趋势时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取宠物的活跃体重目标
    static func getActiveWeightGoal(for pet: Pet, modelContext: ModelContext) -> WeightGoal? {
        logger.info("🔍 开始查找宠物 \(pet.name) 的活跃体重目标")
        
        // 获取所有体重目标
        let descriptor = FetchDescriptor<WeightGoal>()
        
        do {
            let allGoals = try modelContext.fetch(descriptor)
            logger.info("📊 数据库中总共有 \(allGoals.count) 个体重目标")
            
            // 打印所有目标的详细信息
            for (index, goal) in allGoals.enumerated() {
                logger.info("目标 \(index + 1): 宠物ID=\(goal.pet.id), 宠物名=\(goal.pet.name), 目标体重=\(goal.targetWeight), 单位=\(goal.unit.rawValue), 是否活跃=\(goal.isActive), 目标日期=\(goal.targetDate)")
            }
            
            // 在内存中过滤特定宠物的活跃目标
            let activeGoal = allGoals.first { goal in
                let isPetMatch = goal.pet.id == pet.id
                let isActive = goal.isActive == true
                logger.debug("检查目标: 宠物匹配=\(isPetMatch), 活跃状态=\(isActive)")
                return isPetMatch && isActive
            }
            
            if let goal = activeGoal {
                logger.info("✅ 找到活跃体重目标: 目标体重=\(goal.targetWeight) \(goal.unit.rawValue), 目标日期=\(goal.targetDate)")
            } else {
                logger.info("❌ 未找到宠物 \(pet.name) 的活跃体重目标")
            }
            
            return activeGoal
        } catch {
            logger.error("获取体重目标时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建新的体重目标
    static func createWeightGoal(pet: Pet, targetWeight: Double, unit: WeightUnit, targetDate: Date, modelContext: ModelContext) {
        logger.info("🎯 开始为宠物 \(pet.name) 创建体重目标")
        logger.info("📝 目标详情: 体重=\(targetWeight) \(unit.rawValue), 目标日期=\(targetDate)")
        
        // 先将之前的活跃目标设为非活跃
        deactivateCurrentWeightGoals(pet: pet, modelContext: modelContext)
        
        // 创建新目标
        let newGoal = WeightGoal(
            targetWeight: targetWeight,
            unit: unit,
            startDate: Date(),
            targetDate: targetDate,
            pet: pet
        )
        
        logger.info("💾 插入新的体重目标到数据库")
        modelContext.insert(newGoal)
        
        do {
            try modelContext.save()
            logger.info("✅ 成功为\(pet.name)创建体重目标: \(targetWeight) \(unit.rawValue)")
            
            // 验证保存结果
            let verifyGoal = getActiveWeightGoal(for: pet, modelContext: modelContext)
            if verifyGoal != nil {
                logger.info("✅ 验证成功: 新目标已正确保存并可查询")
            } else {
                logger.error("❌ 验证失败: 新目标保存后无法查询到")
            }
        } catch {
            logger.error("❌ 创建体重目标时出错: \(error.localizedDescription)")
        }
    }
    
    /// 将宠物当前的所有体重目标设为非活跃
    private static func deactivateCurrentWeightGoals(pet: Pet, modelContext: ModelContext) {
        logger.info("🔄 开始将宠物 \(pet.name) 的现有活跃目标设为非活跃")
        
        // 获取所有体重目标
        let descriptor = FetchDescriptor<WeightGoal>()
        
        do {
            let allGoals = try modelContext.fetch(descriptor)
            
            // 在内存中过滤特定宠物的活跃目标
            let activeGoals = allGoals.filter { goal in
                goal.pet.id == pet.id && goal.isActive == true
            }
        
            logger.info("📊 找到 \(activeGoals.count) 个需要设为非活跃的目标")
            
            for goal in activeGoals {
                logger.info("🔄 将目标设为非活跃: 目标体重=\(goal.targetWeight) \(goal.unit.rawValue)")
                goal.isActive = false
                goal.updatedAt = Date()
            }
            
            try modelContext.save()
            logger.info("✅ 已将\(pet.name)的\(activeGoals.count)个活跃体重目标设为非活跃")
        } catch {
            logger.error("❌ 更新体重目标状态时出错: \(error.localizedDescription)")
        }
    }
    
    /// 获取宠物的体重统计数据（用于图表显示）
    static func getWeightChartData(for pet: Pet, period: Int = 180, modelContext: ModelContext) -> [Weight] {
        // 默认获取最近6个月的数据
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -period, to: Date()) else {
            return []
        }
        
        // 获取所有体重记录
        let descriptor = FetchDescriptor<Weight>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let allWeights = try modelContext.fetch(descriptor)
            
            // 在内存中过滤特定宠物的体重记录并按时间范围筛选
            return allWeights.filter { 
                $0.pet.id == pet.id && $0.date >= startDate 
            }
        } catch {
            logger.error("获取体重图表数据时出错: \(error.localizedDescription)")
            return []
        }
    }
} 