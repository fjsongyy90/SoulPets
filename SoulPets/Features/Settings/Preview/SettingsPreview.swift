import SwiftUI

// MARK: - 设置页预览
#Preview("设置页面") {
    SettingsView()
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