import Photos
import PhotosUI
import OSLog

/// 照片服务预热器 - 在app启动时预先请求权限和初始化服务
final class PhotosPrewarmService {
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "PhotosPrewarm")
    
    /// 单例
    static let shared = PhotosPrewarmService()
    
    private var isPrewarmed = false
    
    private init() {}
    
    /// 预先检查照片权限并预加载服务（不主动请求权限）
    func prewarmPhotosAccess() {
        guard !isPrewarmed else {
            logger.info("📷 照片服务已预热，跳过")
            return
        }
        isPrewarmed = true
        
        logger.info("📷 开始预热照片服务...")
        
        // 在后台线程执行，不阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 只检查当前权限状态，不主动请求
            // 权限请求应该在用户点击PhotosPicker时自动触发，这样体验更好
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            switch status {
            case .notDetermined:
                self.logger.info("📷 照片权限未决定（将在用户选择照片时请求）")
                
            case .restricted:
                self.logger.warning("📷 照片权限受限（家长控制）")
                
            case .denied:
                self.logger.warning("📷 照片权限已被拒绝")
                
            case .authorized:
                self.logger.info("📷 照片权限已授权（完全访问）")
                
            case .limited:
                self.logger.info("📷 照片权限已授权（限制访问）")
                
            @unknown default:
                self.logger.warning("📷 未知的照片权限状态: \(status.rawValue)")
            }
            
            // 只有当权限已授权时才预加载，避免触发权限弹窗
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.preloadPhotoLibrary()
                }
            } else {
                self.logger.info("📷 照片服务预热完成（权限未授权，跳过预加载）")
            }
        }
    }
    
    /// 预加载照片库，触发系统服务初始化
    private func preloadPhotoLibrary() {
        // 创建一个最小的PHPickerConfiguration来预热系统
        // 这不会显示UI，只是让系统初始化相关服务
        let config = PHPickerConfiguration()
        _ = config.selectionLimit
        _ = config.filter
        
        logger.info("✅ 照片服务预热完成")
    }
    
    /// 日志记录权限状态
    private func logAuthorizationStatus(_ status: PHAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .notDetermined:
                self?.logger.info("📷 照片权限：未决定")
            case .restricted:
                self?.logger.warning("📷 照片权限：受限")
            case .denied:
                self?.logger.warning("📷 照片权限：已拒绝")
            case .authorized:
                self?.logger.info("✅ 照片权限：已授权（完全访问）")
            case .limited:
                self?.logger.info("✅ 照片权限：已授权（限制访问）")
            @unknown default:
                self?.logger.warning("📷 照片权限：未知状态")
            }
        }
    }
}

