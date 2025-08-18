import SwiftUI
import SwiftData

/// 添加/编辑体重记录视图
struct AddEditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pet: Pet?
    let weightToEdit: Weight?
    
    @State private var weightValue: String = ""
    @State private var selectedUnit: WeightUnit = .kg
    @State private var selectedDate: Date = Date()
    @State private var showingValidationError = false
    @State private var errorMessage = ""
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    private let cardColor = Color.white
    
    /// 是否为编辑模式
    private var isEditMode: Bool {
        weightToEdit != nil
    }
    
    /// 标题文本
    private var titleText: String {
        isEditMode ? String(localized: "Edit Weight") : String(localized: "Add Weight")
    }
    
    /// 保存按钮文本
    private var saveButtonText: String {
        isEditMode ? String(localized: "Update") : String(localized: "Save")
    }
    
    /// 表单是否有效
    private var isFormValid: Bool {
        guard let _ = pet,
              let weightDouble = Double(weightValue),
              weightDouble > 0,
              weightDouble < 1000 else {
            return false
        }
        return true
    }
    
    init(pet: Pet?, weightToEdit: Weight? = nil) {
        self.pet = pet
        self.weightToEdit = weightToEdit
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 宠物信息卡片
                        if let pet = pet {
                            petInfoCard(pet)
                        }
                        
                        // 体重输入表单
                        weightInputForm
                        
                        // 日期选择
                        dateSelectionCard
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonText) {
                        saveWeight()
                    }
                    .foregroundColor(isFormValid ? accentColor : labelColor)
                    .disabled(!isFormValid)
                }
            }
            .alert(
                String(localized: "Validation Error"),
                isPresented: $showingValidationError
            ) {
                Button(String(localized: "OK")) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 宠物信息卡片
    private func petInfoCard(_ pet: Pet) -> some View {
        HStack(spacing: 12) {
            // 宠物头像
            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Text(pet.breed)
                    .font(.caption)
                    .foregroundColor(labelColor)
            }
            
            Spacer()
        }
        .padding()
        .background(cardColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重输入表单
    private var weightInputForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Weight"))
                .font(.headline)
                .foregroundColor(textColor)
            
            HStack(spacing: 12) {
                // 体重输入框
                TextField(String(localized: "Enter weight"), text: $weightValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .colorScheme(.light) // 强制使用浅色模式
                    .background(Color.white) // 强制使用白色背景
                    .cornerRadius(8)
                
                // 单位选择器
                Picker(String(localized: "Unit"), selection: $selectedUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue)
                            .tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
            }
            
            // 验证提示
            if !weightValue.isEmpty && !isFormValid {
                Text(String(localized: "Please enter a valid weight between 0.1 and 999.9"))
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white) // 强制使用白色背景
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 日期选择卡片
    private var dateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Date"))
                .font(.headline)
                .foregroundColor(textColor)
            
            DatePicker(
                String(localized: "Weigh Date"),
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(CompactDatePickerStyle())
            .colorScheme(.light) // 强制使用浅色模式
            .accentColor(accentColor)
        }
        .padding()
        .background(Color.white) // 强制使用白色背景
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 方法
    
    /// 设置初始值
    private func setupInitialValues() {
        if let weight = weightToEdit {
            // 编辑模式：使用现有数据
            selectedUnit = pet?.weightUnitPreference ?? .kg
            selectedDate = weight.date
            
            // 根据单位显示体重值
            let displayValue = selectedUnit == .kg ? weight.weightInKg : weight.weightInLbs()
            weightValue = String(format: "%.1f", displayValue)
        } else {
            // 添加模式：使用默认值
            selectedUnit = pet?.weightUnitPreference ?? .kg
            selectedDate = Date()
            weightValue = ""
        }
    }
    
    /// 保存体重记录
    private func saveWeight() {
        guard let pet = pet else {
            showError(String(localized: "Pet information is missing"))
            return
        }
        
        guard let weightDouble = Double(weightValue),
              weightDouble > 0,
              weightDouble < 1000 else {
            showError(String(localized: "Please enter a valid weight"))
            return
        }
        
        if let existingWeight = weightToEdit {
            // 更新现有记录
            WeightService.updateWeight(
                weight: existingWeight,
                newWeightInUnit: weightDouble,
                unit: selectedUnit,
                newDate: selectedDate,
                modelContext: modelContext
            )
        } else {
            // 创建新记录
            WeightService.addWeight(
                pet: pet,
                weightInUnit: weightDouble,
                unit: selectedUnit,
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        dismiss()
    }
    
    /// 显示错误信息
    private func showError(_ message: String) {
        errorMessage = message
        showingValidationError = true
    }
}

#Preview {
    let container = try! ModelContainer(for: Pet.self, Weight.self)
    let context = container.mainContext
    
    let samplePet = Pet(
        name: "Fluffy",
        petType: .cat,
        breed: "Persian",
        gender: .female,
        isNeutered: true,
        birthday: Date(),
        adoptionDay: Date()
    )
    
    context.insert(samplePet)
    
    return AddEditWeightView(pet: samplePet)
        .modelContainer(container)
} 