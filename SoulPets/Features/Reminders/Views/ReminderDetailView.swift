import SwiftUI
import SwiftData
import OSLog

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let reminder: Reminder
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "ReminderDetail")
    
    // 颜色定义 - 与RecordDetailView保持一致
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
                        
                        // 情境卡片 - 合并时间信息和宠物信息
                        contextCard
                        
                        // 重复规则卡片
                        if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                            repeatRuleCard
                        }
                        
                        // 备注卡片
                        notesCard
                        
                        // 完成历史卡片
                        completionHistoryCard
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "Reminder Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditView = true
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
            .sheet(isPresented: $showingEditView) {
                AddEditReminderView(reminderToEdit: reminder, modelContext: modelContext)
            }
            .alert(String(localized: "Delete Reminder"), isPresented: $showingDeleteAlert) {
                Button(String(localized: "Cancel"), role: .cancel) { }
                Button(String(localized: "Delete"), role: .destructive) {
                    deleteReminder()
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete this reminder? This action cannot be undone."))
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 标签信息卡片
    private var tagInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(reminder.tag.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.name)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text(String(localized: LocalizedStringResource(stringLiteral: reminder.tag.category.rawValue)))
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
    
    /// 情境卡片 - 合并时间信息和宠物信息
    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 时间信息区域
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Date & Time"))
                    .font(.appHeadline)
                    .foregroundColor(textColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    // 日期 - 作为视觉重点
                    Text(formattedDateOnly(reminder.startDate))
                        .font(.appBody)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    // 时间 - 次要信息
                    Text(formattedTimeOnly(reminder.startDate))
                        .font(.appCaption)
                        .foregroundColor(labelColor)
                }
            }
            
            // 宠物信息区域 - 与RecordDetailView保持一致
            if let pets = reminder.pets, !pets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pets.count == 1 ? String(localized: "Pet") : String(localized: "Pets"))
                        .font(.appHeadline)
                        .foregroundColor(textColor)
                    
                    // 使用与RecordDetailView相同的宠物展示逻辑
                    petInfoSection(pets: pets)
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
    
    /// 重复规则卡片
    private var repeatRuleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Repeat Settings"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            HStack(spacing: 8) {
                Image(systemName: "repeat")
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                
                Text(reminder.repeatRuleText ?? String(localized: "No repeat"))
                    .font(.appBody)
                    .foregroundColor(textColor)
                
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
    
    /// 备注卡片
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Notes"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            VStack(alignment: .leading, spacing: 8) {
                if let notes = reminder.notes, !notes.isEmpty {
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
        .frame(minHeight: 100) // 整个卡片的最小高度
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// 完成历史卡片
    private var completionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Completion History"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            if let completions = reminder.completions, !completions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(completions.sorted(by: { $0.completionDate > $1.completionDate }), id: \.id) { completion in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.appSuccess)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formattedDateOnly(completion.completionDate))
                                    .font(.appBody)
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor)
                                
                                Text(formattedTimeOnly(completion.completionDate))
                                    .font(.appCaption)
                                    .foregroundColor(labelColor)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text(String(localized: "No completion history yet"))
                    .font(.appBody)
                    .foregroundColor(labelColor)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - 宠物信息展示 - 与RecordDetailView保持一致
    
    /// 宠物信息区域 - 与RecordDetailView保持一致
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
                
                Image(pet.petType.defaultImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.7, height: size * 0.7)
            }
        }
    }
    
    // MARK: - 辅助方法
    
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
    
    // MARK: - 删除提醒
    private func deleteReminder() {
        // 移除相关通知
        NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
        
        // 从数据库删除
        modelContext.delete(reminder)
        
        do {
            try modelContext.save()
            logger.info("成功删除提醒")
            dismiss()
        } catch {
            logger.error("删除提醒失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, Reminder.self, Tag.self, ReminderCompletion.self, configurations: config)
    
    // 创建示例数据
    let tag = Tag(
        code: "health.vaccine",
        name: "Vaccine",
        iconName: "syringe",
        category: .routineHealth,
        associatedPetTypes: [.cat, .dog]
    )
    
    let pet = Pet(
        name: "Mimi",
        petType: .cat,
        breed: "British Shorthair",
        gender: .female,
        isNeutered: true,
        birthday: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    )
    
    let reminder = Reminder(
        startDate: Date(),
        notes: "Annual vaccination",
        repeatInterval: 1,
        repeatUnit: .yearly,
        tag: tag,
        pets: [pet]
    )
    
    container.mainContext.insert(tag)
    container.mainContext.insert(pet)
    container.mainContext.insert(reminder)
    
    return ReminderDetailView(reminder: reminder)
        .modelContainer(container)
} 