//
//  StoryInstanceDetailView.swift
//  MyLovingDoll
//
//  故事实例详情页 - 查看生成的故事内容
//

import SwiftUI
import SwiftData

struct StoryInstanceDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let story: StoryInstance
    @State private var currentPageIndex = 0
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部工具栏
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(story.storyTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if story.status == .completed {
                            Text("第 \(currentPageIndex + 1) / \(story.generatedPages.count) 页")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // 占位，保持标题居中
                    Color.clear
                        .frame(width: 44)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // 主内容区域
                if story.status == .completed {
                    bookView
                } else if story.status == .generating {
                    generatingSection
                } else {
                    failedSection
                }
            }
        }
    }
    
    // MARK: - 书本视图
    private var bookView: some View {
        PageCurlView(
            pages: story.generatedPages,
            currentPage: $currentPageIndex,
            specId: story.entity?.targetSpec?.specId
        )
    }
    
    // MARK: - 头部信息（保留但不使用）
    private var headerSection: some View {
        HStack(spacing: 16) {
            // 对象头像
            if let entity = story.entity,
               let coverSubject = entity.subjects?.first(where: { $0.id == entity.coverSubjectId }),
               let specId = entity.targetSpec?.specId,
               let image = FileManager.loadImage(relativePath: coverSubject.stickerPath, specId: specId) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let entity = story.entity {
                    Text(entity.customName ?? "未命名对象")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Image(systemName: "book.closed")
                    Text(story.storyTitle)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Text("创建于 \(story.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    
    // MARK: - 生成中状态
    private var generatingSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView(value: story.progress) {
                Text("正在生成故事...")
                    .foregroundColor(.white)
            }
            .progressViewStyle(.linear)
            .tint(.white)
            
            Text("\(Int(story.progress * 100))% 完成")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 失败状态
    private var failedSection: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("生成失败")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("请稍后重试")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Button {
                // TODO: 重新生成
            } label: {
                Text("重新生成")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 书页视图
struct BookPageView: View {
    let page: GeneratedStoryPage
    let pageNumber: Int
    let totalPages: Int
    let specId: String?
    
    var generatedImage: UIImage? {
        guard let imagePath = page.generatedImagePath,
              let specId = specId else { return nil }
        return FileManager.loadImage(relativePath: imagePath, specId: specId)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 书页背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 0) {
                    // 图片区域
                    if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: geometry.size.height * 0.6)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: geometry.size.height * 0.6)
                            .overlay(
                                ProgressView()
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                    }
                    
                    Spacer()
                    
                    // 文字区域
                    ScrollView {
                        Text(page.customText ?? page.originalText)
                            .font(.title3)
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                    }
                    .frame(maxHeight: geometry.size.height * 0.25)
                    
                    // 页码
                    Text("\(pageNumber)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - 生成的页面卡片（保留但不使用）
struct GeneratedPageCard: View {
    let page: GeneratedStoryPage
    let pageNumber: Int
    let specId: String?
    
    var generatedImage: UIImage? {
        guard let imagePath = page.generatedImagePath,
              let specId = specId else { return nil }
        return FileManager.loadImage(relativePath: imagePath, specId: specId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 页码
            HStack {
                Text("第 \(pageNumber) 页")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // 生成的图片
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            // 文字内容
            Text(page.customText ?? page.originalText)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryInstance.self, configurations: config)
    let context = container.mainContext
    
    // 创建测试数据
    let spec = TargetSpec(specId: "doll", displayName: "娃娃", targetDescription: "test")
    let entity = Entity(targetSpec: spec)
    entity.customName = "小红帽"
    
    let story = StoryInstance(storyBookId: "test", storyTitle: "小红帽的故事", entity: entity)
    story.status = .completed
    
    context.insert(spec)
    context.insert(entity)
    context.insert(story)
    
    return StoryInstanceDetailView(story: story)
        .modelContainer(container)
}
