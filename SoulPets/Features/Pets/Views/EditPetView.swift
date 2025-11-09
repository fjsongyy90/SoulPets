import SwiftUI
import SwiftData
import os.log

/// 编辑宠物视图
struct EditPetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "EditPetView")
    let pet: Pet
    @StateObject private var viewModel: PetViewModel
    
    // 键盘工具栏相关状态
    @FocusState private var focusedField: EditPetField?
    
    enum EditPetField {
        case name, breed, personality, story, microchip, insurance
    }
    
    init(pet: Pet) {
        self.pet = pet
        // 创建一个临时的ViewModel，使用一个空的ModelContext
        // 我们将在onAppear中更新为环境中的modelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Pet.self, configurations: config)
        _viewModel = StateObject(wrappedValue: PetViewModel(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(red: 0.98, green: 0.97, blue: 0.94).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        basicInfoCard
                        importantDatesCard  
                        healthInfoCard
                        personalityStoryCard
                        privacyText
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(String(localized: "Edit Pet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.60, green: 0.35, blue: 0.15))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveChanges()
                    }
                    .disabled(!viewModel.formIsValid)
                    .foregroundColor(viewModel.formIsValid ? Color(red: 0.60, green: 0.35, blue: 0.15) : .gray)
                }
            }
            .toolbar {
                // 🔧 键盘工具栏完成按钮（仅在有焦点时显示）
                if focusedField != nil {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(String(localized: "Done")) {
                            logger.info("🔧 EditPet键盘工具栏完成按钮被点击")
                            logger.info("🔧 当前焦点状态: \(String(describing: focusedField))")
                            
                            // 关闭键盘
                            focusedField = nil
                            
                            // 备用方法：使用 UIApplication 方式关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            logger.info("🔧 键盘关闭操作已执行")
                        }
                        .foregroundColor(Color(red: 0.60, green: 0.35, blue: 0.15))
                        .onAppear {
                            logger.info("🔧 EditPet Done按钮已创建")
                        }
                    }
                }
            }
            .onChange(of: focusedField) { oldValue, newValue in
                logger.info("📝 EditPet 焦点状态变化: \(String(describing: oldValue)) -> \(String(describing: newValue))")
            }
            .onAppear {
                logger.info("📱 EditPetView onAppear - 键盘工具栏应该已加载")
                // 在视图出现时，使用环境中的modelContext
                viewModel.updateModelContext(modelContext)
                // 加载宠物数据到表单
                viewModel.loadPet(pet)
            }
        }
    }
    
    // MARK: - 子视图组件
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Pet Avatar"))
                .font(.appHeadline)
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            
            CircleImagePicker(image: $viewModel.avatar, size: 120)
        }
        .padding(.vertical, 20)
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Basic Information"))
                .font(.appTitle3)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            
            nameField
            petTypeField
            breedField
            genderField
            neuteredField
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Name"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            TextField(String(localized: "Name"), text: $viewModel.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .name)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            logger.info("📝 EditPet Name TextField simultaneousGesture 触发")
                        }
                )
                .onChange(of: viewModel.name) { _, _ in
                    viewModel.validateForm()
                }
            
            if let error = viewModel.nameError {
                Text(LocalizedStringKey(error))
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var petTypeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Pet Type"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            // v1.1.0: 使用 Menu 样式替代 SegmentedPickerStyle，适配10种宠物类型
            Picker(String(localized: "Pet Type"), selection: $viewModel.petType) {
                ForEach(PetType.allCases, id: \.self) { type in
                    HStack {
                        Image(type.defaultImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(LocalizedStringKey(type.rawValue))
                    }
                    .tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var breedField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Breed / Color"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            TextField(String(localized: "Breed / Color"), text: $viewModel.breed)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .breed)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            logger.info("📝 EditPet Breed TextField simultaneousGesture 触发")
                        }
                )
        }
    }
    
    private var genderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Gender"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            Picker(String(localized: "Gender"), selection: $viewModel.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(LocalizedStringKey(gender.rawValue)).tag(gender)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var neuteredField: some View {
        HStack {
            Text(String(localized: "Neutered / Spayed"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            Spacer()
            
            Toggle("", isOn: $viewModel.isNeutered)
                .labelsHidden()
                .tint(Color(red: 0.60, green: 0.35, blue: 0.15))
        }
    }
    
    private var importantDatesCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Important Dates"))
                .font(.appTitle3)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            
            birthdayField
            adoptionDayField
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var birthdayField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Birthday"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            HStack {
                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .accentColor(Color(red: 0.60, green: 0.35, blue: 0.15))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var adoptionDayField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Adoption / Gotcha Day"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            HStack {
                DatePicker(
                    "",
                    selection: $viewModel.adoptionDay,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .accentColor(Color(red: 0.60, green: 0.35, blue: 0.15))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var healthInfoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Health Information"))
                .font(.appTitle3)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            
            weightUnitField
            microchipField
            insuranceField
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // 新增：性格和故事卡片
    private var personalityStoryCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Personality & Story"))
                .font(.appTitle3)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            
            personalityField
            storyField
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // 性格输入框 - 单行
    private var personalityField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Personality"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            TextField(String(localized: "Describe your pet's personality"), text: Binding(
                get: { viewModel.personality ?? "" },
                set: { viewModel.personality = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($focusedField, equals: .personality)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        logger.info("📝 EditPet Personality TextField simultaneousGesture 触发")
                    }
            )
        }
    }
    
    // 故事输入框 - 多行 (已添加占位符功能)
    private var storyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Story with Owner"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            // 👇 主要修改在这里：使用 ZStack 来实现占位符
            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { viewModel.story ?? "" },
                    set: { viewModel.story = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )
                .cornerRadius(8)
                .focused($focusedField, equals: .story)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            logger.info("📝 EditPet Story TextEditor simultaneousGesture 触发")
                        }
                )
                
                // 当内容为空时，显示这里的占位符文本
                if (viewModel.story ?? "").isEmpty {
                    // 👇 您可以在这里替换成您最喜欢的那句引导语
                    Text(String(localized: "Describe a special moment, a funny habit, or how you first met..."))
                        .font(.body) // 确保字体与TextEditor一致
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false) // 允许点击穿透，以便用户可以点击到下方的TextEditor
                }
            }
        }
    }
    
    private var weightUnitField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Weight Unit"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            Picker(String(localized: "Weight Unit"), selection: $viewModel.weightUnitPreference) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Text(LocalizedStringKey(unit.rawValue)).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var microchipField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Microchip ID (Optional)"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            TextField(String(localized: "Microchip ID (Optional)"), text: $viewModel.microchipID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .microchip)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            logger.info("📝 EditPet Microchip TextField simultaneousGesture 触发")
                        }
                )
        }
    }
    
    private var insuranceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Insurance Policy No. (Optional)"))
                .font(.appSubheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            TextField(String(localized: "Insurance Policy No. (Optional)"), text: $viewModel.insurancePolicyNo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .insurance)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            logger.info("📝 EditPet Insurance TextField simultaneousGesture 触发")
                        }
                )
        }
    }
    
    private var privacyText: some View {
        Text(String(localized: "Your pet's data never leaves your device."))
            .font(.appCaption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 20)
    }
    
    // 保存更改
    private func saveChanges() {
        do {
            try viewModel.updatePet(pet)
            logger.info("成功更新宠物信息: \(pet.name)")
            dismiss()
        } catch {
            logger.error("更新宠物信息时出错: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let pet = Pet(
        name: String(localized: "Whiskers"),
        petType: .cat,
        breed: String(localized: "Tabby"),
        gender: .male,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
        adoptionDay: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
        weightUnitPreference: .kg
    )
    container.mainContext.insert(pet)
    
    return EditPetView(pet: pet)
        .modelContainer(container)
} 
