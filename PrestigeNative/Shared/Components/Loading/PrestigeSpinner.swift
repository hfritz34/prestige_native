//
//  PrestigeSpinner.swift
//  Clean iOS-native loading spinner with purple theme
//
//  A beautiful, smooth spinner that matches Prestige's brand colors
//  and feels native to iOS with perfect animations.
//

import SwiftUI

struct PrestigeSpinner: View {
    @State private var isSpinning = false
    
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(size: CGFloat = 40, lineWidth: CGFloat = 4) {
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .purple.opacity(0.3),
                        .purple,
                        Color(red: 0.6, green: 0.4, blue: 1.0), // Light purple
                        .purple
                    ]),
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                value: isSpinning
            )
            .onAppear {
                isSpinning = true
            }
            .onDisappear {
                isSpinning = false
            }
    }
}

// MARK: - Size Variations

extension PrestigeSpinner {
    static func small() -> PrestigeSpinner {
        PrestigeSpinner(size: 20, lineWidth: 2)
    }
    
    static func medium() -> PrestigeSpinner {
        PrestigeSpinner(size: 40, lineWidth: 4)
    }
    
    static func large() -> PrestigeSpinner {
        PrestigeSpinner(size: 60, lineWidth: 6)
    }
}

// MARK: - Loading View with Text

struct PrestigeLoadingView: View {
    let text: String
    let size: PrestigeSpinner
    
    init(text: String = "Loading...", size: PrestigeSpinner = .medium()) {
        self.text = text
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 16) {
            size
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Inline Loading View

struct PrestigeInlineLoader: View {
    let text: String
    
    init(text: String = "Loading...") {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 12) {
            PrestigeSpinner.small()
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview("Spinner Sizes") {
    VStack(spacing: 30) {
        PrestigeSpinner.small()
        PrestigeSpinner.medium()
        PrestigeSpinner.large()
    }
    .padding()
    .background(Color(red: 1.0, green: 1.0, blue: 1.0))
}

#Preview("Loading Views") {
    VStack(spacing: 40) {
        PrestigeLoadingView(text: "Loading albums...")
        
        PrestigeInlineLoader(text: "Loading tracks...")
        
        Divider()
        
        PrestigeLoadingView(
            text: "Fetching your music data...",
            size: .large()
        )
    }
    .padding()
    .background(Color(red: 1.0, green: 1.0, blue: 1.0))
}