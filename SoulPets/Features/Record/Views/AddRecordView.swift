import SwiftUI
import SwiftData
import PhotosUI

/// 添加记录视图
struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: RecordViewModel
    @Query private var pets: [Pet]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]  // 修改：按sortOrder排序
    
    // 照片选择器状态
    @State private var selectedItems: [PhotosPickerItem] = []
    
    // 标签管理状态
    @State private var showingTagManagement = false
    
    // 照片限制弹窗状态
    @State private var showingPhotoLimitActionSheet = false
    @State private var showingProInfoAlert = false
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: RecordViewModel(modelContext: modelContext))
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
                    case .recordDetails:
                        recordDetailsView
                    }
                }
            }
            .navigationTitle(viewModel.currentStep == .selectPetsAndEvent ? 
                             String(localized: "Select Pets & Event") : 
                             String(localized: LocalizedStringResource(stringLiteral: viewModel.selectedTag?.name ?? "Record Details")))
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
                        .disabled(!viewModel.formIsValid)
                        .foregroundColor(viewModel.formIsValid ? accentColor : .gray)
                    } else {
                        Button(String(localized: "Add")) {
                            if viewModel.saveRecord() {
                                dismiss()
                            }
                        }
                        .disabled(!viewModel.formIsValid)
                        .foregroundColor(viewModel.formIsValid ? accentColor : .gray)
                    }
                }
                
                // 统一的键盘工具栏 - 只显示一个Done按钮
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        // 关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView(modelContext: viewModel.modelContext)
            }
            .confirmationDialog(
                String(localized: "Photo Limit Reached"),
                isPresented: $viewModel.showPhotoLimitAlert,
                titleVisibility: .visible
            ) {
                // 管理相册以释放空间
                Button(String(localized: "Manage Photos to Free Up Space")) {
                    viewModel.showPetPhotosManagement = true
                }
                
                // 返回编辑本次照片
                Button(String(localized: "Edit Photos for This Record")) {
                    // 关闭弹窗，用户可以在当前页面删除一些照片
                }
                
                // 了解 SoulPets Pro
                Button(String(localized: "Learn About SoulPets Pro (Coming Soon)")) {
                    showingProInfoAlert = true
                }
                .foregroundColor(.secondary)
                
                // 取消
                Button(String(localized: "Cancel"), role: .cancel) {
                    // 关闭弹窗，不做任何操作
                }
            } message: {
                if let pet = viewModel.photoLimitAlertPet {
                    Text(String(localized: "\"\(pet.name)\"'s album has reached the 50-photo limit for the free version. To save this record, you can:"))
                } else {
                    Text(String(localized: "Photo limit reached. To save this record, you can:"))
                }
            }
            .sheet(isPresented: $viewModel.showPetPhotosManagement) {
                if let pet = viewModel.photoLimitAlertPet {
                    PetPhotosView(pet: pet)
                }
            }
            .onChange(of: viewModel.showPetPhotosManagement) { oldValue, newValue in
                // 当照片管理页面关闭后，重新尝试保存记录
                if oldValue && !newValue {
                    // 延迟一点时间确保数据已更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if viewModel.retryRecordSave() {
                            dismiss()
                        }
                    }
                }
            }
            .alert(
                String(localized: "SoulPets Pro"),
                isPresented: $showingProInfoAlert
            ) {
                Button(String(localized: "OK")) {
                    // 关闭弹窗
                }
            } message: {
                Text(String(localized: "With Pro features, you can track all expenses and generate annual reports."))
            }
            .onChange(of: showingTagManagement) { oldValue, newValue in
                // 当标签管理页面关闭后，重新加载标签数据
                if oldValue && !newValue {
                    viewModel.loadTags()
                }
            }
        }
        
    }
    
    // MARK: - 子视图
    
    /// 选择宠物和事件视图 (已重构)
    private var selectPetsAndEventView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - 拆分出的第一个子视图：宠物选择卡片
                petSelectorCard
                
                // MARK: - 拆分出的第二个子视图：标签选择部分
                tagSelectorSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helper View 1: 宠物选择卡片
    private var petSelectorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Select Pets"))
                .font(.headline)
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(pets) { pet in
                                                 PetAvatarView(pet: pet, isSelected: viewModel.selectedPets.contains(where: { $0.id == pet.id }), accentColor: accentColor, textColor: textColor)
                             .onTapGesture {
                                 withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                     viewModel.togglePetSelection(pet: pet)
                                 }
                             }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // 优化的验证提示
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    if !viewModel.selectedPets.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.green.opacity(0.8))
                    }
                    Text(viewModel.selectedPets.isEmpty ?
                         String(localized: "Select at least one pet") :
                         String(localized: "\(viewModel.selectedPets.count) pet(s) selected"))
                        .font(.caption)
                        .foregroundColor(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedPets.isEmpty ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPets.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Helper View 2: 标签选择部分
    private var tagSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标签选择器标题和管理按钮
            HStack {
                Text(String(localized: "Select Event Type"))
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
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
            
            // 最近使用的标签 - 只在选择了宠物时显示
            if !viewModel.selectedPets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Recently Used"))
                        .font(.subheadline)
                        .foregroundColor(labelColor)
                        .padding(.horizontal)
                    
                    let filteredRecentTags = filterRecentlyUsedTags()
                    
                    if !filteredRecentTags.isEmpty {
                        tagGridView(tags: filteredRecentTags)
                    } else {
                        // 空状态提示
                        Text(String(localized: "No recently used tags for selected pets"))
                            .font(.caption)
                            .foregroundColor(labelColor.opacity(0.7))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .italic()
                    }
                }
            }
            
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
    }
    
    /// 记录详情视图
    private var recordDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 日期和时间选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Date & Time"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    DatePicker("", selection: $viewModel.recordDate)
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
                
                // 备注输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Notes"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    TextEditor(text: $viewModel.recordNotes)
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
                
                // 照片选择器
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "Photos"))
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        // 显示照片限制提示
                        if !UserPreferencesService.shared.isProMember {
                            Text("Max \(UserPreferencesService.shared.maxPhotosPerRecord)")
                                .font(.caption)
                                .foregroundColor(labelColor)
                        }
                    }
                    
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: UserPreferencesService.shared.maxPhotosPerRecord,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(accentColor)
                                .font(.system(size: 16))
                            Text(String(localized: "Add Photos"))
                                .foregroundColor(accentColor)
                                .font(.body)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 20))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.5))
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 非会员限制提示
                    if !UserPreferencesService.shared.isProMember && viewModel.recordPhotos.count >= UserPreferencesService.shared.maxPhotosPerRecord {
                        Text(String(localized: "Free version allows up to 2 photos per record. Upgrade to SoulPets Pro for unlimited photos."))
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                    
                    // 已选照片预览
                    if !viewModel.recordPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<viewModel.recordPhotos.count, id: \.self) { index in
                                    Image(uiImage: viewModel.recordPhotos[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            Button {
                                                viewModel.recordPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                            }
                                            .padding(5),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 花费输入框（为未来功能预留）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "Cost"))
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Button(action: {
                            showingProInfoAlert = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    
                    TextField("0.00", text: $viewModel.recordCost)
                        .keyboardType(.decimalPad)
                        .foregroundColor(textColor)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white) // 强制使用白色背景
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                viewModel.recordPhotos.removeAll()
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.recordPhotos.append(image)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 标签网格视图
    private func tagGridView(tags: [Tag]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags) { tag in
                    TagItemView(tag: tag, isSelected: viewModel.selectedTag?.id == tag.id, accentColor: accentColor, textColor: textColor)
                        .frame(width: 100) // 固定宽度确保一致性
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                viewModel.selectTag(tag)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 根据宠物类型过滤最近使用的标签
    private func filterRecentlyUsedTags() -> [Tag] {
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取选择的宠物类型
        let selectedPetTypes = Set(viewModel.selectedPets.map { $0.petType })
        
        // 过滤最近使用的标签，只保留适用于选择宠物类型的标签
        return viewModel.recentlyUsedTags.filter { tag in
            !tag.isHidden && selectedPetTypes.isSubset(of: Set(tag.getApplicablePetTypes()))
        }
    }
    
    /// 根据宠物类型和分类筛选标签
    private func filterTags(for category: TagCategory) -> [Tag] {
        // 如果没有选择宠物，返回空数组
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取所有选中宠物的类型
        let selectedPetTypes = viewModel.selectedPets.map { $0.petType }
        
        // 筛选同时适用于所有选中宠物类型的标签，并排除隐藏的标签
        return tags.filter { tag in
            // 检查标签是否属于当前分类
            guard tag.category == category else { return false }
            
            // 排除隐藏的标签
            guard !tag.isHidden else { return false }
            
            // 检查标签是否适用于所有选中的宠物类型
            return selectedPetTypes.allSatisfy { petType in
                tag.isApplicableTo(petType: petType)
            }
        }
    }
}

#Preview {
    AddRecordView(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self)))
} 
