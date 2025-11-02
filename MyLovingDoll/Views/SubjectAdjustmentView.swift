//
//  SubjectAdjustmentView.swift
//  MyLovingDoll
//
//  VisionKit 交互式主体调整界面
//

import SwiftUI
import SwiftData
import VisionKit
import Photos
import Vision
import PhotoEffectsKit

@available(iOS 17.0, *)
struct SubjectAdjustmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let subject: Subject
    let specId: String
    
    @State private var sourceImage: UIImage?
    @State private var editedImage: UIImage? // 编辑后的图片
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showExtractionView = false // 是否显示提取组件
    
    // 编辑状态
    @State private var rotationAngle: Double = 0
    @State private var cropRect: CGRect = CGRect(x: 50, y: 100, width: 300, height: 300) // 裁剪框
    @State private var containerSize: CGSize = .zero // 容器尺寸
    
    
    var currentDisplayImage: UIImage? {
        editedImage ?? sourceImage
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !showExtractionView {
                    // 步骤 1: 显示图片 + 裁剪框 + 工具栏 + 识别按钮
                    VStack(spacing: 0) {
                        // 图片显示区域 + 可拖拽裁剪框
                        GeometryReader { geometry in
                            ZStack {
                                if let image = currentDisplayImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                } else {
                                    ProgressView("加载图片...")
                                }
                                
                                // 裁剪框蒙版
                                if sourceImage != nil {
                                    CropOverlay(
                                        cropRect: $cropRect,
                                        containerSize: geometry.size,
                                        imageSize: currentDisplayImage?.size ?? .zero
                                    )
                                }
                            }
                            .onAppear {
                                containerSize = geometry.size
                            }
                            .onChange(of: geometry.size) { oldValue, newValue in
                                containerSize = newValue
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // 编辑工具栏
                        if sourceImage != nil {
                            ImageEditToolbar(
                                rotationAngle: $rotationAngle,
                                onRotate: { angle in
                                    applyRotation(angle)
                                },
                                onReset: {
                                    resetEditing()
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                        }
                        
                        // 识别按钮
                        if sourceImage != nil {
                            Button {
                                showExtractionView = true
                            } label: {
                                Label("重新识别主体", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue.gradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                } else if let image = currentDisplayImage {
                    // 步骤 2: 使用提取组件处理所有后续流程
                    SubjectExtractionView(
                        sourceImage: image,
                        cropRect: cropRect,
                        containerSize: containerSize,
                        onConfirm: { extractedImage in
                            Task {
                                await saveAdjustedSubject(extractedImage)
                            }
                        },
                        onRetry: {
                            resetToEditMode()
                        }
                    )
                }
                
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("保存中...")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
            .navigationTitle("调整主体")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                await loadSourceImage()
            }
        }
    }
    
    private func loadSourceImage() async {
        
        // 从 PHAsset 加载原始照片
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [subject.sourceAssetId], options: nil).firstObject
        
        guard let asset = asset else {
            errorMessage = "无法找到原始照片"
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            self.sourceImage = image
        }
    }
    
    // MARK: - 图片编辑方法
    
    private func applyRotation(_ angle: Double) {
        guard let image = currentDisplayImage else { return }
        rotationAngle += angle
        editedImage = image.rotate(radians: angle)
    }
    
    private func resetEditing() {
        editedImage = nil
        rotationAngle = 0
        cropRect = CGRect(x: 50, y: 100, width: 300, height: 300)
    }
    
    /// 重置到编辑模式
    private func resetToEditMode() {
        withAnimation {
            showExtractionView = false
        }
    }
    
    private func saveAdjustedSubject(_ extractedImage: UIImage) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let service = VisionKitService(modelContext: modelContext)
            try await service.updateSubject(subject, with: extractedImage, specId: specId)
            
            // 保存成功,关闭页面
            await MainActor.run {
                dismiss()
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}
