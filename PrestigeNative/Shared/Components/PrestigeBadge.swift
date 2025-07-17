//
//  PrestigeBadge.swift
//  Prestige Badge Component
//
//  Shows prestige tier with appropriate styling and colors.
//

import SwiftUI

struct PrestigeBadge: View {
    let tier: PrestigeLevel
    
    var body: some View {
        HStack(spacing: 4) {
            if tier != .none {
                Circle()
                    .fill(tierColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(tier.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(tierColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tierColor.opacity(0.1))
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
        case .peridot:
            return .green
        case .gold:
            return .yellow
        case .emerald:
            return .green
        case .sapphire:
            return .blue
        case .garnet:
            return .red
        case .jet:
            return .black
        case .diamond:
            return .cyan
        case .opal:
            return .purple
        case .darkMatter:
            return .purple
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        PrestigeBadge(tier: .bronze)
        PrestigeBadge(tier: .silver)
        PrestigeBadge(tier: .gold)
        PrestigeBadge(tier: .diamond)
        PrestigeBadge(tier: .darkMatter)
    }
    .padding()
}