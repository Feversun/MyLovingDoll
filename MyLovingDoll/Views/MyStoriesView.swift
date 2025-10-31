//
//  MyStoriesView.swift
//  MyLovingDoll
//
//  我的故事列表页面
//

import SwiftUI
import SwiftData

struct MyStoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryInstance.createdAt, order: .reverse) private var stories: [StoryInstance]
    
    @State private var selectedStory: StoryInstance?
    
    var body: some View {
        NavigationStack {
            Group {
                if stories.isEmpty {
                    emptyStateView
                } else {
                    storyListView
                }
            }
            .navigationTitle("我的故事")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !stories.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.pages")
                .font(.system(size: 80))
                .foregroundStyle(.gray.gradient)
            
            Text("还没有创建故事")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("在故事书中选择一个故事\n搭配你的对象开始创作")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 故事列表
    private var storyListView: some View {
        List {
            ForEach(stories) { story in
                StoryInstanceCard(story: story)
                    .onTapGesture {
                        selectedStory = story
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteStories)
        }
        .listStyle(.plain)
        .sheet(item: $selectedStory) { story in
            StoryInstanceDetailView(story: story)
        }
    }
    
    // MARK: - 删除故事
    private func deleteStories(at offsets: IndexSet) {
        for index in offsets {
            let story = stories[index]
            
            // 删除生成的图片文件
            if let specId = story.entity?.targetSpec?.specId {
                for page in story.generatedPages {
                    if let imagePath = page.generatedImagePath {
                        let fullPath = FileManager.specDirectory(for: specId).appendingPathComponent(imagePath)
                        try? FileManager.default.removeItem(at: fullPath)
                    }
                }
            }
            
            // 从数据库删除
            modelContext.delete(story)
        }
        
        try? modelContext.save()
    }
}

// MARK: - 故事实例卡片
struct StoryInstanceCard: View {
    let story: StoryInstance
    
    var statusColor: Color {
        switch story.status {
        case .generating: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var statusIcon: String {
        switch story.status {
        case .generating: return "hourglass"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
    
    var coverImage: UIImage? {
        if let coverPath = story.coverImagePath,
           let specId = story.entity?.targetSpec?.specId {
            return FileManager.loadImage(relativePath: coverPath, specId: specId)
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 封面/对象图
            ZStack(alignment: .topTrailing) {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 140)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                
                // 状态标记
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(statusColor)
                    .clipShape(Circle())
                    .offset(x: -4, y: 4)
            }
            
            // 信息区域
            VStack(alignment: .leading, spacing: 8) {
                Text(story.storyTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                if let entity = story.entity {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                        Text(entity.customName ?? "未命名对象")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 进度或页数
                if story.status == .generating {
                    HStack(spacing: 8) {
                        ProgressView(value: story.progress)
                            .progressViewStyle(.linear)
                        Text("\(Int(story.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.caption)
                        Text("\(story.generatedPages.count) 页")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 创建时间
                Text(story.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    MyStoriesView()
        .modelContainer(for: [StoryInstance.self, Entity.self])
}
