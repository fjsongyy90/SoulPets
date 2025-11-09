import SwiftUI
import SwiftData

/// 宠物详情视图
struct PetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    
    let pet: Pet
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingPhotosSheet = false
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let cardColor = Color.white
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.5, green: 0.5, blue: 0.5)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    // 创建格式化器
    private let birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 24) {
                // 宠物头像
                petAvatarSection
                
                // 基本信息卡片
                infoCard(title: String(localized: "Basic Information")) {
                    infoRow(label: String(localized: "Name"), value: pet.name)
                    // v1.1.0: petType 使用可选链，因为 CloudKit 要求枚举类型必须可选
                    infoRow(label: String(localized: "Type"), value: pet.petType?.rawValue ?? "unknown")
                    infoRow(label: String(localized: "Breed / Color"), value: pet.breed)
                    infoRow(label: String(localized: "Gender"), value: pet.gender?.rawValue ?? "unknown")
                    infoRow(label: String(localized: "Neutered / Spayed"), value: pet.isNeutered ? String(localized: "Yes") : String(localized: "No"))
                }
                
                // 年龄与日期信息卡片
                infoCard(title: String(localized: "Age & Important Dates")) {
                    // 年龄显示
                    let age = pet.age
                    infoRow(label: String(localized: "Age"), value: "\(age.years)y \(age.months)m \(age.days)d")
                    
                    // 生日显示
                    infoRow(label: String(localized: "Birthday"), value: birthdayFormatter.string(from: pet.birthday))
                    
                    // 领养日显示
                    if let adoptionDay = pet.adoptionDay {
                        infoRow(label: String(localized: "Adoption Day"), value: birthdayFormatter.string(from: adoptionDay))
                        if let days = pet.daysWithOwner {
                            infoRow(label: String(localized: "Together for"), value: "\(days) days")
                        }
                    }
                    
                    // 下个生日
                    infoRow(label: String(localized: "Next Birthday"), value: "In \(pet.daysToNextBirthday) days")
                }
                
                // 照片卡片
                photosCard
                
                // 健康信息卡片
                infoCard(title: String(localized: "Health Information")) {
                    if !pet.microchipID.isEmpty {
                        infoRow(label: String(localized: "Microchip ID"), value: pet.microchipID)
                    } else {
                        infoRow(label: String(localized: "Microchip ID"), value: String(localized: "Not set"))
                    }
                    
                    if !pet.insurancePolicyNo.isEmpty {
                        infoRow(label: String(localized: "Insurance Policy No."), value: pet.insurancePolicyNo)
                    } else {
                        infoRow(label: String(localized: "Insurance Policy No."), value: String(localized: "Not set"))
                    }
                    
                    infoRow(label: String(localized: "Weight Unit"), value: pet.weightUnitPreference?.rawValue ?? "kg")
                }
                
                // 性格和故事卡片 - 始终显示
                infoCard(title: String(localized: "Personality & Story")) {
                    // 性格部分
                    infoRow(label: String(localized: "Personality"), value: pet.personality?.isEmpty ?? true ? String(localized: "Not set") : pet.personality ?? "")
                    
                    // 故事部分
                    infoRow(label: String(localized: "Story with Owner"), value: pet.story?.isEmpty ?? true ? String(localized: "Not set") : pet.story ?? "")
                }
            }
            .padding()
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 视图出现时的初始化逻辑
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit Pet", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete Pet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(accentColor)
                        .font(.system(size: 18))
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPetView(pet: pet)
        }
        .sheet(isPresented: $showingPhotosSheet) {
            PetPhotosView(pet: pet)
        }
        .customConfirmAlert(
            title: String(localized: "delete_pet.title"),
            message: String(localized: "delete_pet.message"),
            isPresented: $showingDeleteAlert,
            confirmTitle: String(localized: "delete_pet.confirm"),
            confirmAction: {
                deletePet()
            },
            isDestructive: true
        )
    }
    
    // 宠物头像部分
    private var petAvatarSection: some View {
        VStack {
            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 3)
                    )
            } else {
                // v1.1.0: 使用 PetType 扩展的 defaultImageName 获取正确的默认图标
                Image(pet.petType?.defaultImageName ?? "pet_cat")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 3)
                    )
            }
            
                    Text(pet.name)
                        .font(.appLargeTitle)
                        .foregroundColor(textColor)
        }
    }
    
    // 信息卡片容器
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.appHeadline)
                .foregroundColor(accentColor)
                .padding(.bottom, 4)
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 信息行
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(labelColor)
            Spacer()
            Text(value)
                .font(.appCallout)
                .foregroundColor(textColor)
        }
        .padding(.vertical, 4)
    }
    
    // 照片卡片
    private var photosCard: some View {
        let petPhotos = getAllPhotosForPet()
        let photoCount = petPhotos.count
        let latestPhotos = Array(petPhotos.prefix(3))
        
        return infoCard(title: String(localized: "Photos")) {
            if photoCount == 0 {
                // 无照片状态
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("No photos yet")
                        .font(.appBody)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                // 显示最新的3张照片
                HStack(spacing: 12) {
                    // 照片缩略图
                    ForEach(latestPhotos, id: \.id) { photo in
                        if let uiImage = UIImage(data: photo.photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // 如果照片不足3张，用占位符填充
                    ForEach(0..<(3 - latestPhotos.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 20))
                            )
                    }
                    
                    Spacer()
                    
                    // 照片数量和箭头
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: NSLocalizedString("photos_count %d", comment: ""), photoCount))
                            .font(.appCallout)
                            .foregroundColor(textColor)
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(accentColor)
                            .font(.system(size: 14))
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingPhotosSheet = true
                }
            }
        }
    }
    
    // 获取宠物的所有照片
    private func getAllPhotosForPet() -> [RecordPhoto] {
        guard let records = pet.records else { return [] }
        
        return records.compactMap { record in
            record.photos ?? []
        }.flatMap { $0 }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    // 删除宠物 - 使用级联删除方法处理关系问题
    private func deletePet() {
        PetService.cascadeDeletePet(pet: pet, modelContext: modelContext)
        
        // 延迟关闭，确保删除操作先完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}
