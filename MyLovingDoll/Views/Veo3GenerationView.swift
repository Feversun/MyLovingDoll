//
//  Veo3GenerationView.swift
//  MyLovingDoll
//
//  VEO 3.1 视频生成界面
//

import SwiftUI
import PhotosUI
import AVKit

struct Veo3GenerationView: View {
    @Environment(\.dismiss) var dismiss
    
    // 模式选择
    enum GenerationMode: String, CaseIterable {
        case textToVideo = "文本生成"
        case imageToVideo = "图片转视频"
        case frameInterpolation = "帧插值"
        case multiReference = "多参考图"
        
        var icon: String {
            switch self {
            case .textToVideo: return "text.bubble"
            case .imageToVideo: return "photo.on.rectangle"
            case .frameInterpolation: return "film"
            case .multiReference: return "photo.stack"
            }
        }
    }
    
    @State private var mode: GenerationMode = .textToVideo
    @State private var prompt: String = ""
    
    // 图片选择
    @State private var firstImage: UIImage?
    @State private var lastImage: UIImage?
    @State private var referenceImages: [ReferenceImageData] = []
    @State private var showingImagePicker = false
    @State private var imagePickerType: ImagePickerType = .first
    
    enum ImagePickerType {
        case first, last, reference
    }
    
    struct ReferenceImageData: Identifiable {
        let id = UUID()
        var image: UIImage
        var type: Veo3Service.ReferenceType = .asset
    }
    
    // 配置选项
    @State private var aspectRatio: String = "16:9"
    @State private var resolution: String = "720p"
    @State private var negativePrompt: String = ""
    @State private var showAdvancedSettings = false
    
    // 生成状态
    @State private var isGenerating = false
    @State private var generatedVideoURL: URL?
    @State private var errorMessage: String?
    
    // 调试日志
    @State private var debugLogs: [String] = []
    @State private var showDebugLogs = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 模式选择
                    modeSelectionSection
                    
                    // 提示词输入
                    promptSection
                    
                    // 图片选择（根据模式显示）
                    if mode != .textToVideo {
                        imageSelectionSection
                    }
                    
                    // 高级设置
                    advancedSettingsSection
                    
                    // 生成按钮
                    generateButton
                    
                    // 调试日志
                    if showDebugLogs {
                        debugLogsSection
                    }
                    
                    // 生成结果
                    if let videoURL = generatedVideoURL {
                        videoResultSection(videoURL: videoURL)
                    }
                    
