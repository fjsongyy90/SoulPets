import Foundation
import SwiftData

@Model
final class WeightGoal {
    // MARK: - 属性
    var id: UUID
    var targetWeight: Double
    var unit: WeightUnit
    var startDate: Date
    var targetDate: Date
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship
    var pet: Pet
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        targetWeight: Double,
        unit: WeightUnit,
        startDate: Date,
        targetDate: Date,
        isActive: Bool = true,
        pet: Pet,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.targetWeight = targetWeight
        self.unit = unit
        self.startDate = startDate
        self.targetDate = targetDate
        self.isActive = isActive
        self.pet = pet
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 辅助方法
extension WeightGoal {
    /// 目标体重是否为减肥
    var isWeightLoss: Bool {
        guard let latestWeight = pet.weights?.sorted(by: { $0.date > $1.date }).first else {
            return false
        }
        
        let latestWeightValue = unit == .kg ? latestWeight.weightInKg : latestWeight.weightInLbs()
        return targetWeight < latestWeightValue
    }
    
    /// 获取标准化的体重值（统一单位）
    var normalizedTargetWeight: Double {
        return unit == .kg ? targetWeight : targetWeight / 2.20462
    }
    
    /// 计算目标进度（0-100%）
    func calculateProgress() -> Double? {
        guard let latestWeight = pet.weights?.sorted(by: { $0.date > $1.date }).first else {
            return nil
        }
        
        // 获取初始体重（目标开始时的体重）
        guard let initialWeight = pet.weights?.filter({ $0.date <= startDate })
            .sorted(by: { $0.date > $1.date })
            .first else {
            return nil
        }
        
        // 将所有体重统一为kg进行计算
        let initialKg = initialWeight.weightInKg
        let currentKg = latestWeight.weightInKg
        let targetKg = normalizedTargetWeight
        
        // 计算总体重差和已完成差
        let totalDifference = abs(targetKg - initialKg)
        let achievedDifference = abs(currentKg - initialKg)
        
        // 避免除以零
        if totalDifference == 0 { return 100.0 }
        
        // 如果目标是减肥且当前体重高于初始体重，或目标是增重且当前体重低于初始体重，进度为0
        if (isWeightLoss && currentKg > initialKg) || (!isWeightLoss && currentKg < initialKg) {
            return 0.0
        }
        
        // 进度百分比，上限100%
        let progress = min((achievedDifference / totalDifference) * 100, 100.0)
        return progress
    }
    
    /// 格式化目标为易读文本
    var formattedGoal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        let formattedWeight = formatter.string(from: NSNumber(value: targetWeight)) ?? "\(targetWeight)"
        
        let type = isWeightLoss ? "减至" : "增至"
        return "\(type) \(formattedWeight) \(unit.rawValue)"
    }
    
    /// 剩余天数
    var remainingDays: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
} 