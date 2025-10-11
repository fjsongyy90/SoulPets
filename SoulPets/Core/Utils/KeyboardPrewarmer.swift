import UIKit
import OSLog

/// 键盘预热器 - 采用“侵入式”策略，尝试触发更深层的键盘加载和JIT编译
final class KeyboardPrewarmer {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "KeyboardPrewarmer")
    
    /// 单例
    static let shared = KeyboardPrewarmer()
    
    private var isPrewarmed = false
    
    // 持有一个对“幽灵窗口”的强引用，防止被过早释放
    private var prewarmWindow: UIWindow?
    
    private init() {}
    
    /// 执行侵入式预热
    func prewarmKeyboard() {
        // 防止重复执行
        guard !isPrewarmed else {
            logger.info("⌨️ 键盘已预热，跳过")
            return
        }
        isPrewarmed = true
        
        logger.info("⌨️ 开始执行“侵入式”键盘预热...")
        
        // 必须在主线程执行UI操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 1. 找到当前活跃的UIWindowScene
            // 这是让新窗口被系统“承认”的关键一步
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                self.logger.warning("❌ 未找到活跃的UIWindowScene，预热失败")
                return
            }

            // 2. 创建一个依附于该场景的窗口
            let window = UIWindow(windowScene: scene)
            
            // 3. 设置窗口为1x1像素，并将其放置在屏幕外，用户不会看到它
            window.frame = CGRect(x: 0, y: -1, width: 1, height: 1)
            
            // 4. 【核心改动】让窗口变为“可见”，这是欺骗系统进行JIT编译的关键
            window.isHidden = false
            
            // 持有它
            self.prewarmWindow = window

            // 创建一个临时的输入框
            let textField = UITextField(frame: .zero)
            window.addSubview(textField)
            
            // 激活键盘
            textField.becomeFirstResponder()

            // 5. 给予系统更长的响应时间后，再进行清理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                textField.resignFirstResponder()
                textField.removeFromSuperview()
                
                // 彻底销毁窗口
                self.prewarmWindow?.isHidden = true
                self.prewarmWindow = nil
                
                self.logger.info("✅ “侵入式”键盘预热完成")
            }
        }
    }
}
