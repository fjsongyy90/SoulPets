import SwiftUI
import SwiftData

struct AddEditReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = AddEditReminderViewModel()
    @Query private var allPets: [Pet]
    
    let reminderToEdit: Reminder?
    
    init(reminderToEdit: Reminder? = nil) {
        self.reminderToEdit = reminderToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 宠物选择部分
                petSelectionSection
                
                // 标签选择部分
                tagSelectionSection
                
                // 日期时间部分
                dateTimeSection
                
                // 重复设置部分
                repeatSection
                
                // 备注部分
                notesSection
            }
            .navigationTitle(viewModel.isEditing ? String(localized: "reminder.edit") : String(localized: "reminder.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.save")) {
                        Task {
                            if await viewModel.saveReminder(modelContext: modelContext) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .alert(
                String(localized: "error.title"),
                isPresented: .constant(viewModel.errorMessage != nil)
            ) {
                Button(String(localized: "common.ok")) {
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
    
    // MARK: - 宠物选择部分
    private var petSelectionSection: some View {
        Section {
            Button(action: { viewModel.showingPetSelection = true }) {
                HStack {
                    Text(String(localized: "reminder.select_pets"))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(viewModel.selectedPetsText)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
        } header: {
            Text(String(localized: "reminder.pets"))
        }
        .sheet(isPresented: $viewModel.showingPetSelection) {
            PetSelectionView(
                selectedPets: $viewModel.selectedPets,
                allPets: allPets
            ) {
                viewModel.loadAvailableTags(from: modelContext)
            }
        }
    }
    
    // MARK: - 标签选择部分
    private var tagSelectionSection: some View {
        Section {
            Button(action: { viewModel.showingTagSelection = true }) {
                HStack {
                    Text(String(localized: "reminder.select_tag"))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let tag = viewModel.selectedTag {
                        HStack(spacing: 8) {
                            Image(systemName: tag.iconName)
                                .foregroundColor(.accentColor)
                            
                            Text(tag.name)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(String(localized: "reminder.no_tag_selected"))
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.selectedPets.isEmpty)
        } header: {
            Text(String(localized: "reminder.event_type"))
        } footer: {
            if viewModel.selectedPets.isEmpty {
                Text(String(localized: "reminder.select_pets_first"))
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $viewModel.showingTagSelection) {
            TagSelectionView(
                selectedTag: $viewModel.selectedTag,
                availableTags: viewModel.availableTags
            )
        }
    }
    
    // MARK: - 日期时间部分
    private var dateTimeSection: some View {
        Section {
            DatePicker(
                String(localized: "reminder.start_date"),
                selection: $viewModel.startDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        } header: {
            Text(String(localized: "reminder.timing"))
        }
    }
    
    // MARK: - 重复设置部分
    private var repeatSection: some View {
        Section {
            Toggle(String(localized: "reminder.repeat"), isOn: $viewModel.isRepeating)
            
            if viewModel.isRepeating {
                HStack {
                    Text(String(localized: "reminder.every"))
                    
                    Spacer()
                    
                    Picker(String(localized: "reminder.interval"), selection: $viewModel.repeatInterval) {
                        ForEach(1...30, id: \.self) { interval in
                            Text("\(interval)").tag(interval)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker(String(localized: "reminder.unit"), selection: $viewModel.repeatUnit) {
                        ForEach(RepeatUnit.allCases, id: \.self) { unit in
                            Text(String(localized: "repeat_unit.\(unit.rawValue.lowercased())"))
                                .tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        } header: {
            Text(String(localized: "reminder.repeat_settings"))
        } footer: {
            if viewModel.isRepeating {
                Text(viewModel.repeatRuleText)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 备注部分
    private var notesSection: some View {
        Section {
            TextField(
                String(localized: "reminder.notes_placeholder"),
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        } header: {
            Text(String(localized: "reminder.notes"))
        }
    }
}

// MARK: - 宠物选择视图
struct PetSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPets: [Pet]
    let allPets: [Pet]
    let onSelectionChanged: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allPets, id: \.id) { pet in
                    HStack {
                        // 宠物头像
                        if let avatarData = pet.avatar, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: pet.petType == .cat ? "cat.fill" : "dog.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .frame(width: 40, height: 40)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pet.name)
                                .font(.headline)
                            
                            Text(pet.breed)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPets.contains(where: { $0.id == pet.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePetSelection(pet)
                    }
                }
            }
            .navigationTitle(String(localized: "reminder.select_pets"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func togglePetSelection(_ pet: Pet) {
        if selectedPets.contains(where: { $0.id == pet.id }) {
            selectedPets.removeAll { $0.id == pet.id }
        } else {
            selectedPets.append(pet)
        }
        onSelectionChanged()
    }
}

// MARK: - 标签选择视图
struct TagSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTag: Tag?
    let availableTags: [Tag]
    
    private var groupedTags: [TagCategory: [Tag]] {
        Dictionary(grouping: availableTags) { $0.category }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TagCategory.allCases, id: \.self) { category in
                    if let tags = groupedTags[category], !tags.isEmpty {
                        Section(header: Text(String(localized: "tag_category.\(category.rawValue.lowercased())"))) {
                            ForEach(tags, id: \.id) { tag in
                                HStack {
                                    Image(systemName: tag.iconName)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(tag.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if selectedTag?.id == tag.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTag = tag
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "reminder.select_tag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddEditReminderView()
        .modelContainer(for: [Pet.self, Reminder.self, Tag.self])
} 