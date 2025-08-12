//
//  CelebrationView.swift
//  Celebration animation for top-rated items
//

import SwiftUI

struct CelebrationView: View {
    @State private var particles: [Particle] = []
    @State private var animateParticles = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                        .offset(
                            x: animateParticles ? particle.endX : particle.startX,
                            y: animateParticles ? particle.endY : particle.startY
                        )
                        .opacity(animateParticles ? 0 : 1)
                        .scaleEffect(animateParticles ? 0.3 : 1.0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                createParticles(in: geometry.size)
                withAnimation(.easeOut(duration: 2.0)) {
                    animateParticles = true
                }
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                startX: size.width / 2,
                startY: size.height / 2,
                endX: CGFloat.random(in: -size.width...size.width),
                endY: CGFloat.random(in: -size.height...size.height),
                color: [Color.yellow, Color.orange, Color.purple, Color.blue, Color.pink].randomElement()!,
                size: CGFloat.random(in: 8...20)
            )
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let color: Color
    let size: CGFloat
}

struct ParticleView: View {
    let particle: Particle
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: ["star.fill", "sparkle", "star.circle.fill"].randomElement()!)
            .font(.system(size: particle.size))
            .foregroundColor(particle.color)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black
        CelebrationView()
    }
}