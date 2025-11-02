//
//  EntityDetailView.swift
//  MyLovingDoll
//
//  实体详情视图
//

import SwiftUI
import SwiftData

struct EntityDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var entity: Entity
    
    @Query private var allStories: [StoryInstance]
    
    @State private var showingProfileEdit = false
    @State private var showingRenameDialog = false
    @State private var newName = ""
    @State private var currentIndex = 0
    @State private var showingAdjustmentView = false
    @State private var showingAllPhotosSheet = false
    @State private var showingMoveSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAIGeneration = false
    @State private var showingVideoGeneration = false
    @State private var showingStoriesSheet = false
    @State private var showingStoryBookPicker = false
    
    var subjects: [Subject] {
        entity.subjects ?? []
    }
    
    var currentSubject: Subject? {
        subjects.indices.contains(currentIndex) ? subjects[currentIndex] : nil
    }
    
    // 该对象参与的故事
    var entityStories: [StoryInstance] {
        allStories.filter { $0.entity?.id == entity.id }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 整体滚动区域
            ScrollView {
                VStack(spacing: 0) {
                    // 大图显示
                    if !subjects.isEmpty {
                        TabView(selection: $currentIndex) {
                            ForEach(subjects.indices, id: \.self) { index in
                                if let specId = entity.targetSpec?.specId {
                                    SubjectLargeImageView(
                                        subject: subjects[index],
                                        specId: specId
                                    )
                                    .tag(index)
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                        .frame(height: 500)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("暂无照片")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 500)
                    }
                    
                    // 参与的故事区域
                    if !entityStories.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("参与的故事", systemImage: "book.pages.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button {
                                    showingStoryBookPicker = true
                                } label: {
                                    Label("加入新故事", systemImage: "plus.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(entityStories) { story in
                                        EntityStoryCard(story: story)
                                            .onTapGesture {
                                                // TODO: 跳转到故事详情
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 80)
                        }
                        .background(Color(.systemBackground))
                    } else {
                        // 空状态
                        VStack(spacing: 16) {
                            Image(systemName: "book")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("还没有加入任何故事")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button {
                                showingStoryBookPicker = true
                            } label: {
                                Label("加入故事", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.gradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // 底部工具栏
            if !subjects.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 0) {
                        // 调整主体
                        ToolbarButton(
                            icon: "crop.rotate",
                            title: "调整"
                        ) {
                            showingAdjustmentView = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 查看所有
                        ToolbarButton(
                            icon: "square.grid.2x2",
                            title: "所有"
                        ) {
                            showingAllPhotosSheet = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // AI 图片
                        ToolbarButton(
                            icon: "sparkles",
                            title: "AI图",
                            color: .purple
                        ) {
                            showingAIGeneration = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // AI 视频
                        ToolbarButton(
                            icon: "video.badge.waveform",
                            title: "视频",
                            color: .orange
                        ) {
                            showingVideoGeneration = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 移动
                        ToolbarButton(
                            icon: "arrow.right.circle",
                            title: "移动"
                        ) {
                            showingMoveSheet = true
                        }
                        
                        Divider().frame(height: 40)
                        
                        // 删除
                        ToolbarButton(
                            icon: "trash",
                            title: "删除",
                            color: .red
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                }
            }
        }
        .navigationTitle(entity.customName ?? "未命名对象")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showingStoriesSheet = true
                    } label: {
                        Label("查看参与的故事 (\(entityStories.count))", systemImage: "book.pages")
                    }
                    
                    Button {
                        showingStoryBookPicker = true
                    } label: {
                        Label("加入新故事", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "book.circle.fill")
                        .foregroundStyle(.blue.gradient)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingProfileEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.pink.gradient)
                }
            }
        }
        .alert("重命名", isPresented: $showingRenameDialog) {
            TextField("名称", text: $newName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                rename()
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteCurrentSubject()
            }
        } message: {
            Text("确定要删除这张照片吗?")
        }
        .sheet(isPresented: $showingAllPhotosSheet) {
            SubjectGridView(
                entity: entity,
                mode: .browse,
                selectedIndex: $currentIndex
            )
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let specId = entity.targetSpec?.specId, let subject = currentSubject {
                MoveSubjectsView(
                    selectedSubjects: [subject.id],
                    currentEntity: entity,
                    specId: specId,
                    onComplete: {
                        if entity.subjects?.isEmpty ?? true {
                            dismiss()
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingAdjustmentView) {
            if #available(iOS 17.0, *), let specId = entity.targetSpec?.specId, let subject = currentSubject {
                SubjectAdjustmentView(subject: subject, specId: specId)
            }
        }
        .sheet(isPresented: $showingAIGeneration) {
            if let specId = entity.targetSpec?.specId {
                NanoBananaGenerationView(entity: entity, specId: specId)
            }
        }
        .sheet(isPresented: $showingVideoGeneration) {
            Veo3GenerationView()
        }
        .sheet(isPresented: $showingStoriesSheet) {
            EntityStoriesListSheet(entity: entity, stories: entityStories)
        }
        .sheet(isPresented: $showingStoryBookPicker) {
            StoryBookPickerSheet(entity: entity)
        }
        .sheet(isPresented: $showingProfileEdit) {
            EntityProfileView(entity: entity)
        }
    }
    
    // MARK: - Methods
    
    private func rename() {
        entity.customName = newName.isEmpty ? nil : newName
        entity.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func deleteCurrentSubject() {
        guard let subject = currentSubject else { return }
        
        // 删除文件
        if let specId = entity.targetSpec?.specId {
            let stickerURL = FileManager.specDirectory(for: specId).appendingPathComponent(subject.stickerPath)
            try? FileManager.default.removeItem(at: stickerURL)
            
            if let thumbnailPath = subject.thumbnailPath {
                let thumbnailURL = FileManager.specDirectory(for: specId).appendingPathComponent(thumbnailPath)
                try? FileManager.default.removeItem(at: thumbnailURL)
            }
        }
        
        // 从实体中移除
        subject.entity = nil
        modelContext.delete(subject)
        
        // 如果删除后实体为空,删除实体并返回
        if entity.subjects?.isEmpty ?? true {
            modelContext.delete(entity)
            try? modelContext.save()
            dismiss()
        } else {
            // 调整当前索引
            if currentIndex >= subjects.count - 1 {
                currentIndex = max(0, subjects.count - 2)
            }
            entity.updateAverageConfidence()
            try? modelContext.save()
        }
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    let title: String
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subject Large Image View
struct SubjectLargeImageView: View {
    let subject: Subject
    let specId: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId)
        }
    }
}

// MARK: - 统一的图片网格视图
enum SubjectGridMode {
    case browse  // 浏览模式：点击切换当前显示
    case select  // 选择模式：选择用于生成
}

struct SubjectGridView: View {
    @Environment(\.dismiss) var dismiss
    
    let entity: Entity
    let mode: SubjectGridMode
    
    @Binding var selectedIndex: Int
    var selectedSubjectId: Binding<UUID?>? = nil
    var onConfirm: (() -> Void)? = nil
    
    var subjects: [Subject] {
        entity.subjects ?? []
    }
    
    var title: String {
        switch mode {
        case .browse:
            return "所有照片 (\(subjects.count))"
        case .select:
            return "选择图片"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(subjects.indices, id: \.self) { index in
                        let subject = subjects[index]
                        
                        if let specId = entity.targetSpec?.specId {
                            SubjectThumbnailView(
                                subject: subject,
                                specId: specId,
                                isSelected: isSelected(subject: subject, index: index),
                                showConfidence: mode == .select
                            )
                            .onTapGesture {
                                handleTap(subject: subject, index: index)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                if mode == .select {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确定") {
                            dismiss()
                            onConfirm?()
                        }
                        .disabled(selectedSubjectId?.wrappedValue == nil)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
            }
        }
    }
    
    private func isSelected(subject: Subject, index: Int) -> Bool {
        switch mode {
        case .browse:
            return index == selectedIndex
        case .select:
            return selectedSubjectId?.wrappedValue == subject.id
        }
    }
    
    private func handleTap(subject: Subject, index: Int) {
        switch mode {
        case .browse:
            selectedIndex = index
            dismiss()
        case .select:
            selectedSubjectId?.wrappedValue = subject.id
        }
    }
}

// MARK: - Subject Thumbnail
struct SubjectThumbnailView: View {
    let subject: Subject
    let specId: String
    var isSelected: Bool = false
    var showConfidence: Bool = false
    
    @State private var image: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay {
                            ProgressView()
                        }
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
            
            if showConfidence {
                Text("置信度: \(Int(subject.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            image = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId)
        }
    }
}

// MARK: - 对象参与的故事列表
struct EntityStoriesListSheet: View {
    @Environment(\.dismiss) var dismiss
    let entity: Entity
    let stories: [StoryInstance]
    
    var body: some View {
        NavigationStack {
            if stories.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("还没有加入任何故事")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List(stories) { story in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.storyTitle)
                                .font(.headline)
                            Text(story.status.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("\(entity.customName ?? "对象")的故事")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
        }
    }
}

// MARK: - 选择故事书加入
struct StoryBookPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entity: Entity
    let books = StoryBook.samples
    
    @State private var selectedBook: StoryBook?
    @State private var selectedSubjectId: UUID?
    @State private var showingConfirmation = false
    @State private var showingSubjectPicker = false
    
    var body: some View {
        NavigationStack {
            List(books) { book in
                Button {
                    selectedBook = book
                    showingConfirmation = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "book.closed.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue.gradient)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(book.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("选择故事书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .alert("选择图片", isPresented: $showingConfirmation) {
            Button("取消", role: .cancel) {}
            Button("继续") {
                // 如果只有一张图，直接创建
                if (entity.subjects?.count ?? 0) <= 1 {
                    selectedSubjectId = entity.subjects?.first?.id
                    createStory()
                } else {
                    // 多张图片，让用户选择
                    showingSubjectPicker = true
                }
            }
        } message: {
            if let book = selectedBook {
                let subjectCount = entity.subjects?.count ?? 0
                if subjectCount > 1 {
                    Text("将《\(book.title)》加入 \(entity.customName ?? "对象")，共有 \(subjectCount) 张图片可选")
                } else {
                    Text("将 \(entity.customName ?? "对象") 加入《\(book.title)》?")
                }
            }
        }
        .sheet(isPresented: $showingSubjectPicker) {
            SubjectGridView(
                entity: entity,
                mode: .select,
                selectedIndex: .constant(0),
                selectedSubjectId: $selectedSubjectId,
                onConfirm: {
                    // 选择完图片后创建故事
                    if selectedSubjectId != nil {
                        createStory()
                    }
                }
            )
        }
    }
    
    private func createStory() {
        guard let book = selectedBook else { return }
        
        let instance = StoryInstance(
            storyBookId: book.id,
            storyTitle: book.title,
            entity: entity
        )
        
        modelContext.insert(instance)
        
        do {
            try modelContext.save()
            
            // 异步生成故事内容
            Task {
                await generateStoryContent(for: instance, book: book, subjectId: selectedSubjectId)
            }
            
        } catch {
            print("保存故事实例失败: \(error)")
        }
        
        dismiss()
    }
    
    // MARK: - 生成故事内容
    private func generateStoryContent(for instance: StoryInstance, book: StoryBook, subjectId: UUID?) async {
        print("[StoryGen] 开始生成故事: \(instance.storyTitle)")
        
        guard let entity = instance.entity,
              let targetSubjectId = subjectId,
              let subject = entity.subjects?.first(where: { $0.id == targetSubjectId }),
              let specId = entity.targetSpec?.specId,
              let characterImage = FileManager.loadImage(relativePath: subject.stickerPath, specId: specId) else {
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

// MARK: - 对象故事卡片
struct EntityStoryCard: View {
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
        VStack(alignment: .leading, spacing: 8) {
            // 封面图
            ZStack(alignment: .topTrailing) {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 180)
                        .overlay(
                            VStack {
                                Image(systemName: "book.closed")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                        )
                }
                
                // 状态标记
                Image(systemName: statusIcon)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(statusColor)
                    .clipShape(Circle())
                    .offset(x: -6, y: 6)
            }
            
            // 标题
            Text(story.storyTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            
            // 状态或页数
            if story.status == .generating {
                HStack(spacing: 4) {
                    ProgressView(value: story.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 80)
                    Text("\(Int(story.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if story.status == .completed {
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack")
                        .font(.caption2)
                    Text("\(story.generatedPages.count) 页")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            } else {
                Text(story.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .frame(width: 140)
    }
}
