import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userSettings: [UserSettings]
    
    @State private var showingLanguageAlert = false
    @State private var selectedAppearance: AppearanceMode = .system
    
    private var currentSettings: UserSettings {
        userSettings.first ?? UserSettings()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 通用设置卡片
                    generalSettingsCard
                    
                    // MARK: - 支持与反馈卡片
                    supportFeedbackCard
                    
                    // MARK: - 关于卡片
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color(hex: "FDFBF8"))
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "E5B487"))
                            .font(.title2)
                    }
                }
            }
        }
        .onAppear {
            selectedAppearance = currentSettings.appearance
        }
        .alert(String(localized: "settings.language.coming_soon.title"), isPresented: $showingLanguageAlert) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.language.coming_soon.message"))
        }
    }
    
    // MARK: - 通用设置卡片
    private var generalSettingsCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.general.title"))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 外观设置
                SettingsRowView(
                    icon: "paintbrush",
                    title: String(localized: "settings.general.appearance"),
                    showChevron: false
                ) {
                    appearancePicker
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 外观选择器
    private var appearancePicker: some View {
        Picker(String(localized: "settings.general.appearance"), selection: $selectedAppearance) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Text(String(localized: "settings.appearance.\(mode.rawValue.lowercased())"))
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedAppearance) { _, newValue in
            updateAppearance(newValue)
        }
    }
    
    // MARK: - 支持与反馈卡片
    private var supportFeedbackCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.support.title"))
                    .font(.headline)
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 关于卡片
    private var aboutCard: some View {
        VStack(spacing: 0) {
            // 卡片标题
            HStack {
                Text(String(localized: "settings.about.title"))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 设置项列表
            VStack(spacing: 1) {
                // 隐私政策
                SettingsRowView(
                    icon: "hand.raised",
                    title: String(localized: "settings.about.privacy_policy"),
                    showChevron: true,
                    action: {
                        SettingsService.openPrivacyPolicy()
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 私有方法
    private func updateAppearance(_ appearance: AppearanceMode) {
        let settings = currentSettings
        settings.appearance = appearance
        settings.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save appearance setting: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
} 