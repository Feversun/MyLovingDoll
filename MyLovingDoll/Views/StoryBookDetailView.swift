//
//  StoryBookDetailView.swift
//  MyLovingDoll
//
//  故事书详情页面
//

import SwiftUI
import SwiftData

struct StoryBookDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var entities: [Entity]
    
    let book: StoryBook
    
    @State private var selectedEntity: Entity?
    @State private var selectedSubjectId: UUID? // 选中的具体图片
    @State private var showingEntityPicker = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 封面区域
                    coverSection
                    
                    // 故事描述
                    descriptionSection
                    
                    // 预览页面
                    previewPagesSection
                    
                    Spacer(minLength: 80)
                }
                .padding()
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                bottomActionBar
            }
            .sheet(isPresented: $showingEntityPicker) {
                EntityPickerSheet(
                    selectedEntity: $selectedEntity,
                    selectedSubjectId: $selectedSubjectId,
                    onConfirm: {
                        // 选择完成后的回调
                    }
                )
            }
            .alert("创建成功", isPresented: $showingSuccessAlert) {
                Button("查看我的故事", role: .none) {
                    // TODO: 跳转到“我的故事”Tab
                    dismiss()
                }
                Button("继续浏览", role: .cancel) {}
            } message: {
                Text("故事已开始生成，可以在“我的故事”中查看进度")
            }
        }
    }
    
    // MARK: - 封面区域
    private var coverSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(book.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(book.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label(book.category, systemImage: "tag.fill")
                    Label("\(book.previewPages.count) 页", systemImage: "doc.text.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(30)
        }
        .frame(height: 320)
    }
    
    // MARK: - 故事描述
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(.blue)
                Text("故事简介")
                    .font(.headline)
            }
            
            Text(book.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 预览页面
    private var previewPagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "photo.stack.fill")
                    .foregroundColor(.purple)
                Text("内容预览")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(book.previewPages) { page in
                        PreviewPageCard(page: page)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 底部操作栏
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if let selectedEntity = selectedEntity {
                    // 已选择对象
                    HStack(spacing: 12) {
                        // 显示选中的图片
                        if let subjectId = selectedSubjectId,
                           let subject = selectedEntity.subjects?.first(where: { $0.id == subjectId }),
                           let specId = selectedEntity.targetSpec?.specId,
                           let image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedEntity.customName ?? "未命名")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let subjectCount = selectedEntity.subjects?.count {
                                Text("共 \(subjectCount) 张照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            showingEntityPicker = true
                        } label: {
                            Text("更换")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button {
                    if selectedEntity == nil {
                        showingEntityPicker = true
                    } else {
                        createStoryInstance()
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedEntity == nil ? "person.crop.circle.badge.plus" : "arrow.right.circle.fill")
                        Text(selectedEntity == nil ? "选择对象" : "开始生成")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedEntity == nil ? Color.blue.gradient : Color.green.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - 创建故事实例
    private func createStoryInstance() {
        guard let entity = selectedEntity else { return }
        
        // 确保有选中的图片
        let subjectId = selectedSubjectId ?? entity.coverSubjectId ?? entity.subjects?.first?.id
        
        // 创建故事实例
        let instance = StoryInstance(
            storyBookId: book.id,
            storyTitle: book.title,
            entity: entity
        )
        
        modelContext.insert(instance)
        
        do {
            try modelContext.save()
            showingSuccessAlert = true
            
            // 异步生成故事内容
            Task {
                await generateStoryContent(for: instance, subjectId: subjectId)
            }
        } catch {
            print("保存故事实例失败: \(error)")
        }
    }
    
    // MARK: - 生成故事内容
    private func generateStoryContent(for instance: StoryInstance, subjectId: UUID?) async {
        print("[StoryGen] 开始生成故事: \(instance.storyTitle)")
        
        guard let entity = instance.entity,
              let targetSubjectId = subjectId,
              let subject = entity.subjects?.first(where: { $0.id == targetSubjectId }),
              let specId = entity.targetSpec?.specId,
              let characterImage = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId) else {
            print("[StoryGen] ❌ 无法获取选中的图片")
            await MainActor.run {
                instance.status = .failed
                try? modelContext.save()
            }
            return
        }
        
        // 获取 NanoBanana Service
        guard let service = try? NanoBananaService.fromKeychain() else {
            print("[StoryGen] ❌ 无法获取 API Key")
            await MainActor.run {
                instance.status = .failed
                try? modelContext.save()
            }
            return
        }
        
        let totalPages = book.previewPages.count
        var generatedPages: [GeneratedStoryPage] = []
        
        // 为每一页生成图片
        for (index, page) in book.previewPages.enumerated() {
            print("[StoryGen] 生成第 \(index + 1)/\(totalPages) 页")
            
            do {
                // 使用对象图片 + 故事页面描述生成图片
                let prompt = "\(page.text). Style: storybook illustration, warm colors, suitable for children."
                
                let generatedImage = try await service.editImage(
                    prompt: prompt,
                    baseImage: characterImage
                )
                
                // 保存生成的图片
                let imageName = "story_\(instance.id.uuidString)_page\(index).jpg"
                let imagePath = "stories/\(imageName)"
                
                if let imageData = generatedImage.jpegData(compressionQuality: 0.8) {
                    let fullPath = FileManager.specDirectory(for: specId).appendingPathComponent(imagePath)
                    try? FileManager.default.createDirectory(at: fullPath.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try? imageData.write(to: fullPath)
                    
                    let generatedPage = GeneratedStoryPage(
                        pageIndex: index,
                        originalText: page.text,
                        generatedImagePath: imagePath,
                        customText: nil,
                        timestamp: Date()
                    )
                    
                    generatedPages.append(generatedPage)
                    
                    // 更新进度
                    await MainActor.run {
                        instance.progress = Double(index + 1) / Double(totalPages)
                        instance.addPage(generatedPage)
                        try? modelContext.save()
                    }
                    
                    print("[StoryGen] ✅ 第 \(index + 1) 页生成成功")
                }
                
            } catch {
                print("[StoryGen] ❌ 第 \(index + 1) 页生成失败: \(error)")
                // 继续生成下一页，不中断
            }
        }
        
        // 完成
        await MainActor.run {
            instance.status = generatedPages.isEmpty ? .failed : .completed
            instance.progress = 1.0
            try? modelContext.save()
            print("[StoryGen] ✅ 故事生成完成，共 \(generatedPages.count)/\(totalPages) 页")
        }
    }
}

// MARK: - 预览页面卡片
struct PreviewPageCard: View {
    let page: StoryPage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 页面图片占位
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .frame(width: 180, height: 240)
            
            Text(page.text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: 180, alignment: .leading)
        }
    }
}

// MARK: - 对象选择器 Sheet
struct EntityPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var entities: [Entity]
    
    @Binding var selectedEntity: Entity?
    @Binding var selectedSubjectId: UUID?
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 16)
                ], spacing: 16) {
                    ForEach(entities.filter { ($0.subjects?.count ?? 0) > 0 }) { entity in
                        NavigationLink {
                            SubjectGridView(
                                entity: entity,
                                mode: .select,
                                selectedIndex: .constant(0),
                                selectedSubjectId: $selectedSubjectId
                            )
                            .onDisappear {
                                if selectedSubjectId != nil {
                                    selectedEntity = entity
                                    dismiss()
                                    onConfirm()
                                }
                            }
                        } label: {
                            EntityGridItem(
                                entity: entity,
                                isSelected: selectedEntity?.id == entity.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("选择对象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 对象网格项
struct EntityGridItem: View {
    let entity: Entity
    let isSelected: Bool
    
    var coverImage: UIImage? {
        guard let coverSubject = entity.subjects?.first(where: { $0.id == entity.coverSubjectId }),
              let specId = entity.targetSpec?.specId else { return nil }
        return FileManager.loadImage(relativePath: coverSubject.stickerPath, specId: specId)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Circle().fill(.white))
                        .offset(x: 35, y: -35)
                }
            }
            
            Text(entity.customName ?? "未命名")
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100)
        }
    }
}

#Preview {
    StoryBookDetailView(book: StoryBook.samples[0])
        .modelContainer(for: [Entity.self, Subject.self])
}
