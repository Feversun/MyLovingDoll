//
//  DisintegrationEffect.swift
//  MyLovingDoll
//
//  可定制的"灰飞烟灭"粒子消散效果
//  此版本用于项目内定制粒子参数，不影响 PhotoEffectsKit 通用版本
//

import SwiftUI

extension View {
    /// 添加灰飞烟灭粒子消散效果
    /// - Parameters:
    ///   - isDeleted: 是否触发消散动画
    ///   - completion: 动画完成回调
    /// - Returns: 应用了消散效果的视图
    @ViewBuilder
    func customDisintegrationEffect(isDeleted: Bool, completion: @escaping () -> ()) -> some View {
        self.modifier(CustomDisintegrationEffectModifier(isDeleted: isDeleted, completion: completion))
    }
}

fileprivate struct CustomDisintegrationEffectModifier: ViewModifier {
    var isDeleted: Bool
    var completion: () -> ()
    
    @State private var particles: [SnapParticle] = []
    @State private var animateEffect: Bool = false
    @State private var triggerSnapshot: Bool = false
    @State private var isDeleteCompleted: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(particles.isEmpty && !isDeleteCompleted ? 1 : 0)
            .overlay(alignment: .topLeading) {
                CustomDisintegrationEffectView(particles: $particles, animateEffect: $animateEffect)
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
        let maxGridCount: Int = 600 // 可调整: 粒子数量
        
        var gridSize: Int = 1
        var rows = Int(height) / gridSize
        var columns = Int(width) / gridSize
        
        while (rows * columns) >= maxGridCount {
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
                    particleOffset: .init(width: positionX, height: positionY)
                ))
            }
        }
        
        await MainActor.run { [particles] in
            self.particles = particles
            withAnimation(.easeInOut(duration: 1.5), completionCriteria: .logicallyComplete) {
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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(particles) { particle in
                Image(uiImage: particle.particleImage)
                    .offset(particle.particleOffset)
                    .offset(
                        x: animateEffect ? .random(in: -60...(-10)) : 0, // 可调整: X 方向飞散范围
                        y: animateEffect ? .random(in: -100...(-10)) : 0  // 可调整: Y 方向飞散范围
                    )
                    .opacity(animateEffect ? 0 : 1)
            }
        }
        .compositingGroup()
        .blur(radius: animateEffect ? 5 : 0) // 可调整: 模糊程度
    }
}

fileprivate struct SnapParticle: Identifiable {
    var id: String = UUID().uuidString
    var particleImage: UIImage
    var particleOffset: CGSize
}
