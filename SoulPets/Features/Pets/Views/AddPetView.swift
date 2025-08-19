import SwiftUI
import SwiftData

/// 添加宠物的主视图
struct AddPetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PetViewModel
    @State private var showingBirthdayReminderAlert = false
    @State private var shouldCreateBirthdayReminder = false
    @State private var savedPet: Pet? // 保存已创建的宠物引用
    
    // 背景和强调色
    private let backgroundColor = Color(red: 0.99, green: 0.98, blue: 0.94)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: PetViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 当前步骤内容
                    ScrollView {
                        switch viewModel.currentStep {
                        case .selectType:
                            PetTypeSelectionView(selectedType: $viewModel.petType)
                                .padding(.top, 20)
                        case .basicInfo:
                            PetBasicInfoView(viewModel: viewModel)
                        case .importantDates:
                            PetImportantDatesView(viewModel: viewModel, onSaveAndFinish: saveAndFinish)
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                    
                    Spacer()
                    
                    // 导航按钮 - 仅用于第一步
                    if viewModel.currentStep == .selectType {
                        VStack {
                            Button(action: {
                                viewModel.moveToNextStep()
                            }) {
                                Text(LocalizedStringKey("Next"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(accentColor)
                                    )
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                            .padding(.top, 10)
                        }
                        .background(backgroundColor)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("SoulPets"))
                        .font(.appHeadline)
                        .foregroundColor(accentColor)
                }
                
                if viewModel.currentStep != .selectType {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.moveToPreviousStep()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text(LocalizedStringKey("Cancel"))
                            .foregroundColor(accentColor)
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert(LocalizedStringKey("Add Birthday Reminder?"), isPresented: $showingBirthdayReminderAlert) {
                Button(LocalizedStringKey("No"), role: .cancel) {
                    finishAndDismiss()
                }
                Button(LocalizedStringKey("Yes")) {
                    shouldCreateBirthdayReminder = true
                    finishAndDismiss()
                }
            } message: {
                Text(LocalizedStringKey("Would you like to create an annual reminder for \(viewModel.name)'s birthday?"))
                    .foregroundColor(textColor)
            }
        }
    }
    
    // 保存宠物并显示生日提醒询问
    private func saveAndFinish() {
        do {
            savedPet = try viewModel.savePet()
            // 不要重置currentStep，避免UI跳回第一步
            showingBirthdayReminderAlert = true
        } catch {
            print("Error saving pet: \(error.localizedDescription)")
        }
    }
    
    // 完成并关闭视图
    private func finishAndDismiss() {
        if shouldCreateBirthdayReminder {
            // 创建生日提醒的代码
            createBirthdayReminder()
        }
        // 在关闭前重置表单
        viewModel.resetForm()
        dismiss()
    }
    
    // 创建生日提醒
    private func createBirthdayReminder() {
        guard let pet = savedPet else {
            print("❌ 找不到已保存的宠物")
            return
        }
        
        print("🎂 开始为\(pet.name)创建生日提醒")
        print("📅 宠物生日: \(pet.birthday)")
        
        do {
            PetService.createBirthdayReminder(pet: pet, modelContext: modelContext)
            print("✅ 成功调用PetService.createBirthdayReminder")
            
            // 验证提醒是否已创建
            let reminderDescriptor = FetchDescriptor<Reminder>()
            let reminders = try modelContext.fetch(reminderDescriptor)
            print("📝 当前数据库中共有 \(reminders.count) 个提醒")
            
            let birthdayReminders = reminders.filter { reminder in
                reminder.tag.code == "planning.birthday" && 
                reminder.pets?.contains(where: { $0.id == pet.id }) == true
            }
            print("🎂 \(pet.name)的生日提醒数量: \(birthdayReminders.count)")
            
        } catch {
            print("❌ 创建生日提醒失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    return AddPetView(modelContext: container.mainContext)
} 