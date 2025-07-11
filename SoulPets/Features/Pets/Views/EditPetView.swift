import SwiftUI
import SwiftData

/// 编辑宠物视图
struct EditPetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    @StateObject private var viewModel: PetViewModel
    
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
            Form {
                // 基本信息
                Section(header: Text(LocalizedStringKey("Basic Information"))) {
                    // 头像选择器
                    HStack {
                        Spacer()
                        CircleImagePicker(image: $viewModel.avatar, size: 120)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical)
                    
                    // 名字
                    TextField(LocalizedStringKey("Name"), text: $viewModel.name)
                        .onChange(of: viewModel.name) { _, _ in
                            viewModel.validateForm()
                        }
                    
                    if let error = viewModel.nameError {
                        Text(LocalizedStringKey(error))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // 宠物类型
                    Picker(LocalizedStringKey("Pet Type"), selection: $viewModel.petType) {
                        ForEach(PetType.allCases, id: \.self) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }
                    
                    // 品种/花色
                    TextField(LocalizedStringKey("Breed / Color"), text: $viewModel.breed)
                    
                    // 性别
                    Picker(LocalizedStringKey("Gender"), selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(LocalizedStringKey(gender.rawValue)).tag(gender)
                        }
                    }
                    
                    // 绝育状态
                    Toggle(LocalizedStringKey("Neutered / Spayed"), isOn: $viewModel.isNeutered)
                }
                
                // 重要日期
                Section(header: Text(LocalizedStringKey("Important Dates"))) {
                    // 生日
                    DatePicker(
                        LocalizedStringKey("Birthday"),
                        selection: $viewModel.birthday,
                        displayedComponents: .date
                    )
                    
                    // 领养日
                    DatePicker(
                        LocalizedStringKey("Adoption / Gotcha Day"),
                        selection: $viewModel.adoptionDay,
                        displayedComponents: .date
                    )
                }
                
                // 健康信息
                Section(header: Text(LocalizedStringKey("Health Information"))) {
                    // 体重单位
                    Picker(LocalizedStringKey("Weight Unit"), selection: $viewModel.weightUnitPreference) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    // 芯片ID
                    TextField(LocalizedStringKey("Microchip ID (Optional)"), text: $viewModel.microchipID)
                    
                    // 保险单号
                    TextField(LocalizedStringKey("Insurance Policy No. (Optional)"), text: $viewModel.insurancePolicyNo)
                }
            }
            .navigationTitle(LocalizedStringKey("Edit Pet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Save")) {
                        saveChanges()
                    }
                    .disabled(!viewModel.formIsValid)
                }
            }
            .onAppear {
                // 在视图出现时，使用环境中的modelContext
                viewModel.updateModelContext(modelContext)
                // 加载宠物数据到表单
                viewModel.loadPet(pet)
            }
        }
    }
    
    // 保存更改
    private func saveChanges() {
        do {
            try viewModel.updatePet(pet)
            dismiss()
        } catch {
            print("Error updating pet: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let pet = Pet(
        name: "Whiskers",
        petType: .cat,
        breed: "Tabby",
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