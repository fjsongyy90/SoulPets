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
    @State private var newPhotos: [UIImage] = []
    @State private var showingDeleteAlert = false
    
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
                        
                        // 日期时间卡片
                        dateTimeCard
                        
                        // 宠物信息卡片
                        if let pets = record.pets, !pets.isEmpty {
                            petInfoCard(pets: pets)
                        }
                        
                        // 备注卡片
                        notesCard
                        
                        // 照片卡片
                        if let photos = record.photos, !photos.isEmpty {
                            photosCard(photos: photos)
                        }
                        
                        // 新添加的照片预览
                        if !newPhotos.isEmpty {
                            newPhotosCard
                        }
                    }
                    .padding()
                }
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 日期时间卡片
    private var dateTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(accentColor)
                Text(String(localized: "Date & Time"))
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
            }
            
            if isEditing {
                DatePicker("", selection: $editedDate)
                    .datePickerStyle(.compact)
                    .accentColor(accentColor)
            } else {
                Text(formattedDate(record.timestamp))
                    .font(.body)
                    .foregroundColor(textColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 宠物信息卡片
    private func petInfoCard(pets: [Pet]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(accentColor)
                Text(pets.count == 1 ? String(localized: "Pet") : String(localized: "Pets"))
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(pets) { pet in
                    VStack(spacing: 8) {
                        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(pet.petType == .dog ? "pet_dog" : "pet_cat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        
                        Text(pet.name)
                            .font(.caption)
                            .foregroundColor(textColor)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 备注卡片
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(accentColor)
                Text(String(localized: "Notes"))
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
            }
            
            if isEditing {
                TextEditor(text: $editedNotes)
                    .foregroundColor(textColor)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray6))
                    )
            } else {
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(textColor)
                } else {
                    Text(String(localized: "No notes"))
                        .font(.body)
                        .foregroundColor(labelColor)
                        .italic()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 照片卡片
    private func photosCard(photos: [RecordPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(accentColor)
                Text(String(localized: "Photos"))
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
                
                if isEditing {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.title2)
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(photos) { photo in
                    if let uiImage = UIImage(data: photo.photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                Group {
                                    if isEditing {
                                        Button {
                                            deletePhoto(photo)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.red))
                                        }
                                        .padding(5)
                                    }
                                },
                                alignment: .topTrailing
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            newPhotos.append(image)
                        }
                    }
                }
                selectedItems.removeAll()
            }
        }
    }
    
    /// 新照片卡片
    private var newPhotosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.badge.plus")
                    .foregroundColor(accentColor)
                Text(String(localized: "New Photos"))
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(0..<newPhotos.count, id: \.self) { index in
                    Image(uiImage: newPhotos[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Button {
                                newPhotos.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.red))
                            }
                            .padding(5),
                            alignment: .topTrailing
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemYellow).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.systemYellow), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 辅助方法
    
    /// 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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
            for image in newPhotos {
                if let imageData = image.jpegData(compressionQuality: 0.5) {
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