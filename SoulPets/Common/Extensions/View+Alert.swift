import SwiftUI

/// 自定义 Alert 样式扩展
extension View {
    /// 显示带有自定义样式的确认Alert
    func customConfirmAlert(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        confirmAction: @escaping () -> Void,
        isDestructive: Bool = false
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button(confirmTitle, role: isDestructive ? .destructive : nil) {
                confirmAction()
            }
            .foregroundColor(isDestructive ? .red : Color(red: 0.60, green: 0.35, blue: 0.15))
            
            Button(cancelTitle, role: .cancel) {}
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
        } message: {
            Text(message)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
        }
    }
    
    /// 显示带有自定义样式的选择Alert
    func customChoiceAlert(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondaryAction: @escaping () -> Void = {}
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button(primaryTitle) {
                primaryAction()
            }
            .foregroundColor(Color(red: 0.60, green: 0.35, blue: 0.15))
            
            Button(secondaryTitle, role: .cancel) {
                secondaryAction()
            }
            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
        } message: {
            Text(message)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
        }
    }
} 