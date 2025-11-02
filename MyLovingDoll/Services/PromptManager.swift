//
//  PromptManager.swift
//  MyLovingDoll
//
//  Prompt 管理系统 - 根据场景动态组合对象特征
//

import Foundation

/// Prompt 场景类型
enum PromptScene {
    case storyGeneration    // 故事生成
    case imageGeneration    // 图片生成
    case conversation       // 对话/交互
    case characterIntro     // 角色介绍
    
    var includedTraits: [EntityTrait] {
        switch self {
        case .storyGeneration:
            return [.name, .personality, .relationship, .appearance, .specialAbilities, .backgroundStory]
        case .imageGeneration:
            return [.appearance, .personality, .age]
        case .conversation:
            return [.name, .personality, .hobbies, .relationship]
        case .characterIntro:
            return [.name, .birthday, .personality, .hobbies, .relationship, .backgroundStory]
        }
    }
}

/// 对象特征类型
enum EntityTrait {
    case name
    case birthday
    case personality
    case hobbies
    case backgroundStory
    case appearance
    case specialAbilities
    case relationship
    case age  // 从生日计算
}

/// Prompt 管理器
class PromptManager {
    static let shared = PromptManager()
    
    private init() {}
    
    /// 为对象生成 Prompt
    func generatePrompt(for entity: Entity, scene: PromptScene, additionalContext: String? = nil) -> String {
        var promptParts: [String] = []
        
        // 根据场景包含的特征组合 prompt
        for trait in scene.includedTraits {
            if let part = getTraitPrompt(entity: entity, trait: trait) {
                promptParts.append(part)
            }
        }
        
        // 添加额外上下文
        if let context = additionalContext {
            promptParts.append(context)
        }
        
        return promptParts.joined(separator: ". ")
    }
    
    /// 获取单个特征的 prompt 片段
    private func getTraitPrompt(entity: Entity, trait: EntityTrait) -> String? {
        switch trait {
        case .name:
            if let name = entity.customName {
                return "Character name is \(name)"
            }
            
        case .birthday:
            if let birthday = entity.birthday {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Birthday: \(formatter.string(from: birthday))"
            }
            
        case .personality:
            if let personality = entity.personality, !personality.isEmpty {
                return "Personality: \(personality)"
            }
            
        case .hobbies:
            if let hobbies = entity.hobbies, !hobbies.isEmpty {
                return "Hobbies: \(hobbies)"
            }
            
        case .backgroundStory:
            if let story = entity.backgroundStory, !story.isEmpty {
                return "Background: \(story)"
            }
            
        case .appearance:
            if let appearance = entity.appearance, !appearance.isEmpty {
                return "Appearance: \(appearance)"
            }
            
        case .specialAbilities:
            if let abilities = entity.specialAbilities, !abilities.isEmpty {
                return "Special abilities: \(abilities)"
            }
            
        case .relationship:
            if let relationship = entity.relationship, !relationship.isEmpty {
                return "Relationship: \(relationship)"
            }
            
        case .age:
            if let birthday = entity.birthday {
                let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
                if age > 0 {
                    return "Age: \(age) years old"
                }
            }
        }
        
        return nil
    }
    
    /// 生成故事特定的 prompt（带故事页面文本）
    func generateStoryPrompt(for entity: Entity, pageText: String, style: String = "storybook illustration, warm colors, suitable for children") -> String {
        let characterPrompt = generatePrompt(for: entity, scene: .storyGeneration)
        return "\(pageText). Character details: \(characterPrompt). Style: \(style)"
    }
    
    /// 生成角色卡片描述
    func generateCharacterDescription(for entity: Entity) -> String {
        generatePrompt(for: entity, scene: .characterIntro)
    }
}
