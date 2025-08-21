//
//  SynthesizerLoader.swift
//  Music-Themed Loading Animations
//
//  Synthesizer and waveform inspired loading animations
//  with purple theme to match the music app branding.
//

import SwiftUI

// MARK: - Synthesizer Loading View

struct SynthesizerLoadingView: View {
    let progress: Double
    let message: String
    @State private var isAnimating = false
    @State private var wavePhase: Double = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 32) {
                // Logo
                Image("prestige_purple")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .opacity(0.9)
                
                // Synthesizer Panel
                synthesizerPanel
                
                // Progress and message
                VStack(spacing: 12) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .animation(.easeInOut(duration: 0.3), value: message)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.purple.opacity(0.8))
                        .monospacedDigit()
                        .fontWeight(.medium)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .purple.opacity(0.3), radius: 20)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                isAnimating = true
                wavePhase = 2 * .pi
            }
        }
    }
    
    private var synthesizerPanel: some View {
        VStack(spacing: 16) {
            // Waveform Oscilloscope
            waveformView
            
            // Control Knobs Row
            HStack(spacing: 24) {
                synthKnob(value: progress, label: "LEVEL")
                synthKnob(value: sin(wavePhase) * 0.5 + 0.5, label: "FREQ")
                synthKnob(value: cos(wavePhase * 1.3) * 0.5 + 0.5, label: "RES")
            }
            
            // LED Progress Indicators
            ledProgressBar
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.15),
                            Color(red: 0.15, green: 0.1, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var waveformView: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                for x in stride(from: 0, through: width, by: 2) {
                    let normalizedX = x / width
                    let frequency = 4.0 + (progress * 8.0) // Frequency increases with progress
                    let amplitude = height * 0.3 * (0.5 + progress * 0.5)
                    let y = midY + sin((normalizedX * frequency * 2 * .pi) + wavePhase) * amplitude
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.purple, Color.blue, Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .shadow(color: .purple.opacity(0.5), radius: 4)
        }
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private func synthKnob(value: Double, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.2, green: 0.2, blue: 0.25),
                                Color(red: 0.1, green: 0.1, blue: 0.15)
                            ],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                
                // Knob indicator
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 2, height: 12)
                    .offset(y: -10)
                    .rotationEffect(.degrees(value * 270 - 135))
                    .shadow(color: .purple, radius: 2)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .fontWeight(.medium)
        }
    }
    
    private var ledProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                let isActive = Double(index) / 20.0 <= progress
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: 8, height: 16)
                    .shadow(
                        color: isActive ? .purple.opacity(0.6) : .clear,
                        radius: isActive ? 2 : 0
                    )
                    .scaleEffect(isActive ? 1.0 : 0.8)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05),
                        value: progress
                    )
            }
        }
    }
}

// MARK: - Spinning Synthesizer Knob

struct SpinningSynthKnob: View {
    @State private var rotation: Double = 0
    let size: CGFloat
    
    init(size: CGFloat = 60) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)
            
            // Inner knob
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.25, green: 0.2, blue: 0.35),
                            Color(red: 0.1, green: 0.1, blue: 0.2)
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: size/2
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .overlay(
                    Circle()
                        .stroke(Color.purple.opacity(0.4), lineWidth: 1)
                )
            
            // Rotating indicator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple, Color.cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: size * 0.25)
                .offset(y: -size * 0.2)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .purple, radius: 3)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Compact Loading Indicator

struct CompactSynthLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            SpinningSynthKnob(size: 24)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.purple)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview Provider

#Preview("Synthesizer Loading") {
    SynthesizerLoadingView(
        progress: 0.65,
        message: "Synchronizing your music data..."
    )
    .preferredColorScheme(.dark)
}

#Preview("Spinning Knob") {
    VStack(spacing: 30) {
        SpinningSynthKnob(size: 80)
        SpinningSynthKnob(size: 40)
        CompactSynthLoader()
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}