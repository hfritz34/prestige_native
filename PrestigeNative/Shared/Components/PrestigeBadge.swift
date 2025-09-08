//
//  PrestigeBadge.swift
//  Prestige Badge Component
//
//  Shows prestige tier with appropriate styling and colors.
//

import SwiftUI

struct PrestigeBadge: View {
    let tier: PrestigeLevel
    let showText: Bool
    
    init(tier: PrestigeLevel, showText: Bool = true) {
        self.tier = tier
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showText {
                if tier == .none {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(tierColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            if showText {
                Text(tier.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(tierColor)
            }
        }
        .padding(.horizontal, showText ? 8 : 0)
        .padding(.vertical, showText ? 4 : 0)
        .background(
            Capsule()
                .fill(showText ? tierColor.opacity(0.1) : Color.clear)
        )
    }
    
    private var tierColor: Color {
        switch tier {
        case .none:
            return .gray
        case .bronze:
            return .brown
        case .silver:
            return .gray
        case .gold:
            return .yellow
        case .emerald:
            return .green
        case .amber:
            return .orange
        case .amethyst:
            return .purple
        case .quartz:
            return .pink
        case .diamond:
            return .cyan
        case .jade:
            return .green
        case .ruby:
            return .red
        case .pearl:
            return .white
        case .loveydovey:
            return .pink
        case .tourmaline:
            return .purple
        case .topaz:
            return .yellow
        case .tanazanite:
            return .blue
        case .prestige:
            return .yellow
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        PrestigeBadge(tier: .bronze)
        PrestigeBadge(tier: .silver)
        PrestigeBadge(tier: .gold)
        PrestigeBadge(tier: .diamond)
        PrestigeBadge(tier: .prestige)
    }
    .padding()
}
