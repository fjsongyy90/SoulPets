import SwiftUI
import SwiftData
import PhotosUI
import OSLog

/// 添加记录 - 记录详情信息视图
struct AddRecordInfoView: View {
    @ObservedObject var viewModel: RecordViewModel
    
    // 照片选择器状态
    @State private var selectedItems: [PhotosPickerItem] = []
    
    // 照片限制弹窗状态
    @State private var showingProInfoAlert = false
    
    // 键盘工具栏相关状态
    @FocusState private var isNotesFieldFocused: Bool
    @FocusState private var isCostFieldFocused: Bool
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AddRecordInfoView")
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) { // 增加间距让布局更呼吸
                    // 日期和时间选择器
                    dateTimeSection
                    
                    // 备注输入框
                    notesSection
                    
                    // 照片选择器
                    photosSection
                    
                    // 花费输入框（为未来功能预留）
                    costSection
                }
                .padding(.vertical, 20) // 增加垂直padding
            }
            
            // 🔧 备用方案：浮动的Done按钮（当键盘激活时显示）
            if isNotesFieldFocused || isCostFieldFocused {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Done") {
                            logger.info("🔧 浮动Done按钮被点击")
                            logger.info("🔧 当前焦点状态 - Notes: \(isNotesFieldFocused), Cost: \(isCostFieldFocused)")
                            
                            // 关闭键盘
                            isNotesFieldFocused = false
                            isCostFieldFocused = false
                            
                            // 备用方法：使用 UIApplication 方式关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            logger.info("🔧 键盘关闭操作已执行")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .onAppear {
                            logger.info("🔍 浮动Done按钮已显示")
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: isNotesFieldFocused || isCostFieldFocused)
            }
        }
        // 都能继承这个更深、对比度更高的颜色。
        .accentColor(Color(red: 0.60, green: 0.35, blue: 0.15))
        // 🔧 修复：为 fullScreenCover 模式添加键盘工具栏
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Text("Debug: Toolbar Loaded")
                        .font(.caption)
                        .foregroundColor(.red)
                        .onAppear {
                            logger.info("🛠️ 键盘工具栏视图已创建并显示")
                        }
                    
                    Spacer()
                    
                    Button(String(localized: "Done")) {
                        logger.info("🔧 键盘工具栏完成按钮被点击")
                        logger.info("🔧 当前焦点状态 - Notes: \(isNotesFieldFocused), Cost: \(isCostFieldFocused)")
                        
                        // 关闭键盘
                        isNotesFieldFocused = false
                        isCostFieldFocused = false
                        
                        // 备用方法：使用 UIApplication 方式关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        logger.info("🔧 键盘关闭操作已执行")
                    }
                    .foregroundColor(accentColor)
                    .onAppear {
                        logger.info("🔧 Done按钮已创建")
                    }
                }
            }
        }
        .onAppear {
            logger.info("📱 AddRecordInfoView onAppear - 键盘工具栏应该已加载")
            
            // 检查工具栏是否正确配置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                logger.info("🔍 延迟检查 - Notes焦点状态: \(isNotesFieldFocused), Cost焦点状态: \(isCostFieldFocused)")
            }
        }
        .onChange(of: isNotesFieldFocused) { oldValue, newValue in
            logger.info("📝 Notes焦点状态变化: \(oldValue) -> \(newValue)")
        }
        .onChange(of: isCostFieldFocused) { oldValue, newValue in
            logger.info("💰 Cost焦点状态变化: \(oldValue) -> \(newValue)")
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
    
    // MARK: - 子视图组件
    
    /// 日期和时间选择器部分 - 方案一：视觉优化
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Date & Time"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            DatePicker("", selection: $viewModel.recordDate)
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorScheme(.light)
                // 👇 主要修改在这里
                .padding(.horizontal, 12) // 给左右一些呼吸空间
                .padding(.vertical, 8)   // 给上下一些呼吸空间
                .background(
                    // 使用品牌强调色的微透明版本作为背景，更温暖
                    accentColor.opacity(0.05)
                )
                .cornerRadius(16) // 使用更大的圆角
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        // 使用品牌强调色的半透明版本作为边框，更柔和
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .accentColor(accentColor)
        }
        .padding(.horizontal)
    }
    
    /// 备注输入框部分 - 情感化优化
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Notes"))
                .font(.appHeadline) // 统一醒目的标题字体
                .foregroundColor(textColor)
            
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
                TextEditor(text: $viewModel.recordNotes)
                    .foregroundColor(textColor)
                    .frame(minHeight: 100)
                    .padding()
                    .background(Color.clear)
                    .colorScheme(.light)
                    .focused($isNotesFieldFocused)
                    .onTapGesture {
                        logger.info("📝 Notes TextEditor被点击，设置焦点")
                        logger.info("📝 点击前焦点状态: \(isNotesFieldFocused)")
                        isNotesFieldFocused = true
                        logger.info("📝 点击后焦点状态: \(isNotesFieldFocused)")
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            logger.info("📝 Notes TextEditor simultaneousGesture 触发")
                        }
                    )
                
                // 情感化占位符
                if viewModel.recordNotes.isEmpty {
                    Text("What's a sweet memory you made just now?")
                        .font(.appBody) // 使用温暖的字体样式
                        .foregroundColor(labelColor.opacity(0.7))
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .allowsHitTesting(false) // 允许点击穿透到TextEditor
                }
            }
        }
        .padding(.horizontal)
    }
    
    /// 照片选择器部分 - 情感化优化
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Photos"))
                    .font(.appHeadline) // 统一醒目的标题字体
                    .foregroundColor(textColor)
                
                Spacer()
                
                // 显示照片限制提示 - 精致字体
                if !UserPreferencesService.shared.isProMember {
                    HStack(spacing: 2) {
                        Text("Max")
                            .font(.appCaption2)
                            .foregroundColor(labelColor)
                        Text("\(UserPreferencesService.shared.maxPhotosPerRecord)")
                            .font(.appCaption2)
                            .fontWeight(.semibold) // 数字突出显示
                            .foregroundColor(labelColor)
                    }
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
                        .font(.appBody)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    // 情感化背景 - 温馨的邀请感
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 非会员限制提示 - 精致字体
            if !UserPreferencesService.shared.isProMember && viewModel.recordPhotos.count >= UserPreferencesService.shared.maxPhotosPerRecord {
                Text(String(localized: "Free version allows up to 2 photos per record. Upgrade to SoulPets Pro for unlimited photos."))
                    .font(.appFootnote) // Pro提示使用appFootnote
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
            
            // 已选照片预览
            if !viewModel.recordPhotos.isEmpty {
                photoPreviewSection
            }
        }
        .padding(.horizontal)
    }
    
    /// 照片预览部分
    private var photoPreviewSection: some View {
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
    
    /// 花费输入框部分 - 情感化优化（为未来功能预留）
    private var costSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Cost"))
                    .font(.appHeadline) // 统一醒目的标题字体
                    .foregroundColor(textColor)
                
                Button(action: {
                    showingProInfoAlert = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            ZStack(alignment: .leading) {
                // 背景容器
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // 输入框
                TextField("", text: $viewModel.recordCost)
                    .keyboardType(.decimalPad)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.clear)
                    .focused($isCostFieldFocused)
                    .onTapGesture {
                        logger.info("💰 Cost TextField被点击，设置焦点")
                        logger.info("💰 点击前焦点状态: \(isCostFieldFocused)")
                        isCostFieldFocused = true
                        logger.info("💰 点击后焦点状态: \(isCostFieldFocused)")
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            logger.info("💰 Cost TextField simultaneousGesture 触发")
                        }
                    )
                
                // 精致的占位符
                if viewModel.recordCost.isEmpty {
                    Text("0.00")
                        .foregroundColor(labelColor.opacity(0.6)) // 占位符使用labelColor
                        .font(.appBody)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AddRecordInfoView(viewModel: RecordViewModel(modelContext: ModelContext(try! ModelContainer(for: Pet.self, Record.self, Tag.self))))
}
