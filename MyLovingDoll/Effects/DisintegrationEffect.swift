//
//  DisintegrationEffect.swift
//  MyLovingDoll
//
//  可定制的"灰飞烟灭"粒子消散效果
//  此版本用于项目内定制粒子参数，不影响 PhotoEffectsKit 通用版本
//

import SwiftUI

// MARK: - 配置结构

/// 灭霸效果配置
struct DisintegrationConfig {
    var maxParticleCount: Int      // 最大粒子数量
    var xScatterRange: ClosedRange<CGFloat>  // X方向飞散范围
    var yScatterRange: ClosedRange<CGFloat>  // Y方向飞散范围
    var blurRadius: CGFloat        // 模糊半径（0为无模糊）
    var duration: Double           // 动画时长（秒）
    var particleShape: ParticleShape // 粒子形状
    
    enum ParticleShape {
        case square    // 方形
        case heart     // 心形
    }
    
    // MARK: - 预设模板
    
    /// 模板1: 默认效果（当前效果）
    static let `default` = DisintegrationConfig(
        maxParticleCount: 600,
        xScatterRange: -60...(-10),
        yScatterRange: -100...(-10),
        blurRadius: 5,
        duration: 1.5,
        particleShape: .square
    )
    
    /// 模板2: 细腻粉碎（粒子更小更多）
    static let fineParticles = DisintegrationConfig(
        maxParticleCount: 1200,
        xScatterRange: -60...(-10),
        yScatterRange: -100...(-10),
        blurRadius: 5,
        duration: 1.5,
        particleShape: .square
    )
    
    /// 模板3: 爱心飘散（心形粒子，清晰，慢速）
    static let heartFloat = DisintegrationConfig(
        maxParticleCount: 600,
        xScatterRange: -60...(-10),
        yScatterRange: -100...(-10),
        blurRadius: 0,
        duration: 3.0,
        particleShape: .heart
    )
}

extension View {
    /// 添加灰飞烟灭粒子消散效果
    /// - Parameters:
    ///   - isDeleted: 是否触发消散动画
    ///   - config: 效果配置（默认使用标准模板）
    ///   - completion: 动画完成回调
    /// - Returns: 应用了消散效果的视图
    @ViewBuilder
    func customDisintegrationEffect(
        isDeleted: Bool,
        config: DisintegrationConfig = .default,
        completion: @escaping () -> ()
    ) -> some View {
        self.modifier(CustomDisintegrationEffectModifier(
            isDeleted: isDeleted,
            config: config,
            completion: completion
        ))
    }
}

fileprivate struct CustomDisintegrationEffectModifier: ViewModifier {
    var isDeleted: Bool
    var config: DisintegrationConfig
    var completion: () -> ()
    
    @State private var particles: [SnapParticle] = []
    @State private var animateEffect: Bool = false
    @State private var triggerSnapshot: Bool = false
    @State private var isDeleteCompleted: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(particles.isEmpty && !isDeleteCompleted ? 1 : 0)
            .overlay(alignment: .topLeading) {
                CustomDisintegrationEffectView(
                    particles: $particles,
                    animateEffect: $animateEffect,
                    config: config
                )
            }
            .snapshot(trigger: triggerSnapshot) { snapshot in
                Task.detached(priority: .high) {
                    try? await Task.sleep(for: .seconds(0))
                    await createParticles(snapshot)
                }
            }
            .onChange(of: isDeleted) { oldValue, newValue in
                if newValue && particles.isEmpty {
                    triggerSnapshot = true
                }
            }
    }
    
    private func createParticles(_ snapshot: UIImage) async {
        var particles: [SnapParticle] = []
        let size = snapshot.size
        let width = size.width
        let height = size.height
        
        var gridSize: Int = 1
        var rows = Int(height) / gridSize
        var columns = Int(width) / gridSize
        
        while (rows * columns) >= config.maxParticleCount {
            gridSize += 1
            rows = Int(height) / gridSize
            columns = Int(width) / gridSize
        }
        
        for row in 0...rows {
            for column in 0...columns {
                let positionX = column * gridSize
                let positionY = row * gridSize
                
                let cropRect = CGRect(x: positionX, y: positionY, width: gridSize, height: gridSize)
                let croppedImage = cropImage(snapshot, rect: cropRect)
                particles.append(.init(
                    particleImage: croppedImage,
                    particleOffset: .init(width: positionX, height: positionY),
                    shape: config.particleShape
                ))
            }
        }
        
        await MainActor.run { [particles] in
            self.particles = particles
            withAnimation(.easeInOut(duration: config.duration), completionCriteria: .logicallyComplete) {
                animateEffect = true
            } completion: {
                isDeleteCompleted = true
                self.particles = []
                completion()
            }
        }
    }
    
    private func cropImage(_ snapshot: UIImage, rect: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .low
            snapshot.draw(at: .init(x: -rect.origin.x, y: -rect.origin.y))
        }
    }
}

fileprivate struct CustomDisintegrationEffectView: View {
    @Binding var particles: [SnapParticle]
    @Binding var animateEffect: Bool
    var config: DisintegrationConfig
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(particles) { particle in
                Group {
                    if particle.shape == .heart {
                        Image(uiImage: particle.particleImage)
                            .clipShape(HeartShape())
                    } else {
                        Image(uiImage: particle.particleImage)
                    }
                }
                .offset(particle.particleOffset)
                .offset(
                    x: animateEffect ? .random(in: config.xScatterRange) : 0,
                    y: animateEffect ? .random(in: config.yScatterRange) : 0
                )
                .opacity(animateEffect ? 0 : 1)
            }
        }
        .compositingGroup()
        .blur(radius: animateEffect ? config.blurRadius : 0)
    }
}

// MARK: - 心形形状

fileprivate struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.1, y: height * 0.4),
            control2: CGPoint(x: width * 0.1, y: height * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.25),
            control1: CGPoint(x: width * 0.9, y: height * 0.75),
            control2: CGPoint(x: width * 0.9, y: height * 0.4)
        )
        
        return path
    }
}

fileprivate struct SnapParticle: Identifiable {
    var id: String = UUID().uuidString
    var particleImage: UIImage
    var particleOffset: CGSize
    var shape: DisintegrationConfig.ParticleShape = .square
}
