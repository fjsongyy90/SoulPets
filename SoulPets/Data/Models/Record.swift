import Foundation
import SwiftData

@Model
final class Record {
    // MARK: - 属性 (CloudKit要求所有属性可选或有默认值)
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系 (CloudKit要求关系可选)
    @Relationship(deleteRule: .nullify)
    var tag: Tag?
    
    @Relationship(deleteRule: .cascade, inverse: \RecordPhoto.record)
    var photos: [RecordPhoto]?
    
    // inverse已在Pet.records定义
    var pets: [Pet]?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        notes: String? = nil,
        tag: Tag? = nil,
        pets: [Pet]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.notes = notes
        self.tag = tag
        self.pets = pets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class RecordPhoto {
    // MARK: - 属性 (CloudKit要求所有属性可选或有默认值)
    var id: UUID = UUID()
    var photoData: Data = Data()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - 关系 (inverse已在Record.photos定义)
    var record: Record?
    
    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        photoData: Data = Data(),
        record: Record? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.photoData = photoData
        self.record = record
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
