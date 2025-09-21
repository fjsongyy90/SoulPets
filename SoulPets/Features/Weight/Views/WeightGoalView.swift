import SwiftUI
import SwiftData
import OSLog

/// 体重目标设置视图
struct WeightGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "WeightGoalView")
    
    let pet: Pet?
    
    @State private var targetWeight: String = ""
    @State private var selectedUnit: WeightUnit = .kg
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var showingValidationError = false
    @State private var showingCancelAlert = false
    @State private var errorMessage = ""
    @State private var existingGoal: WeightGoal?
    
    // 键盘工具栏相关状态
    @FocusState private var isTargetWeightFieldFocused: Bool
    
    // 使用统一的颜色定义
    
    /// 是否为编辑模式
    private var isEditMode: Bool {
        existingGoal != nil
    }
    
    /// 标题文本
    private var titleText: String {
        isEditMode ? String(localized: "Edit Weight Goal") : String(localized: "Set Weight Goal")
    }
    
    /// 保存按钮文本
    private var saveButtonText: String {
        isEditMode ? String(localized: "Update Goal") : String(localized: "Set Goal")
    }
    
    /// 表单是否有效
    private var isFormValid: Bool {
        guard let _ = pet,
              let targetWeightDouble = Double(targetWeight),
              targetWeightDouble > 0,
              targetWeightDouble < 1000,
              targetDate > Date() else {
            return false
        }
        return true
    }
    
    /// 当前体重（如果存在）
    private var currentWeight: Weight? {
        guard let pet = pet else { return nil }
        return WeightService.getLatestWeight(for: pet, modelContext: modelContext)
    }
    
    init(pet: Pet?) {
        self.pet = pet
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 宠物信息卡片
                        if let pet = pet {
                            petInfoCard(pet)
                        }
                        
                        // 当前体重信息
                        if let current = currentWeight {
                            currentWeightCard(current)
                        }
                        
                        // 目标体重输入
                        targetWeightForm
                        
                        // 目标日期选择
                        targetDateCard
                        
                        // 取消目标按钮（仅编辑模式）
                        if isEditMode {
                            cancelGoalButton
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // 🔧 浮动Done按钮（当键盘激活时显示）
                if isTargetWeightFieldFocused {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button("Done") {
                                logger.info("🔧 WeightGoal浮动Done按钮被点击")
                                logger.info("🔧 当前焦点状态 - TargetWeight: \(isTargetWeightFieldFocused)")
                                
                                // 关闭键盘
                                isTargetWeightFieldFocused = false
                                
                                // 备用方法：使用 UIApplication 方式关闭键盘
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                
                                logger.info("🔧 键盘关闭操作已执行")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.appAccent)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .onAppear {
                                logger.info("🔍 WeightGoal浮动Done按钮已显示")
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: isTargetWeightFieldFocused)
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.appAccent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonText) {
                        saveGoal()
                    }
                    .foregroundColor(isFormValid ? .appAccent : .appTextSecondary)
                    .disabled(!isFormValid)
                }
                
                // 🔧 键盘工具栏完成按钮
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        logger.info("🔧 WeightGoal键盘工具栏完成按钮被点击")
                        logger.info("🔧 当前焦点状态 - TargetWeight: \(isTargetWeightFieldFocused)")
                        
                        // 关闭键盘
                        isTargetWeightFieldFocused = false
                        
                        // 备用方法：使用 UIApplication 方式关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        logger.info("🔧 键盘关闭操作已执行")
                    }
                    .foregroundColor(.appAccent)
                    .onAppear {
                        logger.info("🔧 WeightGoal Done按钮已创建")
                    }
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
            .customConfirmAlert(
                title: String(localized: "Cancel Weight Goal"),
                message: String(localized: "This will cancel your current weight goal. This action cannot be undone."),
                isPresented: $showingCancelAlert,
                confirmTitle: String(localized: "Cancel Goal"),
                confirmAction: {
                    cancelExistingGoal()
                },
                isDestructive: true
            )
            .onAppear {
                logger.info("📱 WeightGoalView onAppear - 键盘工具栏应该已加载")
                setupInitialValues()
            }
            .onChange(of: isTargetWeightFieldFocused) { oldValue, newValue in
                logger.info("🎯 WeightGoal TargetWeight焦点状态变化: \(oldValue) -> \(newValue)")
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
                    .foregroundColor(.appTextPrimary)
                
                Text(pet.breed)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 当前体重卡片
    private func currentWeightCard(_ weight: Weight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Current Weight"))
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weight.formattedWeight())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(weight.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "scalemass")
                    .font(.title2)
                    .foregroundColor(.appAccent)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 目标体重输入表单
    private var targetWeightForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Target Weight"))
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            
            HStack(spacing: 12) {
                // 目标体重输入框
                TextField(String(localized: "Enter target weight"), text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .focused($isTargetWeightFieldFocused)
                    .onTapGesture {
                        logger.info("🎯 WeightGoal TargetWeight TextField被点击，设置焦点")
                        isTargetWeightFieldFocused = true
                    }
                
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
            
            // 目标类型提示
            if let current = currentWeight,
               let targetValue = Double(targetWeight),
               targetValue > 0 {
                let currentInUnit = selectedUnit == .kg ? current.weightInKg : current.weightInLbs()
                let goalType = targetValue < currentInUnit ? 
                    String(localized: "Weight Loss Goal") : 
                    String(localized: "Weight Gain Goal")
                
                HStack {
                    Image(systemName: targetValue < currentInUnit ? "arrow.down" : "arrow.up")
                        .foregroundColor(targetValue < currentInUnit ? .appSuccess : .appWarning)
                    Text(goalType)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            
            // 验证提示
            if !targetWeight.isEmpty && !isFormValid {
                Text(String(localized: "Please enter a valid target weight"))
                    .font(.caption)
                    .foregroundColor(.appError)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 目标日期卡片
    private var targetDateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Target Date"))
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            
            DatePicker(
                String(localized: "Target Date"),
                selection: $targetDate,
                in: Date()...,
                displayedComponents: [.date]
            )
            .datePickerStyle(CompactDatePickerStyle())
            .accentColor(Color.appAccent)
            
            // 天数提示
            let daysUntilTarget = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
            if daysUntilTarget > 0 {
                Text(String(format: String(localized: "%d days from now"), daysUntilTarget))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 取消目标按钮
    private var cancelGoalButton: some View {
        Button {
            showingCancelAlert = true
        } label: {
            Text(String(localized: "Cancel Current Goal"))
                .fontWeight(.semibold)
                .foregroundColor(.appError)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appError.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - 方法
    
    /// 设置初始值
    private func setupInitialValues() {
        logger.info("🔧 设置体重目标页面初始值")
        guard let pet = pet else { 
            logger.error("❌ 宠物为空，无法设置初始值")
            return 
        }
        
        logger.info("🐾 为宠物 \(pet.name) 设置初始值")
        
        // 设置单位偏好
        selectedUnit = pet.weightUnitPreference
        logger.info("📏 设置单位偏好: \(selectedUnit.rawValue)")
        
        // 查找现有的活跃目标
        existingGoal = WeightService.getActiveWeightGoal(for: pet, modelContext: modelContext)
        
        if let goal = existingGoal {
            // 编辑模式：使用现有目标数据
            logger.info("✏️ 编辑模式: 找到现有目标")
            targetWeight = String(format: "%.1f", goal.targetWeight)
            selectedUnit = goal.unit
            targetDate = goal.targetDate
            logger.info("📝 加载现有目标数据: 体重=\(targetWeight), 单位=\(selectedUnit.rawValue), 日期=\(targetDate)")
        } else {
            // 新建模式：使用默认值
            logger.info("➕ 新建模式: 使用默认值")
            targetWeight = ""
            targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            logger.info("📝 设置默认值: 空体重, 日期=\(targetDate)")
        }
    }
    
    /// 保存目标
    private func saveGoal() {
        logger.info("💾 开始保存体重目标")
        
        guard let pet = pet else {
            logger.error("❌ 宠物信息缺失")
            showError(String(localized: "Pet information is missing"))
            return
        }
        
        logger.info("🐾 为宠物 \(pet.name) 保存目标")
        
        guard let targetWeightDouble = Double(targetWeight),
              targetWeightDouble > 0,
              targetWeightDouble < 1000 else {
            logger.error("❌ 无效的目标体重: \(targetWeight)")
            showError(String(localized: "Please enter a valid target weight"))
            return
        }
        
        guard targetDate > Date() else {
            logger.error("❌ 无效的目标日期: \(targetDate)")
            showError(String(localized: "Target date must be in the future"))
            return
        }
        
        logger.info("✅ 验证通过，准备保存: 体重=\(targetWeightDouble) \(selectedUnit.rawValue), 日期=\(targetDate)")
        
        // 创建新目标（会自动取消现有目标）
        WeightService.createWeightGoal(
            pet: pet,
            targetWeight: targetWeightDouble,
            unit: selectedUnit,
            targetDate: targetDate,
            modelContext: modelContext
        )
        
        // 确保数据保存
        do {
            try modelContext.save()
            logger.info("✅ 模型上下文保存成功")
        } catch {
            logger.error("❌ 模型上下文保存失败: \(error.localizedDescription)")
            showError(String(localized: "Failed to save goal: ") + error.localizedDescription)
            return
        }
        
        logger.info("🎉 体重目标保存完成，即将关闭页面")
        dismiss()
    }
    
    /// 取消现有目标
    private func cancelExistingGoal() {
        guard let goal = existingGoal else { return }
        
        goal.isActive = false
        goal.updatedAt = Date()
        
        // 确保数据保存
        do {
            try modelContext.save()
        } catch {
            showError(String(localized: "Failed to cancel goal: ") + error.localizedDescription)
            return
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
    let container = try! ModelContainer(for: Pet.self, Weight.self, WeightGoal.self)
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
    
    return WeightGoalView(pet: samplePet)
        .modelContainer(container)
} 