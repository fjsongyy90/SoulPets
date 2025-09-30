import UIKit
import OSLog

/// 键盘预热器 - 在启动时预加载键盘以提升首次弹出性能
final class KeyboardPrewarmer {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "KeyboardPrewarmer")
    /// 单例
    static let shared = KeyboardPrewarmer()
    
    private var isPrewarmed = false
    
    // ✨ 核心修改 1 of 3: 持有一个对“幽灵窗口”的引用 ✨
    private var prewarmWindow: UIWindow?
    
    private init() {}
    
    /// 预热键盘 - 在启动页调用
    func prewarmKeyboard() {
        guard !isPrewarmed else {
            logger.info("⌨️ 键盘已预热，跳过")
            return
        }
        
        logger.info("⌨️ 开始预热键盘...")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // ✨ 核心修改 2 of 3: 创建并配置一个不可见的幽灵窗口 ✨
            let window = UIWindow(frame: .zero)
            window.alpha = 0
            window.isHidden = true
            // 持有对窗口的强引用，防止被立即释放
            self.prewarmWindow = window
            
            // 创建一个不可见的临时输入框
            let textField = UITextField(frame: .zero)
            textField.alpha = 0
            textField.isEnabled = false
            
            // 将输入框添加到我们新的幽灵窗口中
            self.prewarmWindow?.addSubview(textField)
            
            // 激活键盘（触发键盘资源加载）
            // 因为 textField 所在的窗口是不可见的，所以这个操作不会影响主窗口的布局
            textField.becomeFirstResponder()
            
            // 短暂延迟后关闭键盘并清理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textField.resignFirstResponder()
                
                // 再延迟一点确保键盘完全隐藏后再清理
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    textField.removeFromSuperview()
                    
                    // ✨ 核心修改 3 of 3: 释放对幽灵窗口的引用，让其被销毁 ✨
                    self.prewarmWindow = nil
                    
                    self.isPrewarmed = true
                    self.logger.info("✅ 键盘预热完成")
                }
            }
        }
    }
    
    /// 重置预热状态（用于测试）
    func reset() {
        isPrewarmed = false
        prewarmWindow = nil // 确保窗口也被清理
        logger.info("🔄 键盘预热状态已重置")
    }
}
