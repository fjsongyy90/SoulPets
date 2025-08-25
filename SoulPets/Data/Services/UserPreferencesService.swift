import Foundation

/// 用户偏好设置服务
class UserPreferencesService {
    static let shared = UserPreferencesService()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let isProMember = "isProMember"
        static let lastAppEntryDate = "lastAppEntryDate"
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
        return isProMember ? Int.max : 50
    }
    
    // MARK: - App Entry Date
    
    /// 保存应用进入日期
    func saveAppEntryDate() {
        let currentDate = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(currentDate, forKey: Keys.lastAppEntryDate)
    }
    
    /// 获取上次进入应用的日期
    var lastAppEntryDate: Date? {
        return UserDefaults.standard.object(forKey: Keys.lastAppEntryDate) as? Date
    }
    
    /// 检查是否是新的一天
    var isNewDay: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        guard let lastDate = lastAppEntryDate else {
            return true
        }
        return !Calendar.current.isDate(today, inSameDayAs: lastDate)
    }
}
