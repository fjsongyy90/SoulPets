import SwiftUI
import SwiftData
import PhotosUI
import OSLog

/// 记录详情视图
struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let record: Record
    @State private var isEditing = false
    @State private var editedNotes: String = ""
    @State private var editedDate: Date = Date()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newPhotos: [(id: UUID, image: UIImage)] = []
    @State private var showingDeleteAlert = false
    
    // 键盘工具栏相关状态
    @FocusState private var isNotesFieldFocused: Bool
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "RecordDetail")
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 标签信息卡片
                        tagInfoCard
                        
                        // 情境卡片 - 合并日期时间和宠物信息
                        contextCard
                        
                        // 备注卡片
                        notesCard
                        
                        // 照片卡片 - 统一管理新旧照片
                        photosCard
                    }
                    .padding()
                }
                
                // 🔧 修复：移除浮动Done按钮，避免重复显示
            }
            .navigationTitle(String(localized: "Record Details"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditing)
            .toolbar {
                // 自定义返回按钮（编辑模式下）
                if isEditing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            cancelEditing()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text(String(localized: "Cancel"))
                                    .font(.body)
                            }
                            .foregroundColor(accentColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(String(localized: "Save")) {
                            saveChanges()
                        }
                        .foregroundColor(accentColor)
                    } else {
                        Menu {
                            Button {
                                startEditing()
                            } label: {
                                Label(String(localized: "Edit"), systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                
                // 🔧 键盘工具栏完成按钮（仅在编辑模式且有焦点时显示）
                if isEditing && isNotesFieldFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(String(localized: "Done")) {
                            logger.info("🔧 RecordDetail键盘工具栏完成按钮被点击")
                            logger.info("🔧 当前焦点状态 - Notes: \(isNotesFieldFocused)")
                            
                            // 关闭键盘
                            isNotesFieldFocused = false
                            
                            // 备用方法：使用 UIApplication 方式关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            logger.info("🔧 键盘关闭操作已执行")
                        }
                        .foregroundColor(accentColor)
                    }
                }
            }
            .alert(String(localized: "Delete Record"), isPresented: $showingDeleteAlert) {
                Button(String(localized: "Cancel"), role: .cancel) { }
                Button(String(localized: "Delete"), role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete this record? This action cannot be undone."))
            }
        }
        .onChange(of: isNotesFieldFocused) { oldValue, newValue in
            logger.info("📝 RecordDetail Notes焦点状态变化: \(oldValue) -> \(newValue)")
        }
        .onAppear {
            logger.info("📱 RecordDetailView onAppear - 键盘工具栏应该已加载")
        }
    }
    
    // MARK: - 子视图
    
    /// 标签信息卡片
    private var tagInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(record.tag.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: LocalizedStringResource(stringLiteral: record.tag.name)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: record.tag.category.rawValue)))
                        .font(.subheadline)
                        .foregroundColor(labelColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEditing ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 情境卡片 - 合并日期时间和宠物信息
    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 日期时间区域
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Date & Time"))
                    .font(.appHeadline)
                    .foregroundColor(textColor)
                
                if isEditing {
                    DatePicker("", selection: $editedDate)
                        .datePickerStyle(.compact)
                        .accentColor(accentColor)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        // 日期 - 作为视觉重点
                        Text(formattedDateOnly(record.timestamp))
                            .font(.appBody)
                            .fontWeight(.medium)
                            .foregroundColor(textColor)
                        
                        // 时间 - 次要信息
                        Text(formattedTimeOnly(record.timestamp))
                            .font(.appCaption)
                            .foregroundColor(labelColor)
                    }
                }
            }
            
            // 宠物信息区域 - 与RecordsView保持一致的横向布局
            if let pets = record.pets, !pets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pets.count == 1 ? String(localized: "Pet") : String(localized: "Pets"))
                        .font(.appHeadline)
                        .foregroundColor(textColor)
                    
                    // 使用与RecordsView相同的宠物展示逻辑
                    petInfoSection(pets: pets)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEditing ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 宠物信息区域 - 与RecordsView保持一致
    @ViewBuilder
    private func petInfoSection(pets: [Pet]) -> some View {
        if pets.count == 1 {
            // 单宠物：显示头像 + 名字
            HStack(spacing: 8) {
                petAvatarView(pet: pets[0], size: 24)
                
                Text(pets[0].name)
                    .font(.appCaption)
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                
                Spacer()
            }
        } else {
            // 多宠物：横向排列头像，可略带重叠效果
            HStack(spacing: -4) { // 负间距创造重叠效果
                ForEach(pets.prefix(4)) { pet in // 最多显示4个头像
                    petAvatarView(pet: pet, size: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1) // 白色边框分离重叠的头像
                        )
                }
                
                // 如果宠物数量超过4个，显示数量标识
                if pets.count > 4 {
                    Text("+\(pets.count - 4)")
                        .font(.caption2)
                        .foregroundColor(labelColor)
                        .fontWeight(.medium)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
            }
        }
    }
    
    /// 宠物头像视图
    @ViewBuilder
    private func petAvatarView(pet: Pet, size: CGFloat) -> some View {
        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.88, blue: 0.80))
                    .frame(width: size, height: size)
                
                Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.7, height: size * 0.7)
            }
        }
    }
    
    /// 备注卡片 - 去图标化，统一编辑样式，保持视觉韵律
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Notes"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            if isEditing {
                ZStack(alignment: .topLeading) {
                    // 背景容器
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // TextEditor
                    TextEditor(text: $editedNotes)
                        .foregroundColor(textColor)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color.clear)
                        .colorScheme(.light)
                        .focused($isNotesFieldFocused)
                        .onTapGesture {
                            logger.info("📝 RecordDetail Notes TextEditor被点击，设置焦点")
                            isNotesFieldFocused = true
                        }
                    
                    // 情感化占位符
                    if editedNotes.isEmpty {
                        Text("What's a sweet memory you made just now?")
                            .font(.appBody)
                            .foregroundColor(labelColor.opacity(0.7))
                            .italic()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
            } else {
                // 查看模式 - 设置最小高度保持视觉韵律
                VStack(alignment: .leading, spacing: 8) {
                    if let notes = record.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.appBody)
                            .foregroundColor(textColor)
                    } else {
                        Text(String(localized: "No notes"))
                            .font(.appBody)
                            .foregroundColor(labelColor)
                            .italic()
                    }
                }
                .frame(minHeight: 60, alignment: .topLeading) // 设置最小高度，保持视觉平衡
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 100) // 整个卡片的最小高度
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEditing ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 照片卡片 - 去图标化，统一管理新旧照片
    @ViewBuilder
    private var photosCard: some View {
        let allPhotos = getAllPhotos()
        
        // 只在有照片或者编辑模式时显示卡片
        if !allPhotos.isEmpty || isEditing {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(String(localized: "Photos"))
                        .font(.appHeadline)
                        .foregroundColor(textColor)
                    Spacer()
                    
                    // 显示照片限制提示
                    if !UserPreferencesService.shared.isProMember {
                        HStack(spacing: 2) {
                            Text("Max")
                                .font(.appCaption2)
                                .foregroundColor(labelColor)
                            Text("\(UserPreferencesService.shared.maxPhotosPerRecord)")
                                .font(.appCaption2)
                                .fontWeight(.semibold)
                                .foregroundColor(labelColor)
                        }
                    }
                    
                    if isEditing {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: UserPreferencesService.shared.maxPhotosPerRecord,
                            matching: .images
                        ) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                                .font(.title2)
                        }
                    }
                }
                
                if !allPhotos.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(Array(allPhotos.enumerated()), id: \.offset) { index, photoItem in
                            photoGridItem(photoItem: photoItem, index: index)
                        }
                    }
                } else if isEditing {
                    // 编辑模式下的空状态提示
                    VStack(spacing: 8) {
                        Text(String(localized: "Add photos to capture this moment"))
                            .font(.appBody)
                            .foregroundColor(labelColor)
                            .italic()
                        
                        // 非会员限制提示
                        if !UserPreferencesService.shared.isProMember {
                            Text(String(localized: "Free version allows up to 2 photos per record. Upgrade to SoulPets Pro for unlimited photos."))
                                .font(.appFootnote)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEditing ? Color(UIColor.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .onChange(of: selectedItems) { oldValue, newValue in
                Task {
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                // 检查总照片数量限制（现有照片 + 新增照片）
                                let currentPhotoCount = (record.photos?.count ?? 0) + newPhotos.count
                                let maxPhotos = UserPreferencesService.shared.maxPhotosPerRecord
                                
                                if currentPhotoCount < maxPhotos {
                                    newPhotos.append((id: UUID(), image: image))
                                }
                                // 如果超出限制，静默忽略（PhotosPicker已经限制了选择数量）
                            }
                        }
                    }
                    selectedItems.removeAll()
                }
            }
        }
    }
    
    // MARK: - 照片管理辅助方法
    
    /// 照片项目类型
    enum PhotoItem {
        case existing(RecordPhoto)
        case new(id: UUID, image: UIImage)
    }
    
    /// 获取所有照片（现有 + 新增）
    private func getAllPhotos() -> [PhotoItem] {
        var allPhotos: [PhotoItem] = []
        
        // 添加现有照片
        if let photos = record.photos {
            allPhotos.append(contentsOf: photos.map { .existing($0) })
        }
        
        // 添加新增照片
        for photoItem in newPhotos {
            allPhotos.append(.new(id: photoItem.id, image: photoItem.image))
        }
        
        return allPhotos
    }
    
    /// 照片网格项
    @ViewBuilder
    private func photoGridItem(photoItem: PhotoItem, index: Int) -> some View {
        switch photoItem {
        case .existing(let recordPhoto):
            if let image = UIImage(data: recordPhoto.photoData) {
                photoImageView(image: image, isNewPhoto: false, photoItem: photoItem)
            }
        case .new(_, let uiImage):
            photoImageView(image: uiImage, isNewPhoto: true, photoItem: photoItem)
        }
    }
    
    /// 照片图像视图
    @ViewBuilder
    private func photoImageView(image: UIImage, isNewPhoto: Bool, photoItem: PhotoItem) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Group {
                    if isEditing {
                        Button {
                            deletePhotoItem(photoItem)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.red))
                        }
                        .padding(5)
                    }
                    
                    // 新照片标识
                    if isNewPhoto && !isEditing {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("NEW")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange)
                                    )
                                    .padding(.trailing, 8)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                },
                alignment: .topTrailing
            )
    }
    
    /// 删除照片项
    private func deletePhotoItem(_ photoItem: PhotoItem) {
        switch photoItem {
        case .existing(let recordPhoto):
            deletePhoto(recordPhoto)
        case .new(let id, _):
            // 通过UUID精确删除
            newPhotos.removeAll { $0.id == id }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 格式化日期 - 分别获取日期和时间
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// 格式化日期部分
    private func formattedDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// 格式化时间部分
    private func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// 开始编辑
    private func startEditing() {
        isEditing = true
        editedNotes = record.notes ?? ""
        editedDate = record.timestamp
    }
    
    /// 取消编辑
    private func cancelEditing() {
        isEditing = false
        editedNotes = ""
        editedDate = Date()
        newPhotos.removeAll()
        selectedItems.removeAll()
    }
    
    /// 保存更改
    private func saveChanges() {
        do {
            // 更新记录信息
            record.notes = editedNotes.isEmpty ? nil : editedNotes
            record.timestamp = editedDate
            record.updatedAt = Date()
            
            // 添加新照片
            for photoItem in newPhotos {
                if let imageData = photoItem.image.jpegData(compressionQuality: 0.5) {
                    RecordService.addPhotoToRecord(record: record, photoData: imageData, modelContext: modelContext)
                }
            }
            
            try modelContext.save()
            
            // 重置编辑状态
            isEditing = false
            newPhotos.removeAll()
            selectedItems.removeAll()
            
            logger.info("成功更新记录")
            
        } catch {
            logger.error("保存记录更改时出错: \(error.localizedDescription)")
        }
    }
    
    /// 删除照片
    private func deletePhoto(_ photo: RecordPhoto) {
        RecordService.deletePhoto(photo: photo, modelContext: modelContext)
    }
    
    /// 删除记录
    private func deleteRecord() {
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            logger.info("成功删除记录")
            dismiss()
        } catch {
            logger.error("删除记录时出错: \(error.localizedDescription)")
        }
    }
}

#Preview {
    RecordDetailView(record: {
        // 创建预览数据
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self, configurations: config)
        
        // 创建测试数据
        let context = container.mainContext
        let tag = Tag(code: "daily.food", name: "Dinner/Food", iconName: "fork.knife", category: .dailyLife, associatedPetTypes: [.cat, .dog])
        let pet = Pet(name: "Mimi", petType: .cat, breed: "British Shorthair", gender: .female, isNeutered: true, birthday: Date())
        let record = Record(timestamp: Date(), notes: "给咪咪喂了晚饭，她很喜欢新的猫粮", tag: tag, pets: [pet])
        
        context.insert(tag)
        context.insert(pet)
        context.insert(record)
        
        return record
    }())
    .modelContainer({
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self, configurations: config)
    }())
} 