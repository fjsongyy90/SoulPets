import SwiftUI
import SwiftData
import PhotosUI

/// 添加记录视图
struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecordViewModel
    @Query private var pets: [Pet]
    @Query private var tags: [Tag]
    
    // 照片选择器状态
    @State private var selectedItems: [PhotosPickerItem] = []
    
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
                             LocalizedStringKey("Select Pets & Event") : 
                             LocalizedStringKey(viewModel.selectedTag?.name ?? "Record Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .selectPetsAndEvent {
                        Button(LocalizedStringKey("Next")) {
                            viewModel.moveToNextStep()
                        }
                        .disabled(!viewModel.formIsValid)
                        .foregroundColor(viewModel.formIsValid ? accentColor : .gray)
                    } else {
                        Button(LocalizedStringKey("Add")) {
                            if viewModel.saveRecord() {
                                dismiss()
                            }
                        }
                        .disabled(!viewModel.formIsValid)
                        .foregroundColor(viewModel.formIsValid ? accentColor : .gray)
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 选择宠物和事件视图
    private var selectPetsAndEventView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 宠物选择器
                Text(LocalizedStringKey("Select Pets"))
                    .font(.headline)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(pets) { pet in
                            PetAvatarView(pet: pet, isSelected: viewModel.selectedPets.contains(where: { $0.id == pet.id }), accentColor: accentColor, textColor: textColor)
                                .onTapGesture {
                                    viewModel.togglePetSelection(pet: pet)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 验证提示
                if viewModel.selectedPets.isEmpty {
                    Text(LocalizedStringKey("Select at least one pet"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // 标签选择器
                Text(LocalizedStringKey("Select Event Type"))
                    .font(.headline)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                    .padding(.top)
                
                // 最近使用的标签
                if !viewModel.recentlyUsedTags.isEmpty {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Recently Used"))
                            .font(.subheadline)
                            .foregroundColor(labelColor)
                            .padding(.horizontal)
                        
                        tagGridView(tags: viewModel.recentlyUsedTags)
                    }
                }
                
                // 按分类显示标签
                ForEach(TagCategory.allCases, id: \.self) { category in
                    let filteredTags = filterTags(for: category)
                    if !filteredTags.isEmpty {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(category.rawValue))
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
    
    /// 记录详情视图
    private var recordDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 日期和时间选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Date & Time"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    DatePicker("", selection: $viewModel.recordDate)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .accentColor(accentColor)
                }
                .padding(.horizontal)
                
                // 备注输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Notes"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    TextEditor(text: $viewModel.recordNotes)
                        .foregroundColor(textColor)
                        .frame(minHeight: 100)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.recordNotes.isEmpty {
                                    Text(LocalizedStringKey("Add some details about this event (optional)"))
                                        .foregroundColor(labelColor)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                .padding(.horizontal)
                
                // 照片选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Photos"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(accentColor)
                            Text(LocalizedStringKey("Add Photos"))
                                .foregroundColor(accentColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
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
                    Text(LocalizedStringKey("Cost"))
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    TextField("0.00", text: $viewModel.recordCost)
                        .keyboardType(.decimalPad)
                        .foregroundColor(textColor)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(tags) { tag in
                TagItemView(tag: tag, isSelected: viewModel.selectedTag?.id == tag.id, accentColor: accentColor, textColor: textColor)
                    .onTapGesture {
                        viewModel.selectTag(tag)
                    }
            }
        }
        .padding(.horizontal)
    }
    
    /// 根据宠物类型和分类筛选标签
    private func filterTags(for category: TagCategory) -> [Tag] {
        // 如果没有选择宠物，返回空数组
        guard !viewModel.selectedPets.isEmpty else { return [] }
        
        // 获取所有选中宠物的类型
        let selectedPetTypes = viewModel.selectedPets.map { $0.petType }
        
        // 筛选同时适用于所有选中宠物类型的标签
        return tags.filter { tag in
            // 检查标签是否属于当前分类
            guard tag.category == category else { return false }
            
            // 检查标签是否适用于所有选中的宠物类型
            return selectedPetTypes.allSatisfy { petType in
                tag.isApplicableTo(petType: petType)
            }
        }
    }
}

/// 宠物头像视图
struct PetAvatarView: View {
    let pet: Pet
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        VStack {
            ZStack {
                // 头像
                if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(pet.petType == .dog ? "dog" : "cat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color(red: 0.97, green: 0.90, blue: 0.83))
                        )
                }
                
                // 选中状态
                if isSelected {
                    Circle()
                        .stroke(accentColor, lineWidth: 3)
                        .frame(width: 64, height: 64)
                }
            }
            
            // 宠物名称
            Text(pet.name)
                .font(.caption)
                .foregroundColor(isSelected ? accentColor : textColor)
                .lineLimit(1)
        }
    }
}

/// 标签项视图
struct TagItemView: View {
    let tag: Tag
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // 图标
            Image(systemName: tag.iconName)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : accentColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isSelected ? accentColor : Color(red: 0.97, green: 0.90, blue: 0.83))
                )
            
            // 名称
            Text(LocalizedStringKey(tag.name))
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : textColor)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? accentColor.opacity(0.8) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    AddRecordView(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self)))
} 