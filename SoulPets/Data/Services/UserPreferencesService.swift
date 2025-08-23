import Foundation

/// 用户偏好设置服务
class UserPreferencesService {
    static let shared = UserPreferencesService()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let isProMember = "isProMember"
    }
    
    // MARK: - Pro Member Status
    
    /// 是否为Pro会员
    var isProMember: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isProMember)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isProMember)
        }
    }
    
    // MARK: - Photo Limits
    
    /// 每条记录最大照片数量
    var maxPhotosPerRecord: Int {
        return isProMember ? Int.max : 2
    }
    
    /// 每只宠物最大照片总数
    var maxPhotosPerPet: Int {
        return isProMember ? Int.max : 5    
    }
}
