//
//  MusicWaveLoader.swift
//  Musical Wave Loading Animation
//
//  Simple, elegant synthesizer wave that flows to a beat
//  Perfect for a music app - no progress needed, just vibes
//

import SwiftUI

// MARK: - Music Wave Loader

struct MusicWaveLoader: View {
    @State private var phase: Double = 0
    @State private var beatPhase: Double = 0
    @State private var amplitude: Double = 0.5
    
    let message: String?
    let compact: Bool
    
    init(message: String? = nil, compact: Bool = false) {
        self.message = message
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactWaveView
        } else {
            fullScreenWaveView
        }
    }
    
    private var fullScreenWaveView: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo
                Image("prestige_purple")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .opacity(0.9)
                
                // Main wave animation
                waveformView(height: 120, lineWidth: 3)
                
                // Message if provided
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var compactWaveView: some View {
        HStack(spacing: 16) {
            // Mini wave
            waveformView(height: 30, lineWidth: 2)
                .frame(width: 60)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private func waveformView(height: CGFloat, lineWidth: CGFloat) -> some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let midY = size.height / 2
                
                // Create multiple wave layers for richness
                drawWave(context: context, width: width, midY: midY, 
                        frequency: 3, phase: phase, amplitude: amplitude * height * 0.3,
                        color: .purple, lineWidth: lineWidth)
                
                drawWave(context: context, width: width, midY: midY, 
                        frequency: 5, phase: phase * 1.5, amplitude: amplitude * height * 0.2,
                        color: .blue, lineWidth: lineWidth * 0.7)
                
                drawWave(context: context, width: width, midY: midY, 
                        frequency: 7, phase: phase * 0.7, amplitude: amplitude * height * 0.15,
                        color: .cyan, lineWidth: lineWidth * 0.5)
            }
        }
        .frame(height: height)
    }
    
    private func drawWave(context: GraphicsContext, width: CGFloat, midY: CGFloat,
                         frequency: Double, phase: Double, amplitude: CGFloat,
                         color: Color, lineWidth: CGFloat) {
        var path = Path()
        let stepSize: CGFloat = 2
        
        for x in stride(from: 0, through: width, by: stepSize) {
            let normalizedX = Double(x / width)
            let angle = (normalizedX * frequency * 2.0 * .pi) + phase
            let y = midY + CGFloat(sin(angle)) * amplitude
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [color.opacity(0.8), color, color.opacity(0.6)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: width, y: 0)
            ),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
        
        // Add glow effect
        context.stroke(
            path,
            with: .color(color.opacity(0.3)),
            style: StrokeStyle(lineWidth: lineWidth * 2, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func startAnimations() {
        // Continuous wave flow
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            phase = 4 * .pi
        }
        
        // Beat-like amplitude pulse (120 BPM feel)
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            amplitude = 0.8
        }
        
        // Slower beat variation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            beatPhase = .pi
        }
    }
}

// MARK: - Inline Mini Wave

struct InlineMusicWave: View {
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                
                var path = Path()
                let stepSize: CGFloat = 1
                
                for x in stride(from: 0, through: width, by: stepSize) {
                    let normalizedX = Double(x / width)
                    let angle = (normalizedX * 6.0 * 2.0 * .pi) + phase
                    let y = midY + CGFloat(sin(angle)) * height * 0.4
                    
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Color.purple.opacity(0.6), Color.purple, Color.blue]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
            }
        }
        .frame(height: 20)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                phase = 4 * .pi
            }
        }
    }
}

// MARK: - Pulsing Music Dots

struct PulsingMusicDots: View {
    @State private var pulsePhase: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0 + CGFloat(sin(pulsePhase + Double(index) * 0.5)) * 0.5)
                    .opacity(0.7 + sin(pulsePhase + Double(index) * 0.3) * 0.3)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                pulsePhase = 2 * .pi
            }
        }
    }
}

// MARK: - Usage Examples and Previews

#Preview("Full Screen Wave") {
    MusicWaveLoader(message: "Loading your music...")
        .preferredColorScheme(.dark)
}

#Preview("Compact Wave") {
    VStack(spacing: 20) {
        MusicWaveLoader(message: "Loading...", compact: true)
        
        InlineMusicWave()
            .padding()
        
        PulsingMusicDots()
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}