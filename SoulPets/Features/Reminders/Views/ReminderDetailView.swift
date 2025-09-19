import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let reminder: Reminder
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标签信息
                    tagInfoSection
                    
                    // 宠物信息
                    petsSection
                    
                    // 时间信息
                    timeInfoSection
                    
                    // 重复信息
                    if reminder.repeatInterval != nil && reminder.repeatUnit != nil {
                        repeatInfoSection
                    }
                    
                    // 备注
                    if let notes = reminder.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // 完成历史
                    completionHistorySection
                }
                .padding()
            }
            .navigationTitle(reminder.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(String(localized: "Edit")) {
                            showingEditView = true
                        }
                        
                        Divider()
                        
                        Button(String(localized: "Delete"), role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                AddEditReminderView(reminderToEdit: reminder, modelContext: modelContext)
            }
            .alert(
                String(localized: "reminder.delete_title"),
                isPresented: $showingDeleteAlert
            ) {
                Button(String(localized: "Delete"), role: .destructive) {
                    deleteReminder()
                }
                Button(String(localized: "Cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "reminder.delete_message"))
            }
        }
    }
    
    // MARK: - 标签信息部分
    private var tagInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(reminder.tag.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.tag.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(String(localized: "tag_category.\(reminder.tag.category.rawValue.lowercased())"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 宠物信息部分
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "reminder.associated_pets"))
                .font(.headline)
            
            if let pets = reminder.pets, !pets.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 12) {
                    ForEach(pets, id: \.id) { pet in
                        PetMiniCard(pet: pet)
                    }
                }
            } else {
                Text(String(localized: "reminder.no_pets"))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 时间信息部分
    private var timeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "reminder.timing"))
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)
                
                Text(reminder.startDate, style: .date)
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(.accentColor)
                
                Text(reminder.startDate, style: .time)
            }
            .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 重复信息部分
    private var repeatInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "reminder.repeat_settings"))
                .font(.headline)
            
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.accentColor)
                
                Text(reminder.repeatRuleText ?? String(localized: "reminder.no_repeat"))
                
                Spacer()
            }
            .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 备注部分
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "reminder.notes"))
                .font(.headline)
            
            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 完成历史部分
    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "reminder.completion_history"))
                .font(.headline)
            
            if let completions = reminder.completions, !completions.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(completions.sorted(by: { $0.completionDate > $1.completionDate }), id: \.id) { completion in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text(completion.completionDate, style: .date)
                                .font(.body)
                            
                            Spacer()
                            
                            Text(completion.completionDate, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text(String(localized: "reminder.no_completions"))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
    
    // MARK: - 删除提醒
    private func deleteReminder() {
        // 移除相关通知
        NotificationService.removeNotificationsForReminder(reminderId: reminder.id)
        
        // 从数据库删除
        modelContext.delete(reminder)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // TODO: 处理删除错误
            print("删除提醒失败: \(error)")
        }
    }
}

// MARK: - 宠物迷你卡片
struct PetMiniCard: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 8) {
            // 宠物头像
            if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(pet.petType == .cat ? "pet_cat" : "pet_dog")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            Text(pet.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground))
        )
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