                    // 错误提示
                    if let error = errorMessage {
                        errorSection(message: error)
                    }
                }
                .padding()
            }
            .navigationTitle("VEO 3.1 视频生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showDebugLogs ? "隐藏日志" : "显示日志") {
                        showDebugLogs.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: bindingForImagePicker())
            }
        }
    }
    
    // MARK: - 模式选择
    
    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生成模式")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GenerationMode.allCases, id: \.self) { m in
                        Button {
                            mode = m
                            clearImages()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: m.icon)
                                    .font(.title2)
                                Text(m.rawValue)
                                    .font(.caption)
                            }
                            .frame(width: 90, height: 80)
                            .background(mode == m ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(mode == m ? .white : .primary)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 提示词
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("视频描述")
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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    quickPromptButton("电影级真实场景")
                    quickPromptButton("动画风格")
                    quickPromptButton("科幻场景")
                    quickPromptButton("自然风光")
                }
            }
        }
    }
    
    private func quickPromptButton(_ text: String) -> some View {
        Button(text) {
            prompt = text
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
    
    // MARK: - 图片选择
    
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图片设置")
                .font(.headline)
            
            switch mode {
            case .textToVideo:
                EmptyView()
                
            case .imageToVideo:
                imagePickerButton(
                    title: "选择起始图片",
                    image: firstImage,
                    action: { imagePickerType = .first; showingImagePicker = true }
                )
                
            case .frameInterpolation:
                VStack(spacing: 12) {
                    imagePickerButton(
                        title: "第一帧",
                        image: firstImage,
                        action: { imagePickerType = .first; showingImagePicker = true }
                    )
                    imagePickerButton(
                        title: "最后一帧",
                        image: lastImage,
                        action: { imagePickerType = .last; showingImagePicker = true }
                    )
                }
                
            case .multiReference:
                VStack(spacing: 12) {
                    ForEach(referenceImages.indices, id: \.self) { index in
                        HStack {
                            Image(uiImage: referenceImages[index].image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Picker("类型", selection: $referenceImages[index].type) {
                                Text("外观保留").tag(Veo3Service.ReferenceType.asset)
                                Text("风格参考").tag(Veo3Service.ReferenceType.style)
                            }
                            .pickerStyle(.segmented)
                            
                            Button {
                                referenceImages.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if referenceImages.count < 3 {
                        Button {
                            imagePickerType = .reference
                            showingImagePicker = true
                        } label: {
                            Label("添加参考图片 (\(referenceImages.count)/3)", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func imagePickerButton(title: String, image: UIImage?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 高级设置
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showAdvancedSettings.toggle()
                }
            } label: {
                HStack {
                    Text("高级设置")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                }
            }
            .foregroundColor(.primary)
            
            if showAdvancedSettings {
                VStack(alignment: .leading, spacing: 16) {
                    // 分辨率
                    VStack(alignment: .leading) {
                        Text("分辨率")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("分辨率", selection: $resolution) {
                            Text("720p").tag("720p")
                            Text("1080p").tag("1080p")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 宽高比
                    VStack(alignment: .leading) {
                        Text("宽高比")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("宽高比", selection: $aspectRatio) {
                            Text("16:9").tag("16:9")
                            Text("9:16").tag("9:16")
                            Text("1:1").tag("1:1")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 负面提示词
                    VStack(alignment: .leading) {
                        Text("负面提示词（避免出现的内容）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("例如：低质量、模糊、卡通风格", text: $negativePrompt)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 生成按钮
    
    private var generateButton: some View {
        Button {
            Task {
                await generateVideo()
            }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("生成中...")
                } else {
                    Image(systemName: "play.circle.fill")
                    Text("开始生成视频")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canGenerate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canGenerate || isGenerating)
    }
    
    private var canGenerate: Bool {
        guard !prompt.isEmpty else { return false }
        
        switch mode {
        case .textToVideo:
            return true
        case .imageToVideo:
            return firstImage != nil
        case .frameInterpolation:
            return firstImage != nil && lastImage != nil
        case .multiReference:
            return !referenceImages.isEmpty
        }
    }
    
    // MARK: - 调试日志
    
    private var debugLogsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("调试日志")
                    .font(.headline)
                Spacer()
                Button("清空") {
                    debugLogs.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(debugLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 视频结果
    
    private func videoResultSection(videoURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生成结果")
                .font(.headline)
            
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 300)
                .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button {
                    saveVideoToPhotos(videoURL)
                } label: {
                    Label("保存到相册", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button {
                    shareVideo(videoURL)
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 错误提示
    
    private func errorSection(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
            Spacer()
            Button("关闭") {
                errorMessage = nil
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 生成逻辑
    
    private func generateVideo() async {
        isGenerating = true
        errorMessage = nil
        generatedVideoURL = nil
        debugLogs.removeAll()
        
        addLog("[UI] 🚀 开始生成视频")
        addLog("[UI] 模式: \(mode.rawValue)")
        addLog("[UI] 提示词: \(prompt)")
        
        do {
            // 从 Keychain 读取 API Key
            addLog("[UI] 🔑 从 Keychain 读取 API Key...")
            let service = try Veo3Service.fromKeychain()
            addLog("[UI] ✅ API Key 读取成功")
            
            // 配置
            let config = Veo3Service.VideoConfig(
                aspectRatio: aspectRatio,
                resolution: resolution,
                negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt
            )
            
            addLog("[UI] ⚙️ 配置: \(aspectRatio), \(resolution)")
            
            // 根据模式生成
            let videoURL: URL
            
            switch mode {
            case .textToVideo:
                addLog("[UI] 📝 调用文本生成视频...")
                videoURL = try await service.generateVideo(prompt: prompt, config: config)
                
            case .imageToVideo:
                guard let firstImage = firstImage else { return }
                addLog("[UI] 🖼️ 调用图片转视频...")
                addLog("[UI] 图片尺寸: \(firstImage.size)")
                videoURL = try await service.generateVideo(prompt: prompt, firstImage: firstImage, config: config)
                
            case .frameInterpolation:
                guard let firstImage = firstImage, let lastImage = lastImage else { return }
                addLog("[UI] 🎬 调用帧插值...")
                addLog("[UI] 第一帧尺寸: \(firstImage.size)")
                addLog("[UI] 最后一帧尺寸: \(lastImage.size)")
                videoURL = try await service.generateVideo(prompt: prompt, firstImage: firstImage, lastImage: lastImage, config: config)
                
            case .multiReference:
                addLog("[UI] 🎨 调用多参考图生成...")
                addLog("[UI] 参考图数量: \(referenceImages.count)")
                let refs = referenceImages.map { Veo3Service.ReferenceImage(image: $0.image, type: $0.type) }
                videoURL = try await service.generateVideo(prompt: prompt, references: refs, config: config)
            }
            
            addLog("[UI] ✅ 视频生成成功")
            addLog("[UI] 本地路径: \(videoURL.path)")
            
            await MainActor.run {
                generatedVideoURL = videoURL
                isGenerating = false
            }
            
        } catch {
            addLog("[UI] ❌ 错误: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
    
    private func addLog(_ message: String) {
        Task { @MainActor in
            debugLogs.append(message)
            print(message) // 同时输出到 Xcode 控制台
        }
    }
    
    // MARK: - 辅助方法
    
    private func clearImages() {
        firstImage = nil
        lastImage = nil
        referenceImages.removeAll()
    }
    
    private func bindingForImagePicker() -> Binding<UIImage?> {
        switch imagePickerType {
        case .first:
            return $firstImage
        case .last:
            return $lastImage
        case .reference:
            return Binding(
                get: { nil },
                set: { newImage in
                    if let img = newImage {
                        referenceImages.append(ReferenceImageData(image: img))
                    }
                }
            )
        }
    }
    
    private func saveVideoToPhotos(_ url: URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
    }
    
    private func shareVideo(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
