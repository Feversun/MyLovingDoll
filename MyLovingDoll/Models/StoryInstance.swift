//
//  StoryInstance.swift
//  MyLovingDoll
//
//  故事实例 - 对象与故事书的关联
//

import Foundation
import SwiftData
import UIKit

/// 故事实例状态
enum StoryStatus: String, Codable {
    case generating = "生成中"
    case completed = "已完成"
    case failed = "生成失败"
}

/// 生成的故事页面
struct GeneratedStoryPage: Codable {
    let pageIndex: Int
    let originalText: String // 原始故事文本
    let generatedImagePath: String? // 生成的图片路径
    let customText: String? // 自定义文本
    let timestamp: Date
}

/// 故事实例 - 保存对象在某个故事中的生成结果
@Model
final class StoryInstance {
    /// 唯一标识
    @Attribute(.unique) var id: UUID
    
    /// 关联的故事书ID
    var storyBookId: String
    
    /// 故事标题（冗余存储，方便显示）
    var storyTitle: String
    
    /// 关联的对象
    @Relationship(deleteRule: .nullify)
    var entity: Entity?
    
    /// 生成的故事页面（JSON存储）
    @Attribute(.externalStorage) var generatedPagesData: Data?
    
    /// 状态
    var status: StoryStatus
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 完成进度 (0.0 - 1.0)
    var progress: Double
    
    /// 封面图路径（第一页的生成图）
    var coverImagePath: String?
    
    init(storyBookId: String, storyTitle: String, entity: Entity) {
        self.id = UUID()
        self.storyBookId = storyBookId
        self.storyTitle = storyTitle
        self.entity = entity
        self.status = .generating
        self.createdAt = Date()
        self.updatedAt = Date()
        self.progress = 0.0
    }
    
    /// 获取生成的页面
    var generatedPages: [GeneratedStoryPage] {
        guard let data = generatedPagesData,
              let pages = try? JSONDecoder().decode([GeneratedStoryPage].self, from: data) else {
            return []
        }
        return pages
    }
    
    /// 保存生成的页面
    func savePages(_ pages: [GeneratedStoryPage]) {
        generatedPagesData = try? JSONEncoder().encode(pages)
        updatedAt = Date()
    }
    
    /// 添加一个生成的页面
    func addPage(_ page: GeneratedStoryPage) {
        var pages = generatedPages
        pages.append(page)
        savePages(pages)
        
        // 更新封面图（使用第一页）
        if coverImagePath == nil, let imagePath = page.generatedImagePath {
            coverImagePath = imagePath
        }
    }
}
