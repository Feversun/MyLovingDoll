//
//  NanoBananaGenerationView.swift
//  MyLovingDoll
//
//  Nano Banana AI 图片生成视图
//

import SwiftUI
import PhotosUI

// MARK: - 生成历史记录
struct GenerationHistory: Identifiable {
    let id = UUID()
    let image: UIImage
    let prompt: String
    let mode: String
    let timestamp: Date
}

struct NanoBananaGenerationView: View {
    @Environment(\.dismiss) var dismiss
    
    let entity: Entity
    let specId: String
    
    @State private var prompt: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isGenerating = false
    @State private var generatedImage: UIImage?
    @State private var errorMessage: String?
    @State private var showingPhotoPicker = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    // 历史记录
    @State private var generationHistory: [GenerationHistory] = []
    
    // 主体图片(默认第一张)
    var subjectImage: UIImage? {
        guard let firstSubject = entity.subjects?.first else { return nil }
        return FileManager.loadImage(relativePath: firstSubject.stickerPath, specId: specId)
    }
    
    // 所有用于生成的图片
    var allImages: [UIImage] {
        var images: [UIImage] = []
        if let subject = subjectImage {
            images.append(subject)
        }
        images.append(contentsOf: selectedImages)
        return images
    }
    
    // 生成模式
    var generationMode: String {
        let imageCount = allImages.count
        if imageCount == 0 {
            return "文本生成图片"
        } else if imageCount == 1 {
            return "单图编辑"
        } else {
            return "多图合成 (\(imageCount)张)"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 生成模式提示
                    HStack {
                        Image(systemName: modeIcon)
                            .foregroundColor(.blue)
                        Text(generationMode)
                            .font(.headline)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 图片预览区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("参考图片")
                                .font(.headline)
                            Spacer()
                            Text("\(allImages.count)/3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // 主体图片(第一张,不可删除)
                                if let subject = subjectImage {
                                    ImageCard(image: subject, isDefault: true, onRemove: nil)
                                }
                                
                                // 用户添加的图片
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ImageCard(image: image, isDefault: false) {
                                        selectedImages.remove(at: index)
                                    }
                                }
                                
                                // 添加按钮
                                if selectedImages.count < 2 {
                                    Button {
                                        showingPhotoPicker = true
                                    } label: {
                                        VStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.blue)
                                            Text("添加图片")
                                                .font(.caption)
                                        }
                                        .frame(width: 120, height: 120)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 提示词输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("提示词")
                            .font(.headline)
                        
                        TextEditor(text: $prompt)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // 快捷提示词
                        Text("快捷提示:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                QuickPromptButton("可爱风格") {
                                    prompt = "将图片转换为可爱的风格,添加柔和的色彩和卡通效果"
                                }
                                QuickPromptButton("写实风格") {
                                    prompt = "将图片转换为超写实的风格,保持细节清晰"
                                }
                                QuickPromptButton("动漫风格") {
                                    prompt = "将图片转换为日式动漫风格,使用明亮的色彩"
                                }
                                QuickPromptButton("合成") {
                                    prompt = "将这些图片自然地合成在一起,创造一个和谐的场景"
                                }
                            }
                        }
                    }
                    
                    // 生成按钮
                    Button {
                        Task {
                            await generateImage()
                        }
                    } label: {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("生成中...")
                            }
                        } else {
                            Label("开始生成", systemImage: "sparkles")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(prompt.isEmpty ? Color.gray.gradient : Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(prompt.isEmpty || isGenerating)
                    
                    // 生成结果
                    if let generatedImage = generatedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最新生成")
                                .font(.headline)
                            
                            Image(uiImage: generatedImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 3)
                                )
                            
                            HStack(spacing: 12) {
                                Button {
                                    saveToPhotos(generatedImage)
                                } label: {
                                    Label("保存到相册", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.green.gradient)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                Button {
                                    shareImage(generatedImage)
                                } label: {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.blue.gradient)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // 历史记录
                    if !generationHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("生成历史")
                                    .font(.headline)
                                Spacer()
                                Text("共 \(generationHistory.count) 条")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ForEach(generationHistory) { history in
                                HistoryCard(history: history,
                                          onSave: { saveToPhotos(history.image) },
                                          onShare: { shareImage(history.image) })
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // 错误提示
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("AI 图片生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker,
                         selection: $photoPickerItems,
                         maxSelectionCount: 2 - selectedImages.count,
                         matching: .images)
            .onChange(of: photoPickerItems) { _, newItems in
                Task {
                    await loadPhotos(from: newItems)
                }
            }
        }
    }
    
    private var modeIcon: String {
        let count = allImages.count
        if count == 0 { return "wand.and.stars" }
        else if count == 1 { return "photo.badge.arrow.down" }
        else { return "rectangle.3.group" }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImages.append(image)
                }
            }
        }
        photoPickerItems = []
    }
    
    private func generateImage() async {
        print("[UI] 🚀 开始生成图片...")
        print("[UI] 图片数量: \(allImages.count)")
        print("[UI] 提示词: \(prompt)")
        
        isGenerating = true
        errorMessage = nil
        
        do {
            print("[UI] 🔑 从 Keychain 读取 API Key...")
            let service = try NanoBananaService.fromKeychain()
            print("[UI] ✅ API Key 读取成功")
            
            let result: UIImage
            
            // 根据图片数量选择 API
            switch allImages.count {
            case 0:
                print("[UI] 📝 模式: 纯文本生成")
                result = try await service.generateImage(prompt: prompt)
                
            case 1:
                print("[UI] 🎨 模式: 单图编辑")
                result = try await service.editImage(prompt: prompt, baseImage: allImages[0])
                
            default:
                print("[UI] 🖼️ 模式: 多图合成 (\(allImages.count)张)")
                result = try await service.composeImage(prompt: prompt, baseImages: allImages)
            }
            
            print("[UI] ✅ 图片生成成功!")
            
            await MainActor.run {
                // 保存到历史记录
                let history = GenerationHistory(
                    image: result,
                    prompt: prompt,
                    mode: generationMode,
                    timestamp: Date()
                )
                generationHistory.insert(history, at: 0)
                
                generatedImage = result
                isGenerating = false
            }
            
        } catch {
            print("[UI] ❌ 错误: \(error)")
            await MainActor.run {
                if error.localizedDescription.contains("itemNotFound") {
                    errorMessage = "请先在设置中配置 API Key"
                } else {
                    errorMessage = error.localizedDescription
                }
                isGenerating = false
            }
        }
    }
    
    private func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 图片卡片
struct ImageCard: View {
    let image: UIImage
    let isDefault: Bool
    let onRemove: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDefault ? Color.blue : Color.gray.opacity(0.3), lineWidth: isDefault ? 2 : 1)
                )
            
            if isDefault {
                Text("主体")
                    .font(.caption2)
                    .padding(4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(x: -4, y: 4)
            } else if let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                }
                .offset(x: -4, y: 4)
            }
        }
    }
}

// MARK: - 快捷提示按钮
struct QuickPromptButton: View {
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(16)
        }
    }
}

// MARK: - 历史记录卡片
struct HistoryCard: View {
    let history: GenerationHistory
    let onSave: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间和模式
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(history.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(history.mode)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            // 提示词
            Text(history.prompt)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 图片
            Image(uiImage: history.image)
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
            
            // 操作按钮
            HStack(spacing: 8) {
                Button {
                    onSave()
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Button {
                    onShare()
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
