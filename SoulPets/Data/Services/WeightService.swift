import Foundation
import SwiftData
import OSLog

/// 体重服务，负责处理体重相关的业务逻辑
class WeightService {
    private static let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "Weight")
    
    /// 获取宠物的所有体重记录（按日期降序排列）
    static func getWeightEntries(for pet: Pet, modelContext: ModelContext) -> [Weight] {
        let descriptor = FetchDescriptor<Weight>(
            predicate: #Predicate<Weight> { weight in
                weight.pet.id == pet.id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("获取宠物体重记录时出错: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取宠物的最近体重记录
    static func getLatestWeight(for pet: Pet, modelContext: ModelContext) -> Weight? {
        let descriptor = FetchDescriptor<Weight>(
            predicate: #Predicate<Weight> { weight in
                weight.pet.id == pet.id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: 1
        )
        
        do {
            let weights = try modelContext.fetch(descriptor)
            return weights.first
        } catch {
            logger.error("获取宠物最近体重记录时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 添加新的体重记录
    static func addWeight(pet: Pet, weightInUnit: Double, unit: WeightUnit, date: Date, modelContext: ModelContext) {
        // 将体重统一转换为kg存储
        let weightInKg = (unit == .kg) ? weightInUnit : (weightInUnit / 2.20462)
        
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
        // 将体重统一转换为kg存储
        weight.weightInKg = (unit == .kg) ? newWeightInUnit : (newWeightInUnit / 2.20462)
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
        let descriptor = FetchDescriptor<Weight>(
            predicate: #Predicate<Weight> { weight in
                weight.pet.id == pet.id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: 2
        )
        
        do {
            let recentWeights = try modelContext.fetch(descriptor)
            
            // 需要至少有两条记录才能计算趋势
            guard recentWeights.count >= 2 else { return nil }
            
            let latestWeight = recentWeights[0].weightInKg
            let previousWeight = recentWeights[1].weightInKg
            
            // 计算差异（正值表示增重，负值表示减重）
            return latestWeight - previousWeight
        } catch {
            logger.error("计算体重趋势时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取宠物的活跃体重目标
    static func getActiveWeightGoal(for pet: Pet, modelContext: ModelContext) -> WeightGoal? {
        let descriptor = FetchDescriptor<WeightGoal>(
            predicate: #Predicate<WeightGoal> { goal in
                goal.pet.id == pet.id && goal.isActive == true
            }
        )
        
        do {
            let goals = try modelContext.fetch(descriptor)
            return goals.first
        } catch {
            logger.error("获取体重目标时出错: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建新的体重目标
    static func createWeightGoal(pet: Pet, targetWeight: Double, unit: WeightUnit, targetDate: Date, modelContext: ModelContext) {
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
        
        modelContext.insert(newGoal)
        
        do {
            try modelContext.save()
            logger.info("成功为\(pet.name)创建体重目标: \(targetWeight) \(unit.rawValue)")
        } catch {
            logger.error("创建体重目标时出错: \(error.localizedDescription)")
        }
    }
    
    /// 将宠物当前的所有体重目标设为非活跃
    private static func deactivateCurrentWeightGoals(pet: Pet, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WeightGoal>(
            predicate: #Predicate<WeightGoal> { goal in
                goal.pet.id == pet.id && goal.isActive == true
            }
        )
        
        do {
            let activeGoals = try modelContext.fetch(descriptor)
            for goal in activeGoals {
                goal.isActive = false
                goal.updatedAt = Date()
            }
            
            try modelContext.save()
            logger.info("已将\(pet.name)的\(activeGoals.count)个活跃体重目标设为非活跃")
        } catch {
            logger.error("更新体重目标状态时出错: \(error.localizedDescription)")
        }
    }
    
    /// 获取宠物的体重统计数据（用于图表显示）
    static func getWeightChartData(for pet: Pet, period: Int = 180, modelContext: ModelContext) -> [Weight] {
        // 默认获取最近6个月的数据
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -period, to: Date()) else {
            return []
        }
        
        let descriptor = FetchDescriptor<Weight>(
            predicate: #Predicate<Weight> { weight in
                weight.pet.id == pet.id && weight.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .ascending)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("获取体重图表数据时出错: \(error.localizedDescription)")
            return []
        }
    }
} 