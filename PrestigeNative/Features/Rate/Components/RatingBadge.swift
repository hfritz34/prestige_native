//
//  RatingBadge.swift
//  Rating Badge Component
//

import SwiftUI
import Foundation

struct RatingBadge: View {
    let score: Double
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var emojiSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .title3
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }
    
    private var backgroundColor: Color {
        if score >= 6.8 {
            return Color(hex: "#22c55e") ?? .green
        } else if score >= 3.4 {
            return Color(hex: "#eab308") ?? .yellow
        } else {
            return Color(hex: "#ef4444") ?? .red
        }
    }
    
    private var emoji: String {
        if score >= 7 {
            return "⭐"
        } else if score >= 4 {
            return "👍"
        } else {
            return "👎"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(size.emojiSize)
            
            Text(String(format: "%.1f", score))
                .font(size.fontSize)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(size.padding)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }
}

// MARK: - Compact Rating Badge

struct CompactRatingBadge: View {
    let score: Double
    
    private var color: Color {
        if score >= 6.8 {
            return Color(hex: "#22c55e") ?? .green
        } else if score >= 3.4 {
            return Color(hex: "#eab308") ?? .yellow
        } else {
            return Color(hex: "#ef4444") ?? .red
        }
    }
    
    var body: some View {
        Text(String(format: "%.1f", score))
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }
}

// MARK: - Rating Stars View

struct RatingStarsView: View {
    let score: Double
    let maxScore: Double
    let starCount: Int
    let size: CGFloat
    
    init(
        score: Double,
        maxScore: Double = 10.0,
        starCount: Int = 5,
        size: CGFloat = 20
    ) {
        self.score = score
        self.maxScore = maxScore
        self.starCount = starCount
        self.size = size
    }
    
    private var normalizedScore: Double {
        (score / maxScore) * Double(starCount)
    }
    
    private var color: Color {
        if score >= 6.8 {
            return Color(hex: "#22c55e") ?? .green
        } else if score >= 3.4 {
            return Color(hex: "#eab308") ?? .yellow
        } else {
            return Color(hex: "#ef4444") ?? .red
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<starCount, id: \.self) { index in
                StarShape()
                    .fill(starFill(for: index))
                    .frame(width: size, height: size)
            }
        }
    }
    
    private func starFill(for index: Int) -> Color {
        let fillAmount = normalizedScore - Double(index)
        
        if fillAmount >= 1 {
            return color
        } else if fillAmount > 0 {
            return color.opacity(fillAmount)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Star Shape

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        
        var path = Path()
        
        for i in 0..<10 {
            let angle = (Double(i) * .pi * 2 / 10) - .pi / 2
            let isOuter = i % 2 == 0
            let r = isOuter ? radius : innerRadius
            
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Rating Category Label

struct RatingCategoryLabel: View {
    let category: RatingCategoryModel
    let showEmoji: Bool
    
    init(category: RatingCategoryModel, showEmoji: Bool = true) {
        self.category = category
        self.showEmoji = showEmoji
    }
    
    private var backgroundColor: Color {
        Color(hex: category.colorHex) ?? .gray
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showEmoji {
                Text(category.emoji)
                    .font(.caption)
            }
            
            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }
}

// MARK: - Animated Rating Badge

struct AnimatedRatingBadge: View {
    let score: Double
    let size: RatingBadge.BadgeSize
    @State private var isAnimating = false
    
    var body: some View {
        RatingBadge(score: score, size: size)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Rating Progress Ring

struct RatingProgressRing: View {
    let score: Double
    let maxScore: Double
    let size: CGFloat
    
    init(
        score: Double,
        maxScore: Double = 10.0,
        size: CGFloat = 60
    ) {
        self.score = score
        self.maxScore = maxScore
        self.size = size
    }
    
    private var progress: Double {
        score / maxScore
    }
    
    private var color: Color {
        if score >= 6.8 {
            return Color(hex: "#22c55e") ?? .green
        } else if score >= 3.4 {
            return Color(hex: "#eab308") ?? .yellow
        } else {
            return Color(hex: "#ef4444") ?? .red
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: size / 10)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: size / 10,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            // Score text
            VStack(spacing: 0) {
                Text(String(format: "%.1f", score))
                    .font(.system(size: size / 3, weight: .bold))
                    .foregroundColor(color)
                
                Text("/\(Int(maxScore))")
                    .font(.system(size: size / 6))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Rating Badges") {
    VStack(spacing: 20) {
        // Different sizes
        HStack(spacing: 16) {
            RatingBadge(score: 9.2, size: .small)
            RatingBadge(score: 5.5, size: .medium)
            RatingBadge(score: 2.8, size: .large)
        }
        
        // Compact badges
        HStack(spacing: 16) {
            CompactRatingBadge(score: 8.7)
            CompactRatingBadge(score: 4.2)
            CompactRatingBadge(score: 1.5)
        }
        
        // Stars
        VStack(spacing: 8) {
            RatingStarsView(score: 9.0)
            RatingStarsView(score: 6.5)
            RatingStarsView(score: 3.0)
        }
        
        // Category labels
        HStack(spacing: 12) {
            RatingCategoryLabel(
                category: RatingCategoryModel(
                    id: "1",
                    name: "Loved",
                    minScore: 6.8,
                    maxScore: 10.0,
                    colorHex: "#22c55e",
                    displayOrder: 1
                )
            )
            
            RatingCategoryLabel(
                category: RatingCategoryModel(
                    id: "2",
                    name: "Liked",
                    minScore: 3.4,
                    maxScore: 6.7,
                    colorHex: "#eab308",
                    displayOrder: 2
                ),
                showEmoji: false
            )
        }
        
        // Progress rings
        HStack(spacing: 20) {
            RatingProgressRing(score: 8.5)
            RatingProgressRing(score: 5.0, size: 80)
            RatingProgressRing(score: 2.0, size: 40)
        }
        
        // Animated badge
        AnimatedRatingBadge(score: 9.8, size: .large)
    }
    .padding()
}
