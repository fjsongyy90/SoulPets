import SwiftUI
import SwiftData

/// 添加宠物的主视图
struct AddPetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PetViewModel
    @State private var showingBirthdayReminderAlert = false
    @State private var shouldCreateBirthdayReminder = false
    
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
                            PetImportantDatesView(viewModel: viewModel)
                        }
                    }
                    .scrollDismissesKeyboard(.immediately) // 滚动时立即收起键盘
                    
                    // 导航按钮 - 使用新的UI风格
                    if viewModel.currentStep == .selectType {
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
                    } else if viewModel.currentStep == .basicInfo {
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
                                        .fill(viewModel.formIsValid ? accentColor : Color.gray)
                                )
                        }
                        .disabled(!viewModel.formIsValid)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .padding(.top, 10)
                    } else if viewModel.currentStep == .importantDates {
                        Button(action: {
                            // 最后一步，保存宠物
                            saveAndFinish()
                        }) {
                            Text(LocalizedStringKey("Finish & Welcome, \(viewModel.name)!"))
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("SoulPets"))
                        .font(.headline)
                        .fontWeight(.bold)
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
        .onAppear {
            // 修复键盘工具栏布局问题
            // 不再直接修改UIToolbar的外观，改为在PetBasicInfoView中处理
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
        if shouldCreateBirthdayReminder {
            // 创建生日提醒的代码
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