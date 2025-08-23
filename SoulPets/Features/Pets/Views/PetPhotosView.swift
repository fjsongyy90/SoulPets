import SwiftUI
import SwiftData

/// 宠物照片管理页面
struct PetPhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    @State private var isSelectionMode = false
    @State private var selectedPhotos: Set<UUID> = []
    @State private var showingDeleteAlert = false
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let cardColor = Color.white
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // 网格布局配置
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // 获取宠物的所有照片
    private var petPhotos: [RecordPhoto] {
        guard let records = pet.records else { return [] }
        
        return records.compactMap { record in
            record.photos ?? []
        }.flatMap { $0 }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    // 智能删除确认消息
    private var deleteConfirmationMessage: String {
        let selectedCount = selectedPhotos.count
        let photosToDelete = petPhotos.filter { selectedPhotos.contains($0.id) }
        
        var sharedPhotosCount = 0
        var exclusivePhotosCount = 0
        
        for photo in photosToDelete {
            if let record = photo.record,
               let recordPets = record.pets,
               recordPets.count > 1 {
                sharedPhotosCount += 1
            } else {
                exclusivePhotosCount += 1
            }
        }
        
        if selectedCount == 1 {
            if sharedPhotosCount == 1 {
                return String(localized: "This photo belongs to multiple pets. Only the association with \(pet.name) will be removed.")
            } else {
                return String(localized: "This photo will be permanently deleted.")
            }
        } else {
            var message = ""
            if exclusivePhotosCount > 0 {
                message += String(localized: "\(exclusivePhotosCount) photos will be permanently deleted.")
            }
            if sharedPhotosCount > 0 {
                if !message.isEmpty { message += "\n" }
                message += String(localized: "\(sharedPhotosCount) shared photos will only remove the association with \(pet.name).")
            }
            return message
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if petPhotos.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    // 照片网格
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(petPhotos, id: \.id) { photo in
                                photoGridItem(photo: photo)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("\(pet.name)'s Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
                
                if !petPhotos.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if isSelectionMode {
                            HStack(spacing: 16) {
                                Button("Cancel") {
                                    exitSelectionMode()
                                }
                                .foregroundColor(accentColor)
                                
                                if !selectedPhotos.isEmpty {
                                    Button("Delete") {
                                        showingDeleteAlert = true
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        } else {
                            Button("Select") {
                                enterSelectionMode()
                            }
                            .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .customConfirmAlert(
                title: String(localized: "Delete Photos"),
                message: deleteConfirmationMessage,
                isPresented: $showingDeleteAlert,
                confirmTitle: String(localized: "Delete"),
                confirmAction: {
                    deleteSelectedPhotos()
                },
                isDestructive: true
            )
        }
    }
    
    // 照片网格项
    private func photoGridItem(photo: RecordPhoto) -> some View {
        let isSelected = selectedPhotos.contains(photo.id)
        
        return ZStack {
            // 照片
            if let uiImage = UIImage(data: photo.photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // 选择模式下的选中指示器
            if isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accentColor)
                                    .font(.system(size: 20))
                            } else {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .onTapGesture {
            if isSelectionMode {
                togglePhotoSelection(photo: photo)
            } else {
                // 可以在这里添加查看大图的功能
            }
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Photos Yet")
                    .font(.appTitle2)
                    .foregroundColor(textColor)
                
                Text("Photos from \(pet.name)'s records will appear here")
                    .font(.appBody)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // 进入选择模式
    private func enterSelectionMode() {
        isSelectionMode = true
        selectedPhotos.removeAll()
    }
    
    // 退出选择模式
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedPhotos.removeAll()
    }
    
    // 切换照片选择状态
    private func togglePhotoSelection(photo: RecordPhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }
    
    // 删除选中的照片
    private func deleteSelectedPhotos() {
        let photosToDelete = petPhotos.filter { selectedPhotos.contains($0.id) }
        
        for photo in photosToDelete {
            deletePhotoForCurrentPet(photo: photo)
        }
        
        exitSelectionMode()
    }
    
    // 为当前宠物删除照片的智能逻辑
    private func deletePhotoForCurrentPet(photo: RecordPhoto) {
        guard let record = photo.record else { return }
        
        // 检查这条记录是否属于多只宠物
        if let recordPets = record.pets, recordPets.count > 1 {
            // 记录属于多只宠物，只移除当前宠物的关联
            let updatedPets = recordPets.filter { $0.id != pet.id }
            record.pets = updatedPets
            
            // 如果移除当前宠物后，记录不再属于任何宠物，则删除整条记录（包括照片）
            if updatedPets.isEmpty {
                modelContext.delete(record)
            }
        } else {
            // 记录只属于当前宠物，直接删除整条记录（照片会通过cascade自动删除）
            modelContext.delete(record)
        }
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("删除照片时出错: \(error.localizedDescription)")
        }
    }
}

#Preview("宠物照片管理") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    
    let pet = Pet(
        name: "Mimi",
        petType: .cat,
        breed: "British Shorthair",
        gender: .female,
        isNeutered: true,
        birthday: Date(),
        weightUnitPreference: .kg
    )
    container.mainContext.insert(pet)
    
    return PetPhotosView(pet: pet)
        .modelContainer(container)
}