//
//  AIImageGenerationView.swift
//  MyLovingDoll
//
//  AI 图片生成视图
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct AIImageGenerationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entity: Entity
    let specId: String
    
    @State private var prompt: String = ""
    @State private var negativePrompt: String = ""
    @State private var selectedStyle: AIImageGenerationRequest.GenerationStyle = .realistic
    @State private var isGenerating = false
    @State private var generatedImage: UIImage?
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var apiKey: String = ""
    
    var sourceImage: UIImage? {
        guard let firstSubject = entity.subjects?.first else { return nil }
        return FileManager.loadImage(relativePath: firstSubject.stickerPath, specId: specId)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 源图片
                    if let sourceImage = sourceImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("源图片")
                                .font(.headline)
                            
                            Image(uiImage: sourceImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    // 提示词输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("提示词")
                            .font(.headline)
                        
                        TextEditor(text: $prompt)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // 负面提示词
                    VStack(alignment: .leading, spacing: 8) {
                        Text("负面提示词 (可选)")
                            .font(.headline)
                        
                        TextEditor(text: $negativePrompt)
                            .frame(height: 60)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // 风格选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("风格")
                            .font(.headline)
                        
                        Picker("风格", selection: $selectedStyle) {
                            Text("真实").tag(AIImageGenerationRequest.GenerationStyle.realistic)
                            Text("动漫").tag(AIImageGenerationRequest.GenerationStyle.anime)
                            Text("卡通").tag(AIImageGenerationRequest.GenerationStyle.cartoon)
                            Text("艺术").tag(AIImageGenerationRequest.GenerationStyle.artistic)
                        }
                        .pickerStyle(.segmented)
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
                            Label("生成图片", systemImage: "sparkles")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(prompt.isEmpty ? Color.gray : Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(prompt.isEmpty || isGenerating)
                    
                    // 生成结果
                    if let generatedImage = generatedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("生成结果")
                                .font(.headline)
                            
                            Image(uiImage: generatedImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                            
                            HStack {
                                Button {
                                    saveGeneratedImage(generatedImage)
                                } label: {
                                    Label("保存", systemImage: "square.and.arrow.down")
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
                    
                    // 错误提示
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
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
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AISettingsView(apiKey: $apiKey)
            }
        }
    }
    
    private func generateImage() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            // 创建 AI 服务
            let service = GeminiImageService(apiKey: apiKey)
            
            // 检查可用性
            guard await service.isAvailable() else {
                errorMessage = "请先在设置中配置 API Key"
                isGenerating = false
                return
            }
            
            // 创建请求
            let request = AIImageGenerationRequest(
                sourceImage: sourceImage,
                prompt: prompt,
                negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
                style: selectedStyle
            )
            
            // 生成图片
            let response = try await service.generateImage(request: request)
            
            await MainActor.run {
                generatedImage = response.generatedImage
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
    
    private func saveGeneratedImage(_ image: UIImage) {
        // 保存到相册或项目中
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func shareImage(_ image: UIImage) {
        // 分享功能
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

// MARK: - AI 设置视图
struct AISettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var apiKey: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                } header: {
                    Text("Gemini API 设置")
                } footer: {
                    Text("在 https://makersuite.google.com/app/apikey 获取 API Key")
                }
            }
            .navigationTitle("AI 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
