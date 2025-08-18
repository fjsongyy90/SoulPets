import Foundation
import SwiftData

/// 体重记录模型
@Model
final class Weight {
    // MARK: - 属性
    var id: UUID
    var date: Date
    var weightInKg: Double
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 关系
    @Relationship(deleteRule: .nullify)
    var pet: Pet?
    
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
        // 验证体重值的有效性
        if weightInKg.isFinite && weightInKg > 0 && weightInKg < 1000 {
            self.weightInKg = weightInKg
        } else {
            // 如果体重值无效，使用默认值
            self.weightInKg = 1.0
        }
        self.pet = pet
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - 辅助方法
    
    /// 转换为磅
    func weightInLbs() -> Double {
        let lbsValue = weightInKg * 2.20462
        return lbsValue.isFinite ? lbsValue : 0.0
    }
    
    /// 根据用户偏好获取格式化的体重字符串
    func formattedWeight(unit: WeightUnit? = nil) -> String {
        let preferredUnit = unit ?? pet?.weightUnitPreference ?? .kg
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let weightValue: Double
        let unitString: String
        
        switch preferredUnit {
        case .kg:
            weightValue = weightInKg
            unitString = "kg"
        case .lbs:
            weightValue = weightInLbs()
            unitString = "lbs"
        }
        
        // 确保体重值是有效的
        guard weightValue.isFinite && weightValue > 0 else {
            return "-- \(unitString)"
        }
        
        if let formattedValue = formatter.string(from: NSNumber(value: weightValue)) {
            return "\(formattedValue) \(unitString)"
        } else {
            return "\(String(format: "%.1f", weightValue)) \(unitString)"
        }
    }
} 