//
//  SkeletonLoader.swift
//  Skeleton Loading Components
//
//  Provides skeleton loading animations for smooth content loading
//  with shimmer effects and proper layout preservation.
//

import SwiftUI

// MARK: - Skeleton Grid View

struct SkeletonGridView: View {
    let columns: Int = 3
    let rows: Int = 3
    @State private var isAnimating = false
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 16
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                SkeletonGridCard()
            }
        }
        .padding(.horizontal)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Skeleton Grid Card

struct SkeletonGridCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Card skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack(spacing: 8) {
                        // Rank badge skeleton
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Spacer()
                        }
                        
                        // Image skeleton
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        // Badge skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 20)
                    }
                    .padding(8)
                )
                .shimmer(isAnimating: $isAnimating)
            
            // Title skeleton
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .shimmer(isAnimating: $isAnimating)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 10)
                    .padding(.horizontal, 10)
                    .shimmer(isAnimating: $isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Unified Loading Overlay

struct UnifiedLoadingView: View {
    let progress: Double
    let message: String
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: 24) {
                // Logo or icon
                Image("prestige_purple")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .opacity(0.9)
                
                // Progress indicator
                VStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .frame(width: 200)
                    
                    // Loading message
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.2), value: message)
                    
                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .monospacedDigit()
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .shadow(radius: 20)
            )
        }
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @Binding var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    shimmerGradient
                        .frame(width: geometry.size.width * 3)
                        .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                        .animation(
                            .linear(duration: 2.0)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                .mask(content)
            )
    }
    
    private var shimmerGradient: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.3),
                Color.white.opacity(0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension View {
    func shimmer(isAnimating: Binding<Bool>) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - List Skeleton Views

struct SkeletonRowView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Image skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .shimmer(isAnimating: $isAnimating)
            
            // Text skeletons
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 14)
                    .shimmer(isAnimating: $isAnimating)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: $isAnimating)
            }
            
            Spacer()
            
            // Badge skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 24)
                .shimmer(isAnimating: $isAnimating)
        }
        .padding(.vertical, 8)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    let loadingState: LoadingState
    let progress: Double
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                EmptyView()
                
            case .loading:
                UnifiedLoadingView(
                    progress: progress,
                    message: message
                )
                
            case .loaded:
                EmptyView()
                
            case .error(let error):
                ErrorStateView(
                    error: error,
                    onRetry: onRetry
                )
            }
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: APIError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to Load Content")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Preview Provider

#Preview("Skeleton Grid") {
    SkeletonGridView()
        .preferredColorScheme(.dark)
}

#Preview("Unified Loading") {
    UnifiedLoadingView(
        progress: 0.65,
        message: "Loading your prestige data..."
    )
    .preferredColorScheme(.dark)
}

#Preview("Skeleton Row") {
    VStack {
        ForEach(0..<5, id: \.self) { _ in
            SkeletonRowView()
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}