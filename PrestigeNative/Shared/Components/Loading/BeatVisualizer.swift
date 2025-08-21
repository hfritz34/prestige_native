//
//  BeatVisualizer.swift
//  Animated Beat Visualizer Component
//
//  Recreates the React beat visualizer with animated bars
//  that pulse to a beat with purple theme variations
//

import SwiftUI

// MARK: - Beat Visualizer

struct BeatVisualizer: View {
    let isPlaying: Bool
    @State private var animationPhase: Double = 0
    
    init(isPlaying: Bool = true) {
        self.isPlaying = isPlaying
    }
    
    // Create 32 bars with different delays and purple variations
    private var bars: [(delay: Double, color: Color)] {
        return (0..<32).map { index in
            // Calculate purple variations - base purple hue is around 280
            let hue = 280 + Double(index % 4) * 5 // Purple hue with slight variations
            let saturation = 0.75 + Double(index % 3) * 0.08 // Varying saturation
            let brightness = 0.6 + Double(index % 3) * 0.1 // Varying brightness
            
            let color = Color(hue: hue / 360.0, saturation: saturation, brightness: brightness)
            let delay = Double(index % 8) * 0.15 // Staggered animation delays
            
            return (delay: delay, color: color)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Beat visualizer bars
            HStack(spacing: 3) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    BarView(
                        color: bar.color,
                        delay: bar.delay,
                        isPlaying: isPlaying,
                        index: index
                    )
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 20)
            
            // Loading text
            Text("Music is loading")
                .font(.subheadline)
                .italic()
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Individual Bar View

struct BarView: View {
    let color: Color
    let delay: Double
    let isPlaying: Bool
    let index: Int
    
    @State private var barHeight: CGFloat = 8
    @State private var animationOffset: Double = 0
    
    private var baseHeight: CGFloat { 8 }
    private var maxHeight: CGFloat { 80 }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        color,
                        color.opacity(0.7),
                        color.opacity(0.9)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: barHeight)
            .shadow(color: color.opacity(0.5), radius: 2, y: 1)
            .animation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: barHeight
            )
            .onAppear {
                if isPlaying {
                    startAnimation()
                }
            }
            .onChange(of: isPlaying) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
    }
    
    private func startAnimation() {
        // Create varied animation patterns for each bar
        let heightVariation = CGFloat.random(in: 0.3...1.0)
        let animatedHeight = baseHeight + (maxHeight - baseHeight) * heightVariation
        
        // Start the continuous animation
        withAnimation(
            .easeInOut(duration: 0.4 + Double.random(in: -0.1...0.1))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            barHeight = animatedHeight
        }
        
        // Add secondary animation for more organic movement
        Timer.scheduledTimer(withTimeInterval: 1.2 + delay, repeats: true) { _ in
            guard isPlaying else { return }
            
            let newHeightVariation = CGFloat.random(in: 0.2...1.0)
            let newAnimatedHeight = baseHeight + (maxHeight - baseHeight) * newHeightVariation
            
            withAnimation(
                .easeInOut(duration: 0.6 + Double.random(in: -0.2...0.2))
            ) {
                barHeight = newAnimatedHeight
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            barHeight = baseHeight
        }
    }
}

// MARK: - Compact Beat Visualizer

struct CompactBeatVisualizer: View {
    let isPlaying: Bool
    
    init(isPlaying: Bool = true) {
        self.isPlaying = isPlaying
    }
    
    // Smaller version with fewer bars
    private var bars: [(delay: Double, color: Color)] {
        return (0..<12).map { index in
            let hue = 280 + Double(index % 3) * 8
            let saturation = 0.8 + Double(index % 2) * 0.1
            let brightness = 0.65 + Double(index % 2) * 0.15
            
            let color = Color(hue: hue / 360.0, saturation: saturation, brightness: brightness)
            let delay = Double(index % 4) * 0.2
            
            return (delay: delay, color: color)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                CompactBarView(
                    color: bar.color,
                    delay: bar.delay,
                    isPlaying: isPlaying
                )
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Compact Bar View

struct CompactBarView: View {
    let color: Color
    let delay: Double
    let isPlaying: Bool
    
    @State private var barHeight: CGFloat = 4
    
    private var baseHeight: CGFloat { 4 }
    private var maxHeight: CGFloat { 24 }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: 3, height: barHeight)
            .onAppear {
                if isPlaying {
                    startCompactAnimation()
                }
            }
            .onChange(of: isPlaying) { _, newValue in
                if newValue {
                    startCompactAnimation()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        barHeight = baseHeight
                    }
                }
            }
    }
    
    private func startCompactAnimation() {
        let heightVariation = CGFloat.random(in: 0.4...1.0)
        let animatedHeight = baseHeight + (maxHeight - baseHeight) * heightVariation
        
        withAnimation(
            .easeInOut(duration: 0.3)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            barHeight = animatedHeight
        }
    }
}

// MARK: - Loading Overlay with Beat Visualizer

struct BeatVisualizerLoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                BeatVisualizer(isPlaying: true)
                
                // Optional custom message
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Preview Provider

#Preview("Beat Visualizer") {
    VStack(spacing: 40) {
        BeatVisualizer(isPlaying: true)
        
        CompactBeatVisualizer(isPlaying: true)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Loading Overlay") {
    BeatVisualizerLoadingView(message: "Syncing your music library...")
        .preferredColorScheme(.dark)
}