import Foundation
import SwiftData
import SwiftUI
import os.log

/// 宠物管理视图模型
class PetViewModel: ObservableObject {
    // MARK: - 属性
    private var modelContext: ModelContext
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "PetViewModel")
    private var validationWorkItem: DispatchWorkItem?
    
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
    @Published var personality: String?
    @Published var story: String?
    
    // 表单验证
    @Published var nameError: String?
    @Published var formIsValid: Bool = false
    
    // 添加宠物的流程控制
    @Published var currentStep: AddPetStep = .selectType
    
    // 防抖动计时器
    private var debounceTimer: Timer?
    
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
    
    /// 防抖动验证表单
    func debouncedValidateForm() {
        // 取消之前的定时器
        debounceTimer?.invalidate()
        
        // 创建新的定时器，延迟执行验证
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.validateForm()
        }
    }
    
    func validateForm() {
        // 取消之前的验证任务
        validationWorkItem?.cancel()
        
        // 创建新的验证任务
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // 验证名称
            let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = !trimmedName.isEmpty
            
            // 只有当验证结果改变时才更新UI
            DispatchQueue.main.async {
                let oldError = self.nameError
                let oldValid = self.formIsValid
                
                self.nameError = isValid ? nil : "Please enter your pet's name"
                self.formIsValid = isValid
                
                // 减少不必要的UI更新
                if oldError != self.nameError || oldValid != self.formIsValid {
                    // 状态确实改变了，UI会自动更新
                }
            }
        }
        
        // 保存并延迟执行验证任务
        validationWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
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
                weightUnitPreference: self.weightUnitPreference,
                personality: personality?.trimmingCharacters(in: .whitespacesAndNewlines),
                story: story?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // 保存到数据库
            modelContext.insert(pet)
            
            // 如果提供了初始体重，创建体重记录
            if let weightValue = Double(initialWeight), weightValue > 0 {
                let weight = Weight(
                    date: Date(),
                    weightInKg: convertToKilograms(weightValue),
                    pet: pet
                )
                modelContext.insert(weight)
                logger.info("为宠物添加初始体重记录: \(weightValue) \(self.weightUnitPreference.rawValue)")
            }
            
            try modelContext.save()
            
            logger.info("成功创建宠物档案: \(pet.id.uuidString)")
            // 移除自动重置表单，让调用者决定何时重置
            // resetForm()
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
            pet.weightUnitPreference = self.weightUnitPreference
            pet.personality = personality?.trimmingCharacters(in: .whitespacesAndNewlines)
            pet.story = story?.trimmingCharacters(in: .whitespacesAndNewlines)
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
            
            // 使用级联删除方法
            PetService.deletePet(pet: pet, modelContext: modelContext)
            
            logger.info("成功删除宠物档案")
        } catch {
            logger.error("删除宠物失败，错误: \(error.localizedDescription)")
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
        self.weightUnitPreference = pet.weightUnitPreference
        personality = pet.personality
        story = pet.story
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
        self.weightUnitPreference = .kg
        initialWeight = ""
        personality = nil
        story = nil
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
    
    // MARK: - 辅助方法
    
    /// 将体重值转换为公斤
    private func convertToKilograms(_ value: Double) -> Double {
        switch self.weightUnitPreference {
        case .kg:
            return value
        case .lbs:
            return value * 0.453592 // 磅转公斤的转换系数
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