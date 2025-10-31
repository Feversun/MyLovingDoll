//
//  StoryBook.swift
//  MyLovingDoll
//
//  故事书数据模型
//

import Foundation
import SwiftUI

/// 故事书模型
struct StoryBook: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let coverImageName: String // 封面图片名称
    let previewPages: [StoryPage] // 预览页面
    let category: String
    
    init(id: String, title: String, subtitle: String, description: String, coverImageName: String, previewPages: [StoryPage], category: String = "童话") {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.coverImageName = coverImageName
        self.previewPages = previewPages
        self.category = category
    }
}

/// 故事页面
struct StoryPage: Identifiable {
    let id: UUID = UUID()
    let imageName: String
    let text: String
}

// MARK: - 示例数据
extension StoryBook {
    static let samples: [StoryBook] = [
        StoryBook(
            id: "little-red-riding-hood",
            title: "小红帽",
            subtitle: "Little Red Riding Hood",
            description: "从前有个可爱的小姑娘，谁见了都喜欢，但最喜欢她的是她的奶奶。一次奶奶送给小姑娘一顶红色天鹅绒的帽子，戴在她的头上正好合适，从此，姑娘再也不愿意戴其他帽子，于是大家便叫她\"小红帽\"。",
            coverImageName: "story.redhood.cover",
            previewPages: [
                StoryPage(imageName: "story.redhood.1", text: "从前有个可爱的小姑娘..."),
                StoryPage(imageName: "story.redhood.2", text: "她总是戴着红色的帽子..."),
                StoryPage(imageName: "story.redhood.3", text: "有一天，妈妈让她去看望奶奶...")
            ]
        ),
        StoryBook(
            id: "snow-white",
            title: "白雪公主",
            subtitle: "Snow White",
            description: "在遥远的王国里，住着一位美丽善良的公主，她的皮肤像雪一样白，因此被称为白雪公主。王后嫉妒她的美貌，派猎人要害她，但白雪公主逃到了森林里，遇到了七个小矮人...",
            coverImageName: "story.snowwhite.cover",
            previewPages: [
                StoryPage(imageName: "story.snowwhite.1", text: "在一个王国里..."),
                StoryPage(imageName: "story.snowwhite.2", text: "美丽的白雪公主..."),
                StoryPage(imageName: "story.snowwhite.3", text: "遇到了七个小矮人...")
            ]
        ),
        StoryBook(
            id: "cinderella",
            title: "灰姑娘",
            subtitle: "Cinderella",
            description: "从前有一个善良美丽的女孩，她的继母和两个姐姐对她很不好，经常让她做很多家务。但是在仙女的帮助下，她参加了王子的舞会，最终与王子过上了幸福的生活。",
            coverImageName: "story.cinderella.cover",
            previewPages: [
                StoryPage(imageName: "story.cinderella.1", text: "善良的灰姑娘..."),
                StoryPage(imageName: "story.cinderella.2", text: "仙女出现了..."),
                StoryPage(imageName: "story.cinderella.3", text: "王子的舞会...")
            ]
        )
    ]
}
