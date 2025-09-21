import SwiftUI
import SwiftData
import PhotosUI
import OSLog

/// 添加记录主流程视图
struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: RecordViewModel
    
    // 照片限制弹窗状态
    @State private var showingProInfoAlert = false
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AddRecordView")
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
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
                        AddRecordPetAndEventView(viewModel: viewModel)
                    case .recordDetails:
                        AddRecordInfoView(viewModel: viewModel)
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
        }
        .onAppear {
            logger.info("📱 AddRecordView onAppear - fullScreenCover模式已启动")
        }
    }
}

#Preview {
    AddRecordView(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self, RecordPhoto.self)))
} 
