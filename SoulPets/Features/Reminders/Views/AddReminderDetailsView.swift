import SwiftUI
import SwiftData
import OSLog

/// 添加提醒 - 提醒详情信息视图
struct AddReminderDetailsView: View {
    @ObservedObject var viewModel: AddEditReminderViewModel
    
    // 键盘工具栏相关状态
    @FocusState private var isNotesFieldFocused: Bool
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "AddReminderDetailsView")
    
    // 颜色定义 - 与Record模块保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let textColor = Color(red: 0.25, green: 0.25, blue: 0.25)
    private let labelColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { // 增加间距让布局更呼吸
                // 日期和时间选择器
                dateTimeSection
                
                // 重复设置
                repeatSettingsSection
                
                // 备注输入框
                notesSection
            }
            .padding(.vertical, 20) // 增加垂直padding
        }
        .toolbar {
            // 🔧 键盘工具栏完成按钮（仅在有焦点时显示）
            if isNotesFieldFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        logger.info("🔧 AddReminderDetails键盘工具栏完成按钮被点击")
                        logger.info("🔧 当前焦点状态 - Notes: \(isNotesFieldFocused)")
                        
                        // 关闭键盘
                        isNotesFieldFocused = false
                        
                        // 备用方法：使用 UIApplication 方式关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        logger.info("🔧 键盘关闭操作已执行")
                    }
                    .foregroundColor(accentColor)
                    .onAppear {
                        logger.info("🔧 AddReminderDetails Done按钮已创建")
                    }
                }
            }
        }
        .onChange(of: isNotesFieldFocused) { oldValue, newValue in
            logger.info("📝 AddReminderDetails Notes焦点状态变化: \(oldValue) -> \(newValue)")
        }
        .onAppear {
            logger.info("📱 AddReminderDetailsView onAppear - 键盘工具栏应该已加载")
        }
    }
    
    // MARK: - 子视图组件
    
    /// 日期和时间选择器部分 - 与Record模块保持一致的设计风格
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Date & Time"))
                .font(.appHeadline)
                .foregroundColor(textColor)
            
            DatePicker("", selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorScheme(.light)
                // 👇 与Record模块保持一致的样式
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
    
    /// 重复设置部分 - 情感化优化
    private var repeatSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Repeat Settings"))
                .font(.appHeadline) // 统一醒目的标题字体
                .foregroundColor(textColor)
            
            VStack(spacing: 16) {
                // 重复开关
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Repeat"))
                            .font(.appBody)
                            .foregroundColor(textColor)
                        if !viewModel.isRepeating {
                            Text(String(localized: "One-time reminder"))
                                .font(.appCaption2)
                                .foregroundColor(labelColor.opacity(0.7))
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.isRepeating)
                        .tint(accentColor)
                        .scaleEffect(0.9) // 稍微缩小开关以配合整体设计
                }
                
                // 重复间隔设置 - 只在开启重复时显示
                if viewModel.isRepeating {
                    VStack(spacing: 12) {
                        // 分隔线
                        Divider()
                            .background(labelColor.opacity(0.2))
                        
                        HStack {
                            Text(String(localized: "Every"))
                                .font(.appBody)
                                .foregroundColor(textColor)
                            
                            Spacer()
                            
                            // 间隔数字选择器
                            Menu {
                                ForEach(1...30, id: \.self) { interval in
                                    Button("\(interval)") {
                                        viewModel.setRepeatInterval(interval)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(viewModel.repeatInterval)")
                                        .font(.appBody)
                                        .foregroundColor(accentColor)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(accentColor)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(accentColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // 时间单位选择器
                            Menu {
                                ForEach(RepeatUnit.allCases, id: \.self) { unit in
                                    Button(String(localized: "repeat_unit.\(unit.rawValue.lowercased())")) {
                                        viewModel.setRepeatUnit(unit)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(String(localized: "repeat_unit.\(viewModel.repeatUnit.rawValue.lowercased())"))
                                        .font(.appBody)
                                        .foregroundColor(accentColor)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(accentColor)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(accentColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // 重复规则预览 - 情感化文案
                        if !viewModel.repeatRuleText.isEmpty {
                            HStack {
                                Image(systemName: "repeat")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(accentColor.opacity(0.7))
                                Text(viewModel.repeatRuleText)
                                    .font(.appCaption)
                                    .foregroundColor(labelColor)
                                    .italic()
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isRepeating)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal)
    }
    
    /// 备注输入框部分 - 与Record模块保持一致的情感化设计
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
                TextEditor(text: $viewModel.notes)
                    .foregroundColor(textColor)
                    .frame(minHeight: 100)
                    .padding()
                    .background(Color.clear)
                    .colorScheme(.light)
                    .focused($isNotesFieldFocused)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                logger.info("📝 AddReminderDetails Notes TextEditor simultaneousGesture 触发")
                            }
                    )
                
                // 情感化占位符 - 针对提醒场景优化
                if viewModel.notes.isEmpty {
                    Text(String(localized: "Any special notes for this reminder?"))
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
}

#Preview {
    AddReminderDetailsView(viewModel: AddEditReminderViewModel())
}
