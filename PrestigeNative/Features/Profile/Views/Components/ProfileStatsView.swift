//
//  ProfileStatsView.swift
//  Component for displaying user statistics
//

import SwiftUI

struct ProfileStatsView: View {
    let friendsCount: Int
    let ratingsCount: Int
    let prestigesCount: Int
    
    var body: some View {
        HStack(spacing: 24) {
            StatItem(value: friendsCount, label: friendsCount == 1 ? "Friend" : "Friends")
            
            Divider()
                .frame(height: 20)
                .background(Color.secondary.opacity(0.3))
            
            StatItem(value: ratingsCount, label: "Rated")
            
            Divider()
                .frame(height: 20)
                .background(Color.secondary.opacity(0.3))
            
            StatItem(value: prestigesCount, label: prestigesCount == 1 ? "Prestige" : "Prestiges")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

private struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileStatsView(
        friendsCount: 12,
        ratingsCount: 145,
        prestigesCount: 23
    )
}