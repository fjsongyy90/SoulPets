import SwiftUI
import SwiftData

/// 适配器类：让ReminderViewModel能够与RecordViewModel的接口兼容
/// 这样可以复用AddRecordPetAndEventView组件
class ReminderRecordAdapter: RecordViewModel {
    private let reminderViewModel: AddEditReminderViewModel
    
    init(reminderViewModel: AddEditReminderViewModel, modelContext: ModelContext) {
        self.reminderViewModel = reminderViewModel
        super.init(modelContext: modelContext)
        
        // 同步初始数据
        self.selectedPets = reminderViewModel.selectedPets
        self.selectedTag = reminderViewModel.selectedTag
        self.recentlyUsedTags = reminderViewModel.recentlyUsedTags
    }
    
    /// 重写宠物选择方法，同步到ReminderViewModel
    override func togglePetSelection(pet: Pet) {
        super.togglePetSelection(pet: pet)
        // 同步到ReminderViewModel
        reminderViewModel.selectedPets = self.selectedPets
        // 触发ReminderViewModel的标签重新加载
        reminderViewModel.loadTags()
    }
    
    /// 重写标签选择方法，同步到ReminderViewModel
    override func selectTag(_ tag: Tag) {
        super.selectTag(tag)
        // 同步到ReminderViewModel
        reminderViewModel.selectedTag = self.selectedTag
    }
    
    /// 重写标签加载方法，从ReminderViewModel获取数据
    override func loadTags() {
        reminderViewModel.loadTags()
        // 同步最新的标签数据
        self.recentlyUsedTags = reminderViewModel.recentlyUsedTags
    }
}

struct AddEditReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: AddEditReminderViewModel
    
    // 颜色定义 - 与Record模块保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    init(reminderToEdit: Reminder? = nil, modelContext: ModelContext) {
        self.reminderToEdit = reminderToEdit
        if let reminder = reminderToEdit {
            _viewModel = StateObject(wrappedValue: AddEditReminderViewModel(reminder: reminder))
        } else {
            _viewModel = StateObject(wrappedValue: AddEditReminderViewModel(modelContext: modelContext))
        }
    }
    
    let reminderToEdit: Reminder?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                // 当前步骤内容
                VStack {
                    switch viewModel.currentStep {
                    case .selectPetsAndEvent:
                        // 复用Record模块的组件
                        AddRecordPetAndEventView(viewModel: adaptedRecordViewModel)
                    case .reminderDetails:
                        // 使用新创建的独立提醒详情页
                        AddReminderDetailsView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(viewModel.currentStep == .selectPetsAndEvent ? 
                             String(localized: "Select Pets & Event") : 
                             String(localized: LocalizedStringResource(stringLiteral: viewModel.selectedTag?.name ?? "Reminder Details")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .selectPetsAndEvent {
                        Button(String(localized: "Next")) {
                            viewModel.moveToNextStep()
                        }
                        .disabled(!viewModel.isStepOneValid)
                        .foregroundColor(viewModel.isStepOneValid ? accentColor : .gray)
                    } else {
                        Button(String(localized: viewModel.isEditing ? "Save" : "Add")) {
                            Task {
                                if await viewModel.saveReminder(modelContext: modelContext) {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .foregroundColor(viewModel.isFormValid && !viewModel.isLoading ? accentColor : .gray)
                    }
                }
            }
            .alert(
                String(localized: "Error"),
                isPresented: .constant(viewModel.errorMessage != nil)
            ) {
                Button(String(localized: "OK")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // 设置modelContext
                viewModel.modelContext = modelContext
                
                if let reminder = reminderToEdit {
                    viewModel.setupForEditing(reminder)
                }
                viewModel.loadAvailableTags(from: modelContext)
            }
        }
    }
    
    // MARK: - 适配器
    
    /// 适配器：将AddEditReminderViewModel适配为RecordViewModel接口
    /// 这样就可以复用AddRecordPetAndEventView组件
    private var adaptedRecordViewModel: ReminderRecordAdapter {
        ReminderRecordAdapter(reminderViewModel: viewModel, modelContext: modelContext)
    }
    
}

#Preview {
    let modelContainer = try! ModelContainer(for: Pet.self, Reminder.self, Tag.self)
    let modelContext = ModelContext(modelContainer)
    
    return AddEditReminderView(modelContext: modelContext)
        .modelContainer(modelContainer)
} 