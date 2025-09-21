import SwiftUI
import SwiftData
import OSLog

/// 添加/编辑体重记录视图
struct AddEditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pet: Pet?
    let weightToEdit: Weight?
    
    @State private var weightValue: String = ""
    @FocusState private var weightFieldFocused: Bool
    @State private var selectedUnit: WeightUnit = .kg
    @State private var selectedDate: Date = Date()
    @State private var showingValidationError = false
    @State private var errorMessage = ""
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AddEditWeightView")
    
    // 移除硬编码颜色定义，使用统一的颜色系统
    
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
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 宠物信息卡片
                        if let pet = pet {
                            petInfoCard(pet)
                        }
                        
                        // 体重输入表单
                        weightInputForm
                        
                        // 日期选择
                        dateSelectionCard
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                
                // 🔧 浮动Done按钮（当键盘激活时显示）
                if weightFieldFocused {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button("Done") {
                                logger.info("🔧 AddEditWeight浮动Done按钮被点击")
                                logger.info("🔧 当前焦点状态 - Weight: \(weightFieldFocused)")
                                
                                // 关闭键盘
                                weightFieldFocused = false
                                
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
                                logger.info("🔍 AddEditWeight浮动Done按钮已显示")
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: weightFieldFocused)
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(Color.appAccent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonText) {
                        saveWeight()
                    }
                    .foregroundColor(isFormValid ? Color.appAccent : Color.appTextSecondary)
                    .disabled(!isFormValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer() // 将按钮推到右侧
                    
                    Button(String(localized: "Done")) {
                        logger.info("🔧 AddEditWeight键盘工具栏完成按钮被点击")
                        logger.info("🔧 当前焦点状态 - Weight: \(weightFieldFocused)")
                        
                        weightFieldFocused = false // 点击“完成”按钮，取消焦点
                        
                        // 备用方法：使用 UIApplication 方式关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        logger.info("🔧 键盘关闭操作已执行")
                    }
                    .foregroundColor(Color.appAccent)
                    .onAppear {
                        logger.info("🔧 AddEditWeight Done按钮已创建")
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
            .onAppear {
                logger.info("📱 AddEditWeightView onAppear - 键盘工具栏应该已加载")
                setupInitialValues()
                // 确保视图加载完成后再聚焦，触发键盘弹起
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    weightFieldFocused = true
                }
            }
            .onChange(of: weightFieldFocused) { oldValue, newValue in
                logger.info("⚖️ AddEditWeight Weight焦点状态变化: \(oldValue) -> \(newValue)")
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
                    .foregroundColor(Color.appTextPrimary)
                
                Text(pet.breed)
                    .font(.caption)
                    .foregroundColor(Color.appTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// 体重输入表单
    private var weightInputForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(Color.appAccent)
                    .font(.title3)
                
                Text(String(localized: "Weight"))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // 体重输入框 - 视觉焦点
                TextField(String(localized: "Enter weight"), text: $weightValue)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .medium, design: .rounded)) // 大号字体作为视觉焦点
                    .multilineTextAlignment(.center)
                    .focused($weightFieldFocused)
                    .padding(.vertical, 20)
                    .background(Color.appBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                !weightValue.isEmpty && !isFormValid ? Color.appError : Color.appAccent.opacity(0.3), 
                                lineWidth: 2
                            )
                    )
                    .cornerRadius(12)
                    .onTapGesture {
                        logger.info("⚖️ AddEditWeight Weight TextField被点击，设置焦点")
                        weightFieldFocused = true
                    }
                
                // 自定义单位选择器
                customUnitSelector
            }
            
            // 验证提示
            if !weightValue.isEmpty && !isFormValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(Color.appError)
                        .font(.caption)
                    
                    Text(String(localized: "Please enter a valid weight between 0.1 and 999.9"))
                        .font(.caption)
                        .foregroundColor(Color.appError)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// 自定义单位选择器 - 柔和胶囊按钮
    private var customUnitSelector: some View {
        HStack(spacing: 0) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedUnit = unit
                    }
                }) {
                    Text(unit.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedUnit == unit ? Color.cardBackground : Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedUnit == unit ? 
                            Color.appAccent : 
                            Color.appBackground
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.appBackground)
        .cornerRadius(25) // 胶囊形状
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.appAccent.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// 精美的日期选择卡片
    private var dateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题和图标
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color.appAccent)
                    .font(.title3)
                
                Text(String(localized: "Date"))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
            }
        
            // 简化的日期选择器 - 作为核心元素
            DatePicker(
                String(localized: "Weigh Date"),
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(CompactDatePickerStyle())
            .accentColor(Color.appAccent)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color.appTextPrimary)
            // --- 新增代码开始 ---
            .contentShape(Rectangle()) // 确保整个区域都可以响应点击
            .onTapGesture {
                // 在点击日期选择器时，明确地取消文本框的焦点
                weightFieldFocused = false
            }
            // --- 新增代码结束 ---
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// 格式化选择的日期
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: selectedDate)
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
