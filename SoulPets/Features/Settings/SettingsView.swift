import SwiftUI
import SwiftData
import os.log

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var showingLanguageAlert = false
    @State private var selectedAppearance: AppearanceMode = .system
    
    // Debug功能相关状态
    @State private var showingResetDataAlert = false
    @State private var showingResetOptionsSheet = false
    @State private var selectedResetOptions: Set<SettingsService.ResetDataOption> = []
    @State private var showingResetSuccessAlert = false
    @State private var showingPrivacyPromiseSheet = false
    
    // 颜色定义
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15) // #E5B487
    
    // 适应性强调色 - 在深色模式下使用更亮的版本
    private var adaptiveAccentColor: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.90, green: 0.71, blue: 0.53, alpha: 1.0) // 深色模式：更亮的版本
            default:
                return UIColor(red: 0.60, green: 0.35, blue: 0.15, alpha: 1.0) // 浅色模式：原始棕褐色
            }
        })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 通用设置卡片
                    generalSettingsCard
                    
                    // MARK: - 支持与反馈卡片
                    supportFeedbackCard

                    // MARK: - 数据与隐私卡片
                    dataPrivacyCard
                    
                    // MARK: - Debug卡片（仅Debug模式）
                    if SettingsService.isDebugMode {
                        debugCard
                    }
                    
                    // MARK: - 关于卡片
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color(.systemBackground)) // 使用系统背景色，适应深色模式
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .foregroundColor(adaptiveAccentColor) // 使用适应性强调色，确保在深色模式下也清晰可见
                    .font(.body.weight(.medium))
                }
            }
        }
        .onAppear {
            // 确保选中的外观模式与当前设置一致
            selectedAppearance = userSettings.appearance
            // 应用当前的外观设置到窗口
            applyAppearanceToWindow(userSettings.appearance)
        }
        .alert(String(localized: "settings.language.coming_soon.title"), isPresented: $showingLanguageAlert) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.language.coming_soon.message"))
        }
        .sheet(isPresented: $showingResetOptionsSheet) {
            resetDataOptionsSheet
        }
        .alert(String(localized: "settings.debug.reset.confirm.title"), isPresented: $showingResetDataAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                selectedResetOptions = []
            }
            Button(String(localized: "settings.debug.reset.confirm.action"), role: .destructive) {
                performDataReset()
            }
        } message: {
            Text(String(localized: "settings.debug.reset.confirm.message"))
        }
        .alert(String(localized: "settings.debug.reset.success.title"), isPresented: $showingResetSuccessAlert) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.debug.reset.success.message"))
        }
        .sheet(isPresented: $showingPrivacyPromiseSheet) {
            privacyPromiseView
        }
    }
    
    // MARK: - 通用设置卡片
    private var generalSettingsCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.general.title"))
                    .font(.appHeadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 外观设置 - 使用自定义组件
                VStack(spacing: 0) {
                    // 标题行
                    HStack(spacing: 12) {
                        Image(systemName: "paintbrush")
                            .font(.title3)
                            .foregroundColor(adaptiveAccentColor) // 使用适应性强调色
                            .frame(width: 24, height: 24)
                        
                        Text(String(localized: "settings.general.appearance"))
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // 外观选择器
                    customAppearancePicker
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // 通知设置
                SettingsRowView(
                    icon: "bell",
                    title: String(localized: "settings.general.notifications"),
                    showChevron: true,
                    action: {
                        SettingsService.openNotificationSettings()
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // 语言设置
                SettingsRowView(
                    icon: "globe",
                    title: String(localized: "settings.general.language"),
                    rightText: String(localized: "settings.general.language.current"),
                    showChevron: true,
                    action: {
                        showingLanguageAlert = true
                    }
                )
            }
            .padding(.bottom, 16)
        }
        .background(Color(.secondarySystemBackground)) // 使用系统二级背景色，适应深色模式
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 自定义外观选择器
    private var customAppearancePicker: some View {
        HStack(spacing: 8) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button(action: {
                    selectedAppearance = mode
                    updateAppearance(mode)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconForAppearance(mode))
                            .font(.title2)
                            .foregroundColor(selectedAppearance == mode ? .white : adaptiveAccentColor) // 使用适应性强调色
                        
                        Text(mode.rawValue)
                            .font(.caption)
                            .foregroundColor(selectedAppearance == mode ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedAppearance == mode ? adaptiveAccentColor : Color(.tertiarySystemBackground)) // 使用系统颜色
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(adaptiveAccentColor.opacity(0.3), lineWidth: 1) // 使用适应性强调色
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 支持与反馈卡片
    private var supportFeedbackCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.support.title"))
                    .font(.appHeadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 功能建议
                SettingsRowView(
                    icon: "lightbulb",
                    title: String(localized: "settings.support.suggest_feature"),
                    showChevron: true,
                    action: {
                        SettingsService.suggestFeature()
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // App Store 评分
                SettingsRowView(
                    icon: "star",
                    title: String(localized: "settings.support.rate_app"),
                    showChevron: true,
                    action: {
                        SettingsService.rateApp()
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // 分享应用
                SettingsRowView(
                    icon: "square.and.arrow.up",
                    title: String(localized: "settings.support.share_app"),
                    showChevron: true,
                    action: {
                        SettingsService.shareApp()
                    }
                )
            }
            .padding(.bottom, 16)
        }
        .background(Color(.secondarySystemBackground)) // 使用系统二级背景色，适应深色模式
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Debug卡片
    private var debugCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.debug.title"))
                    .font(.appHeadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 重置数据
                SettingsRowView(
                    icon: "arrow.clockwise",
                    title: String(localized: "settings.debug.reset_data"),
                    showChevron: true,
                    action: {
                        selectedResetOptions = [] // 清空已选选项
                        showingResetOptionsSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // 版本信息
                SettingsRowView(
                    icon: "info.circle",
                    title: String(localized: "settings.about.version"),
                    rightText: SettingsService.appVersion,
                    showChevron: false
                )
            }
            .padding(.bottom, 16)
        }
        .background(Color(.secondarySystemBackground)) // 使用系统二级背景色，适应深色模式
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 数据与隐私卡片
    private var dataPrivacyCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundColor(adaptiveAccentColor)
                Text(String(localized: "settings.privacy.title"))
                    .font(.appHeadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 核心口号
            HStack {
                Text(String(localized: "settings.privacy.slogan"))
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.leading, 16)
            
            // 我们的隐私承诺
            SettingsRowView(
                icon: "lock.shield",
                title: String(localized: "settings.privacy.promise"),
                showChevron: true,
                action: {
                    showingPrivacyPromiseSheet = true
                }
            )
            
            Divider()
                .padding(.leading, 52)
            
            // 隐私政策
            SettingsRowView(
                icon: "doc.text",
                title: String(localized: "settings.about.privacy_policy"),
                showChevron: true,
                action: {
                    SettingsService.openPrivacyPolicy()
                }
            )
            .padding(.bottom, 16)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 隐私承诺详情页
    private var privacyPromiseView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 引言
                    Text(String(localized: "settings.privacy.promise.intro"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // 100% 本地存储
                    privacyPromiseItem(
                        icon: "📱🔒",
                        title: String(localized: "settings.privacy.promise.local_storage.title"),
                        description: String(localized: "settings.privacy.promise.local_storage.description")
                    )
                    
                    // 没有账号，没有追踪
                    privacyPromiseItem(
                        icon: "👤🚫",
                        title: String(localized: "settings.privacy.promise.no_tracking.title"),
                        description: String(localized: "settings.privacy.promise.no_tracking.description")
                    )
                    
                    // iCloud 是您的私人保险箱
                    privacyPromiseItem(
                        icon: "☁️✔️",
                        title: String(localized: "settings.privacy.promise.icloud.title"),
                        description: String(localized: "settings.privacy.promise.icloud.description")
                    )
                    
                    // 离线可用
                    privacyPromiseItem(
                        icon: "🌐🔌",
                        title: String(localized: "settings.privacy.promise.offline.title"),
                        description: String(localized: "settings.privacy.promise.offline.description")
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "settings.privacy.promise.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        showingPrivacyPromiseSheet = false
                    }
                    .foregroundColor(adaptiveAccentColor)
                }
            }
        }
    }
    
    // 隐私承诺项目
    private func privacyPromiseItem(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text(icon)
                    .font(.title)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }
    
    // MARK: - 关于卡片
    private var aboutCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.about.title"))
                    .font(.appHeadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 服务条款
                SettingsRowView(
                    icon: "doc.text",
                    title: String(localized: "settings.about.terms_of_service"),
                    showChevron: true,
                    action: {
                        SettingsService.openTermsOfService()
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // 版本信息
                SettingsRowView(
                    icon: "info.circle",
                    title: String(localized: "settings.about.version"),
                    rightText: SettingsService.appVersion,
                    showChevron: false
                )
            }
            .padding(.bottom, 16)
        }
        .background(Color(.secondarySystemBackground)) // 使用系统二级背景色，适应深色模式
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 私有方法
    private func updateAppearance(_ appearance: AppearanceMode) {
        // 更新UserSettings
        userSettings.appearance = appearance
        selectedAppearance = appearance
        
        // 立即应用外观更改
        DispatchQueue.main.async {
            applyAppearanceToWindow(appearance)
        }
    }
    
    private func applyAppearanceToWindow(_ appearance: AppearanceMode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        switch appearance {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func iconForAppearance(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .system:
            return "gear"
        }
    }
    
    // MARK: - Debug相关方法
    
    /// 重置数据选项选择Sheet
    private var resetDataOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 说明文本
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings.debug.reset.description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Text(String(localized: "settings.debug.reset.warning"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color(.systemBackground)) // 使用系统背景色，适应深色模式
                
                // 选项列表
                List {
                    ForEach(SettingsService.ResetDataOption.allCases, id: \.self) { option in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.localizedTitle)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedResetOptions.contains(option) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(adaptiveAccentColor) // 使用适应性强调色
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedResetOptions.contains(option) {
                                selectedResetOptions.remove(option)
                            } else {
                                selectedResetOptions.insert(option)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(String(localized: "settings.debug.reset_data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        showingResetOptionsSheet = false
                        selectedResetOptions = []
                    }
                    .foregroundColor(adaptiveAccentColor) // 使用适应性强调色
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "settings.debug.reset.confirm")) {
                        showingResetOptionsSheet = false
                        showingResetDataAlert = true
                    }
                    .foregroundColor(selectedResetOptions.isEmpty ? .gray : .red)
                    .disabled(selectedResetOptions.isEmpty)
                }
            }
        }
    }
    
    /// 执行数据重置
    private func performDataReset() {
        Task {
            do {
                // 在后台线程执行数据重置
                try await Task.sleep(nanoseconds: 100_000_000) // 短暂延迟确保UI更新
                
                // 执行重置操作
                SettingsService.resetData(options: selectedResetOptions, modelContext: modelContext)
                
                // 在主线程更新UI
                await MainActor.run {
                    selectedResetOptions = []
                    showingResetSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    selectedResetOptions = []
                    // 可以在这里添加错误提示
                    print("重置数据时出错: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 