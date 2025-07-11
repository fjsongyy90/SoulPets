import SwiftUI
import SwiftData

/// 添加宠物的主视图
struct AddPetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PetViewModel
    @State private var showingBirthdayReminderAlert = false
    @State private var shouldCreateBirthdayReminder = false
    
    // 步骤标题
    private let stepTitles = ["Pet Type", "Basic Info", "Important Dates"]
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: PetViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 步骤指示器
                StepIndicator(
                    currentStep: stepForAddPetStep(viewModel.currentStep),
                    totalSteps: 3,
                    stepTitles: stepTitles
                )
                .padding(.top)
                
                // 当前步骤内容
                ScrollView {
                    switch viewModel.currentStep {
                    case .selectType:
                        PetTypeSelectionView(selectedType: $viewModel.petType)
                            .padding(.top, 20)
                    case .basicInfo:
                        PetBasicInfoView(viewModel: viewModel)
                    case .importantDates:
                        PetImportantDatesView(viewModel: viewModel)
                    }
                }
                
                // 导航按钮
                HStack {
                    // 上一步按钮
                    if viewModel.currentStep != .selectType {
                        Button(action: {
                            viewModel.moveToPreviousStep()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(LocalizedStringKey("Back"))
                            }
                            .padding()
                            .foregroundColor(Color("AccentColor"))
                        }
                    }
                    
                    Spacer()
                    
                    // 下一步/完成按钮
                    Button(action: {
                        if viewModel.currentStep == .importantDates {
                            // 最后一步，保存宠物
                            saveAndFinish()
                        } else {
                            // 进入下一步
                            viewModel.moveToNextStep()
                        }
                    }) {
                        HStack {
                            Text(viewModel.currentStep == .importantDates ? 
                                 LocalizedStringKey("Finish & Welcome \(viewModel.name)!") : 
                                 LocalizedStringKey("Next"))
                            
                            if viewModel.currentStep != .importantDates {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.currentStep == .basicInfo && !viewModel.formIsValid ? 
                                      Color.gray : Color("AccentColor"))
                        )
                    }
                    .disabled(viewModel.currentStep == .basicInfo && !viewModel.formIsValid)
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("Add New Pet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
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
            }
        }
    }
    
    // 将枚举步骤转换为数字索引
    private func stepForAddPetStep(_ step: AddPetStep) -> Int {
        switch step {
        case .selectType: return 0
        case .basicInfo: return 1
        case .importantDates: return 2
        }
    }
    
    // 保存宠物并显示生日提醒询问
    private func saveAndFinish() {
        do {
            _ = try viewModel.savePet()
            showingBirthdayReminderAlert = true
        } catch {
            print("Error saving pet: \(error.localizedDescription)")
        }
    }
    
    // 完成并关闭视图
    private func finishAndDismiss() {
        // TODO: 如果用户选择了创建生日提醒，这里应该创建一个提醒
        if shouldCreateBirthdayReminder {
            // 在这里创建生日提醒的代码
            print("应该创建生日提醒")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    return AddPetView(modelContext: container.mainContext)
} 