//
//  TargetSpec.swift
//  MyLovingDoll
//
//  ObjectCamp 目标规格配置
//

import Foundation
import SwiftData

@Model
final class TargetSpec {
    /// 唯一标识符 (如: "doll", "car", "person:female")
    @Attribute(.unique) var specId: String
    
    /// 显示名称
    var displayName: String
    
    /// 目标类型描述 (用于 Vision 识别提示)
    var targetDescription: String
    
    /// 是否启用
    var isEnabled: Bool
    
    /// 创建时间
    var createdAt: Date
    
    /// 关联的实体
    @Relationship(deleteRule: .cascade, inverse: \Entity.targetSpec)
    var entities: [Entity]?
    
    /// 关联的主体
    @Relationship(deleteRule: .cascade, inverse: \Subject.targetSpec)
    var subjects: [Subject]?
    
    init(specId: String, displayName: String, targetDescription: String, isEnabled: Bool = true) {
        self.specId = specId
        self.displayName = displayName
        self.targetDescription = targetDescription
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}
