import SwiftUI
import SwiftData

// MARK: - 设置页预览
#Preview("设置页面") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserSettings.self, configurations: config)
    
    // 添加测试用户设置
    let userSettings = UserSettings(
        appearance: .system,
        userName: "测试用户",
        iCloudSyncEnabled: true
    )
    container.mainContext.insert(userSettings)
    
    return SettingsView()
        .modelContainer(container)
}

#Preview("设置行组件 - 基础") {
    VStack(spacing: 1) {
        SettingsRowView(
            icon: "bell",
            title: "Notifications",
            showChevron: true,
            action: {
                print("Notifications tapped")
            }
        )
        
        SettingsRowView(
            icon: "globe",
            title: "Language",
            rightText: "English",
            showChevron: true,
            action: {
                print("Language tapped")
            }
        )
        
        SettingsRowView(
            icon: "info.circle",
            title: "Version",
            rightText: "1.0.0",
            showChevron: false
        )
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(hex: "FDFBF8"))
}

#Preview("设置行组件 - 带内容") {
    VStack(spacing: 1) {
        SettingsRowView(
            icon: "paintbrush",
            title: "Appearance",
            showChevron: false
        ) {
            Picker("Appearance", selection: .constant(AppearanceMode.system)) {
                Text("Light").tag(AppearanceMode.light)
                Text("Dark").tag(AppearanceMode.dark)
                Text("System").tag(AppearanceMode.system)
            }
            .pickerStyle(.segmented)
        }
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(hex: "FDFBF8"))
} 