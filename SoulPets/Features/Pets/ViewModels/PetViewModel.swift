import Foundation
import SwiftData
import SwiftUI
import os.log

/// 宠物管理视图模型
class PetViewModel: ObservableObject {
    // MARK: - 属性
    private var modelContext: ModelContext
    private let logger = Logger(subsystem: "com.yourapp.SoulPets", category: "PetViewModel")
    
    // 新宠物表单数据
    @Published var name: String = ""
    @Published var petType: PetType = .cat
    @Published var breed: String = ""
    @Published var avatar: UIImage?
    @Published var gender: Gender = .male
    @Published var isNeutered: Bool = false
    @Published var birthday: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @Published var adoptionDay: Date = Date()
    @Published var microchipID: String = ""
    @Published var insurancePolicyNo: String = ""
    @Published var weightUnitPreference: WeightUnit = .kg
    @Published var initialWeight: String = ""
    
    // 表单验证
    @Published var nameError: String?
    @Published var formIsValid: Bool = false
    
    // 添加宠物的流程控制
    @Published var currentStep: AddPetStep = .selectType
    
    // MARK: - 初始化
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        validateForm()
    }
    
    // 更新ModelContext
    func updateModelContext(_ newModelContext: ModelContext) {
        self.modelContext = newModelContext
    }
    
    // MARK: - 表单验证
    func validateForm() {
        // 验证名称
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Please enter your pet's name"
            formIsValid = false
            return
        } else {
            nameError = nil
        }
        
        // 验证其他必填项
        formIsValid = true
    }
    
    // MARK: - 数据操作
    /// 保存新宠物
    func savePet() throws -> Pet {
        do {
            logger.info("开始创建宠物档案: \(self.name)")
            
            // 将UIImage转换为Data
            let avatarData = avatar?.jpegData(compressionQuality: 0.7)
            
            // 创建新宠物实例
            let pet = Pet(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                petType: petType,
                breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                avatar: avatarData,
                gender: gender,
                isNeutered: isNeutered,
                birthday: birthday,
                adoptionDay: adoptionDay,
                microchipID: microchipID,
                insurancePolicyNo: insurancePolicyNo,
                weightUnitPreference: weightUnitPreference
            )
            
            // 保存到数据库
            modelContext.insert(pet)
            
            // 如果提供了初始体重，创建体重记录
            if let weightValue = Double(initialWeight), weightValue > 0 {
                let weight = Weight(
                    date: Date(),
                    weightInKg: weightValue,
                    pet: pet
                )
                modelContext.insert(weight)
                logger.info("为宠物添加初始体重记录: \(weightValue) kg")
            }
            
            try modelContext.save()
            
            logger.info("成功创建宠物档案: \(pet.id.uuidString)")
            resetForm()
            return pet
        } catch {
            logger.error("保存宠物失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 更新现有宠物
    func updatePet(_ pet: Pet) throws {
        do {
            logger.info("开始更新宠物档案: \(pet.id.uuidString)")
            
            // 更新宠物信息
            pet.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            pet.petType = petType
            pet.breed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
            if let avatarData = avatar?.jpegData(compressionQuality: 0.7) {
                pet.avatar = avatarData
            }
            pet.gender = gender
            pet.isNeutered = isNeutered
            pet.birthday = birthday
            pet.adoptionDay = adoptionDay
            pet.microchipID = microchipID
            pet.insurancePolicyNo = insurancePolicyNo
            pet.weightUnitPreference = weightUnitPreference
            pet.updatedAt = Date()
            
            try modelContext.save()
            logger.info("成功更新宠物档案")
        } catch {
            logger.error("更新宠物失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 删除宠物
    func deletePet(_ pet: Pet) throws {
        do {
            logger.info("开始删除宠物档案: \(pet.id.uuidString)")
            modelContext.delete(pet)
            try modelContext.save()
            logger.info("成功删除宠物档案")
        } catch {
            logger.error("删除宠物失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 加载宠物数据到表单
    func loadPet(_ pet: Pet) {
        name = pet.name
        petType = pet.petType
        breed = pet.breed
        if let avatarData = pet.avatar {
            avatar = UIImage(data: avatarData)
        } else {
            avatar = nil
        }
        gender = pet.gender
        isNeutered = pet.isNeutered
        birthday = pet.birthday
        adoptionDay = pet.adoptionDay ?? Date()
        microchipID = pet.microchipID
        insurancePolicyNo = pet.insurancePolicyNo
        weightUnitPreference = pet.weightUnitPreference
    }
    
    /// 重置表单
    func resetForm() {
        name = ""
        petType = .cat
        breed = ""
        avatar = nil
        gender = .male
        isNeutered = false
        birthday = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        adoptionDay = Date()
        microchipID = ""
        insurancePolicyNo = ""
        weightUnitPreference = .kg
        initialWeight = ""
        currentStep = .selectType
    }
    
    // MARK: - 流程控制
    func moveToNextStep() {
        switch currentStep {
        case .selectType:
            currentStep = .basicInfo
        case .basicInfo:
            validateForm()
            if formIsValid {
                currentStep = .importantDates
            }
        case .importantDates:
            // 最后一步，不需要操作
            break
        }
    }
    
    func moveToPreviousStep() {
        switch currentStep {
        case .selectType:
            // 第一步，不需要操作
            break
        case .basicInfo:
            currentStep = .selectType
        case .importantDates:
            currentStep = .basicInfo
        }
    }
}

// MARK: - 辅助类型
/// 添加宠物的步骤
enum AddPetStep {
    case selectType
    case basicInfo
    case importantDates
} 