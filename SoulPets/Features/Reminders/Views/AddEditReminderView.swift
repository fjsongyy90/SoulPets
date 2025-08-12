import SwiftUI
import SwiftData

struct AddEditReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = AddEditReminderViewModel()
    @State private var showingTagManagement = false  // 新增：标签管理状态
    @Query private var allPets: [Pet]
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]  // 修改：按sortOrder排序
    
    let reminderToEdit: Reminder?
    
    // 颜色定义 - 与Record模块保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    init(reminderToEdit: Reminder? = nil) {
        self.reminderToEdit = reminderToEdit
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                backgroundColor.ignoresSafeArea()
                
                // 当前步骤内容
                VStack {
                    switch viewModel.currentStep {
                    case .selectPetsAndEvent:
                        selectPetsAndEventView
                    case .reminderDetails:
                        reminderDetailsView
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
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView(modelContext: modelContext)
            }
            .onChange(of: showingTagManagement) { oldValue, newValue in
                // 当标签管理页面关闭后，重新加载标签数据
                if oldValue && !newValue {
                    viewModel.loadAvailableTags(from: modelContext)
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
                if let reminder = reminderToEdit {
                    viewModel.setupForEditing(reminder)
                }
                viewModel.loadAvailableTags(from: modelContext)
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 选择宠物和事件视图 - 参考Record模块
    private var selectPetsAndEventView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 宠物选择器
                Text(String(localized: "Select Pets"))
                    .font(.headline)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(allPets) { pet in
                            PetAvatarView(
                                pet: pet, 
                                isSelected: viewModel.selectedPets.contains(where: { $0.id == pet.id }), 
                                accentColor: accentColor, 
                                textColor: textColor
                            )
                            .onTapGesture {
                                viewModel.togglePetSelection(pet: pet)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 验证提示
                if viewModel.selectedPets.isEmpty {
                    Text(String(localized: "Select at least one pet"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // 标签选择器标题和管理按钮
                HStack {
                    Text(String(localized: "Select Event Type"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    // 标签管理按钮
                    Button(action: {
                        showingTagManagement = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gear")
                                .font(.caption)
                            Text(String(localized: "Manage Tags"))
                                .font(.caption)
                        }
                        .foregroundColor(accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 按分类显示标签
                ForEach(TagCategory.allCases, id: \.self) { category in
                    let filteredTags = filterTags(for: category)
                    if !filteredTags.isEmpty {
                        VStack(alignment: .leading) {
                            Text(String(localized: LocalizedStringResource(stringLiteral: category.rawValue)))
                                .font(.subheadline)
                                .foregroundColor(labelColor)
                                .padding(.horizontal)
                            
                            tagGridView(tags: filteredTags)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    /// 提醒详情视图 - 参考Record模块
    private var reminderDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 日期和时间选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Date & Time"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .colorScheme(.light) // 强制使用浅色模式
                        .padding()
                        .background(Color.white) // 强制使用白色背景
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .accentColor(accentColor)
                }
                .padding(.horizontal)
                
                // 重复设置
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Repeat Settings"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    VStack(spacing: 16) {
                        // 重复开关
                        HStack {
                            Text(String(localized: "Repeat"))
                                .foregroundColor(textColor)
                            Spacer()
                            Toggle("", isOn: $viewModel.isRepeating)
                                .tint(accentColor)
                        }
                        
                        // 重复间隔设置
                        if viewModel.isRepeating {
                            HStack {
                                Text(String(localized: "Every"))
                                    .foregroundColor(textColor)
                                
                                Spacer()
                                
                                Picker("Interval", selection: $viewModel.repeatInterval) {
                                    ForEach(1...30, id: \.self) { interval in
                                        Text("\(interval)")
                                            .tag(interval)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(accentColor)
                                
                                Picker("Unit", selection: $viewModel.repeatUnit) {
                                    ForEach(RepeatUnit.allCases, id: \.self) { unit in
                                        Text(String(localized: "repeat_unit.\(unit.rawValue.lowercased())"))
                                            .tag(unit)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(accentColor)
                            }
                            
                            // 重复规则预览
                            if !viewModel.repeatRuleText.isEmpty {
                                Text(viewModel.repeatRuleText)
                                    .font(.caption)
                                    .foregroundColor(labelColor)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white) // 强制使用白色背景
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
                .padding(.horizontal)
                
                // 备注输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Notes"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    TextEditor(text: $viewModel.notes)
                        .foregroundColor(textColor)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color.white) // 直接设置白色背景
                        .colorScheme(.light) // 强制使用浅色模式
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 标签网格视图 - 复用Record模块的设计
    private func tagGridView(tags: [Tag]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags) { tag in
                    TagItemView(
                        tag: tag, 
                        isSelected: viewModel.selectedTag?.id == tag.id, 
                        accentColor: accentColor, 
                        textColor: textColor
                    )
                    .frame(width: 100) // 固定宽度确保一致性
                    .onTapGesture {
                        viewModel.selectTag(tag)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 根据宠物类型和分类筛选标签 - 与Record模块保持一致
    private func filterTags(for category: TagCategory) -> [Tag] {
        // 如果没有选择宠物，返回空数组
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取所有选中宠物的类型
        let selectedPetTypes = viewModel.selectedPets.map { $0.petType }
        
        // 筛选同时适用于所有选中宠物类型的标签，并排除隐藏的标签，只显示可用于提醒的标签
        return allTags.filter { tag in
            // 检查标签是否属于当前分类
            guard tag.category == category else { return false }
            
            // 排除隐藏的标签
            guard !tag.isHidden else { return false }
            
            // 只显示可用于提醒的标签
            guard tag.defaultIsReminder else { return false }
            
            // 检查标签是否适用于所有选中的宠物类型
            return selectedPetTypes.allSatisfy { petType in
                tag.isApplicableTo(petType: petType)
            }
        }
    }
}

#Preview {
    AddEditReminderView()
        .modelContainer(for: [Pet.self, Reminder.self, Tag.self])
} 