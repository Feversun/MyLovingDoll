//
//  SubjectExtractionView.swift
//  MyLovingDoll
//
//  可复用的主体识别和动画展示组件
//  接收任意图片，执行裁剪、识别、灭霸动画、Shimmer 等完整流程
//

import SwiftUI
import Vision
import PhotoEffectsKit

@available(iOS 17.0, *)
struct SubjectExtractionView: View {
    let sourceImage: UIImage
    let cropRect: CGRect
    let containerSize: CGSize
    let onConfirm: (UIImage) -> Void
    let onRetry: () -> Void
    
    @State private var croppedImage: UIImage?
    @State private var extractedSubject: UIImage?
    @State private var isAnalyzing = false
    @State private var triggerDisintegration = false
    @State private var showSubject = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if let subject = extractedSubject {
                // 步骤 2: 显示裁剪图片 + 灭霸动画 + 主体 + Shimmer + 操作按钮
                ZStack(alignment: .bottom) {
                    // 主体显示区域
                    ZStack {
                        // 底层: 完整裁剪图（消散动画）
                        if let cropped = croppedImage {
                            Image(uiImage: cropped)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .customDisintegrationEffect(
                                    isDeleted: triggerDisintegration,
                                    config: .heartFloat  // 使用爱心飘散模板
                                ) {
                                    // 动画完成后放大主体
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                        showSubject = true
                                    }
                                }
                        }
                        
                        // 顶层: 主体（始终覆盖在上面，消散后加 Shimmer）
                        Image(uiImage: subject)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .modifier(ConditionalShimmer(
                                enabled: showSubject,
                                config: ShimmerConfig(
                                    tint: .white.opacity(0.5),
                                    highlight: .white,
                                    blur: 5,
                                    highlightOpacity: 1,
                                    speed: 2,
                                    blendMode: .normal
                                )
                            ))
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    
                    // 操作按钮 - 浮动在底部
                    if showSubject {
                        VStack(spacing: 12) {
                            // 确认保存
                            Button {
                                onConfirm(subject)
                            } label: {
                                Label("确认保存", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green.gradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            // 重新调整
                            Button {
                                onRetry()
                            } label: {
                                Label("重新调整", systemImage: "arrow.counterclockwise")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            } else if isAnalyzing {
                // 识别中
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("识别中...")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
        }
        .alert("错误", isPresented: .constant(errorMessage != nil)) {
            Button("确定") {
                errorMessage = nil
                onRetry()
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            await performExtraction()
        }
    }
    
    // MARK: - 主要流程
    
    private func performExtraction() async {
        // 1. 裁剪图片
        guard let imageCropRect = convertCropRectToImageCoordinates(
            cropRect: cropRect,
            imageSize: sourceImage.size,
            containerSize: containerSize
        ) else {
            errorMessage = "裁剪坐标转换失败"
            return
        }
        
        guard let cropped = sourceImage.crop(to: imageCropRect) else {
            errorMessage = "裁剪失败"
            return
        }
        
        await MainActor.run {
            croppedImage = cropped
            isAnalyzing = true
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        do {
            // 2. 使用 Vision 提取主体
            let subjects = try await extractSubjectsUsingVision(from: cropped)
            
            await MainActor.run {
                if subjects.isEmpty {
                    errorMessage = "未识别到主体，请尝试其他照片"
                } else {
                    // 取第一个主体
                    extractedSubject = subjects[0].0
                    
                    // 3. 稍微延迟后触发灭霸动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        triggerDisintegration = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "识别失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 将屏幕坐标系的裁剪框转换为图片坐标系
    private func convertCropRectToImageCoordinates(
        cropRect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect? {
        guard containerSize.width > 0 && containerSize.height > 0 else { return nil }
        
        // 计算图片在容器中的实际显示尺寸 (scaledToFit)
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        var displayedImageSize: CGSize
        var imageOffset: CGPoint
        
        if imageAspect > containerAspect {
            // 图片比容器更宽，以宽度为准
            displayedImageSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
            imageOffset = CGPoint(
                x: 0,
                y: (containerSize.height - displayedImageSize.height) / 2
            )
        } else {
            // 图片比容器更高，以高度为准
            displayedImageSize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
            imageOffset = CGPoint(
                x: (containerSize.width - displayedImageSize.width) / 2,
                y: 0
            )
        }
        
        // 计算缩放比例
        let scaleX = imageSize.width / displayedImageSize.width
        let scaleY = imageSize.height / displayedImageSize.height
        
        // 转换裁剪框坐标
        let imageCropRect = CGRect(
            x: (cropRect.origin.x - imageOffset.x) * scaleX,
            y: (cropRect.origin.y - imageOffset.y) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )
        
        // 限制在图片范围内
        let clampedRect = CGRect(
            x: max(0, imageCropRect.origin.x),
            y: max(0, imageCropRect.origin.y),
            width: min(imageCropRect.width, imageSize.width - max(0, imageCropRect.origin.x)),
            height: min(imageCropRect.height, imageSize.height - max(0, imageCropRect.origin.y))
        )
        
        return clampedRect
    }
    
    /// 使用 Vision 提取主体
    private func extractSubjectsUsingVision(from image: UIImage) async throws -> [(UIImage, Double)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "SubjectExtraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNInstanceMaskObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var subjects: [(UIImage, Double)] = []
                
                for observation in results {
                    do {
                        let maskedPixelBuffer = try observation.generateMaskedImage(
                            ofInstances: observation.allInstances,
                            from: handler,
                            croppedToInstancesExtent: true
                        )
                        
                        let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            subjects.append((uiImage, Double(observation.confidence)))
                        }
                    } catch {
                        print("警告: 生成主体图像失败")
                    }
                }
                
                continuation.resume(returning: subjects)
            }
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
