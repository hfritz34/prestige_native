//
//  StatCard.swift
//  Profile stat card component
//
//  Displays a single statistic with icon and value.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    HStack {
        StatCard(title: "Listening Time", value: "125h", icon: "clock.fill", color: .blue)
        StatCard(title: "Top Prestige", value: "Gold", icon: "star.fill", color: .purple)
        StatCard(title: "Artists", value: "42", icon: "music.mic", color: .orange)
    }
    .padding()
}