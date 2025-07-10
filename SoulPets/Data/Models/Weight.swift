import Foundation
import SwiftData

@Model
final class Weight {
    // MARK: - 属性
    var id: UUID
    var date: Date
    var weightInKg: Double
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship
    var pet: Pet
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        date: Date,
        weightInKg: Double,
        pet: Pet,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.weightInKg = weightInKg
        self.pet = pet
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 辅助方法
extension Weight {
    /// 将kg转换为lbs
    func weightInLbs() -> Double {
        return weightInKg * 2.20462
    }
    
    /// 根据宠物首选单位显示体重
    func formattedWeight() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        if pet.weightUnitPreference == .kg {
            guard let formattedValue = formatter.string(from: NSNumber(value: weightInKg)) else {
                return "\(weightInKg) kg"
            }
            return "\(formattedValue) kg"
        } else {
            let lbs = weightInLbs()
            guard let formattedValue = formatter.string(from: NSNumber(value: lbs)) else {
                return "\(lbs) lbs"
            }
            return "\(formattedValue) lbs"
        }
    }
} 