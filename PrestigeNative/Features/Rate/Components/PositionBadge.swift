//
//  PositionBadge.swift
//  Position Badge Component for Track Rankings
//

import SwiftUI
import Foundation

struct PositionBadge: View {
    let position: Int
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
        // Position-based coloring: top positions get better colors
        if position <= 3 {
            return Color(hex: "#fbbf24") ?? .orange  // Top 3: Gold
        } else if position <= 10 {
            return Color(hex: "#3b82f6") ?? .blue    // Top 10: Blue
        } else if position <= 20 {
            return Color(hex: "#8b5cf6") ?? .purple  // Top 20: Purple
        } else {
            return Color(hex: "#6b7280") ?? .gray    // Others: Gray
        }
    }
    
    private var emoji: String {
        if position <= 3 {
            return "🏆"
        } else if position <= 10 {
            return "🔥"
        } else {
            return "#"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(size.emojiSize)
            
            Text("\(position)")
                .font(size.fontSize)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(size.padding)
        .background(backgroundColor)
        .cornerRadius(size == .large ? 8 : 6)
        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            PositionBadge(position: 1, size: .small)
            PositionBadge(position: 5, size: .small)
            PositionBadge(position: 15, size: .small)
            PositionBadge(position: 25, size: .small)
        }
        
        HStack(spacing: 12) {
            PositionBadge(position: 1, size: .medium)
            PositionBadge(position: 5, size: .medium)
            PositionBadge(position: 15, size: .medium)
            PositionBadge(position: 25, size: .medium)
        }
        
        HStack(spacing: 12) {
            PositionBadge(position: 1, size: .large)
            PositionBadge(position: 5, size: .large)
            PositionBadge(position: 15, size: .large)
            PositionBadge(position: 25, size: .large)
        }
    }
    .padding()
}