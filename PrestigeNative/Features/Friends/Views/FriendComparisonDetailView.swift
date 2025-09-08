//
//  FriendComparisonDetailView.swift
//  Enhanced comparison view showing detailed friend vs user data
//

import SwiftUI

struct FriendComparisonDetailView: View {
    let comparison: EnhancedItemComparisonResponse
    @Environment(\.dismiss) private var dismiss
    
    // Computed properties for consistent sizing with 19:20 ratio
    private var headerBackgroundSize: CGFloat {
        return 120  // Header image background size
    }
    
    private var headerSpotifySize: CGFloat {
        return headerBackgroundSize * (17.0 / 20.0)  // 17:20 ratio
    }
    
    private var comparisonBackgroundSize: CGFloat {
        return 150  // Comparison card background size
    }
    
    private var comparisonSpotifySize: CGFloat {
        return comparisonBackgroundSize * (17.0 / 20.0)  // 17:20 ratio
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with item info
                    headerSection
                    
                    // Side-by-side comparison
                    comparisonSection
                    
                    // Detailed stats comparison
                    detailedStatsSection
                }
                .padding()
            }
            .navigationTitle("Prestige Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Item artwork
            CachedAsyncImage(
                url: comparison.itemImageUrl,
                placeholder: Image(systemName: getItemTypeIcon()),
                contentMode: .fill
            )
            .frame(width: headerSpotifySize, height: headerSpotifySize)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            
            // Item name and type
            VStack(spacing: 4) {
                Text(comparison.itemName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(comparison.itemType.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var comparisonSection: some View {
        VStack(spacing: 20) {
            Text("You vs \(comparison.friendNickname)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Side-by-side visual comparison (like demo/rating flow)
            HStack(alignment: .center, spacing: 20) {
                // User card (matching home page 3-column design)
                VStack(spacing: 6) {
                    ZStack {
                        // Prestige background (matching home page design)
                        if let userTier = comparison.userStats.prestigeTier,
                           let prestigeLevel = PrestigeLevel(rawValue: userTier),
                           prestigeLevel != .none && !prestigeLevel.imageName.isEmpty {
                            Image(prestigeLevel.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.8)
                                .scaleEffect(1.1)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Item artwork (matching home page design)
                        CachedAsyncImage(
                            url: comparison.itemImageUrl,
                            placeholder: Image(systemName: getItemTypeIcon()),
                            contentMode: .fill
                        )
                        .frame(width: comparisonSpotifySize, height: comparisonSpotifySize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        // Prestige badge at bottom (matching home page)
                        if let userTier = comparison.userStats.prestigeTier,
                           let prestigeLevel = PrestigeLevel(rawValue: userTier) {
                            VStack {
                                Spacer()
                                PrestigeBadge(tier: prestigeLevel, showText: false)
                                    .scaleEffect(0.8)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .frame(width: comparisonBackgroundSize, height: comparisonBackgroundSize)
                    .aspectRatio(1, contentMode: .fit)
                    
                    // User info (matching home page design)
                    VStack(spacing: 2) {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if let listeningTime = comparison.userStats.listeningTime {
                            Text(TimeFormatter.formatListeningTime(listeningTime * 1000))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    Color(hex: comparison.userStats.prestigeTier.flatMap { PrestigeLevel.fromBackendTier($0).color } ?? "#6B7280") ?? .purple
                                )
                        }
                    }
                }
                
                // VS Indicator (using same design as rating comparison)
                VersusIndicator()
                
                // Friend card (matching home page 3-column design)
                VStack(spacing: 6) {
                    ZStack {
                        // Prestige background (matching home page design)
                        if let friendTier = comparison.friendStats.prestigeTier,
                           let prestigeLevel = PrestigeLevel(rawValue: friendTier),
                           prestigeLevel != .none && !prestigeLevel.imageName.isEmpty {
                            Image(prestigeLevel.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.8)
                                .scaleEffect(1.1)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Item artwork (matching home page design)
                        CachedAsyncImage(
                            url: comparison.itemImageUrl,
                            placeholder: Image(systemName: getItemTypeIcon()),
                            contentMode: .fill
                        )
                        .frame(width: comparisonSpotifySize, height: comparisonSpotifySize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        // Prestige badge at bottom (matching home page)
                        if let friendTier = comparison.friendStats.prestigeTier,
                           let prestigeLevel = PrestigeLevel(rawValue: friendTier) {
                            VStack {
                                Spacer()
                                PrestigeBadge(tier: prestigeLevel, showText: false)
                                    .scaleEffect(0.8)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .frame(width: comparisonBackgroundSize, height: comparisonBackgroundSize)
                    .aspectRatio(1, contentMode: .fit)
                    
                    // Friend info (matching home page design)
                    VStack(spacing: 2) {
                        Text(comparison.friendNickname)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if let listeningTime = comparison.friendStats.listeningTime {
                            Text(TimeFormatter.formatListeningTime(listeningTime * 1000))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    Color(hex: comparison.friendStats.prestigeTier.flatMap { PrestigeLevel.fromBackendTier($0).color } ?? "#6B7280") ?? .purple
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var detailedStatsSection: some View {
        VStack(spacing: 16) {
            Text("Stats Comparison")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Side-by-side stats cards
            HStack(spacing: 16) {
                // User stats column
                VStack(spacing: 12) {
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        // Always show 3 stats in consistent order
                        
                        // 1. Listening Time (always first)
                        StatComparisonCard(
                            title: "Time",
                            value: comparison.userStats.listeningTime != nil ? 
                                TimeFormatter.formatListeningTime(comparison.userStats.listeningTime! * 1000) : "N/A",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        // 2. Rating or Position (based on item type)
                        if comparison.itemType.lowercased() == "track" {
                            // For tracks: show position/ranking
                            StatComparisonCard(
                                title: "Position",
                                value: comparison.userStats.position != nil ? "#\(comparison.userStats.position!)" : "N/A",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        } else {
                            // For albums/artists: show rating
                            StatComparisonCard(
                                title: "Rating",
                                value: comparison.userStats.ratingScore != nil ? 
                                    String(format: "%.1f", comparison.userStats.ratingScore!) : "Not rated",
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                        
                        // 3. Play Count (placeholder for now since we don't have this data yet)
                        StatComparisonCard(
                            title: "Plays",
                            value: "N/A",
                            icon: "play.fill",
                            color: .green
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Friend stats column
                VStack(spacing: 12) {
                    Text(comparison.friendNickname)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        // Always show 3 stats in consistent order
                        
                        // 1. Listening Time (always first)
                        StatComparisonCard(
                            title: "Time",
                            value: comparison.friendStats.listeningTime != nil ? 
                                TimeFormatter.formatListeningTime(comparison.friendStats.listeningTime! * 1000) : "N/A",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        // 2. Rating or Position (based on item type)
                        if comparison.itemType.lowercased() == "track" {
                            // For tracks: show position/ranking
                            StatComparisonCard(
                                title: "Position",
                                value: comparison.friendStats.position != nil ? "#\(comparison.friendStats.position!)" : "N/A",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        } else {
                            // For albums/artists: show rating
                            StatComparisonCard(
                                title: "Rating",
                                value: comparison.friendStats.ratingScore != nil ? 
                                    String(format: "%.1f", comparison.friendStats.ratingScore!) : "Not rated",
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                        
                        // 3. Play Count (placeholder for now since we don't have this data yet)
                        StatComparisonCard(
                            title: "Plays",
                            value: "N/A",
                            icon: "play.fill",
                            color: .green
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Helper Methods
    
    private func getItemTypeIcon() -> String {
        switch comparison.itemType.lowercased() {
        case "track": return "music.note"
        case "album": return "square.stack"
        case "artist": return "music.mic"
        default: return "music.note"
        }
    }
    
}

// MARK: - Supporting Views

struct StatComparisonCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

struct ComparisonBar: View {
    let title: String
    let userValue: Double
    let friendValue: Double
    let userLabel: String
    let friendLabel: String
    let friendName: String
    let maxValue: Double?
    let isInverted: Bool
    
    init(title: String, userValue: Double, friendValue: Double, userLabel: String, friendLabel: String, friendName: String, maxValue: Double? = nil, isInverted: Bool = false) {
        self.title = title
        self.userValue = userValue
        self.friendValue = friendValue
        self.userLabel = userLabel
        self.friendLabel = friendLabel
        self.friendName = friendName
        self.maxValue = maxValue
        self.isInverted = isInverted
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // User bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("You")
                            .font(.caption)
                            .foregroundColor(Theme.primary)
                        if isUserWinner {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.primary)
                                .frame(
                                    width: geometry.size.width * userPercentage,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                    
                    Text(userLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isUserWinner ? 
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(colors: [.clear], startPoint: .center, endPoint: .center),
                            lineWidth: isUserWinner ? 1 : 0
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isUserWinner ? .white.opacity(0.05) : .clear)
                        )
                )
                
                // Friend bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(friendName)
                            .font(.caption)
                            .foregroundColor(.green)
                        if isFriendWinner {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.green)
                                .frame(
                                    width: geometry.size.width * friendPercentage,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                    
                    Text(friendLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isFriendWinner ? 
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(colors: [.clear], startPoint: .center, endPoint: .center),
                            lineWidth: isFriendWinner ? 1 : 0
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isFriendWinner ? .white.opacity(0.05) : .clear)
                        )
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var isUserWinner: Bool {
        if isInverted {
            return userValue < friendValue
        } else {
            return userValue > friendValue
        }
    }
    
    private var isFriendWinner: Bool {
        if isInverted {
            return friendValue < userValue
        } else {
            return friendValue > userValue
        }
    }
    
    private var userPercentage: Double {
        let max = maxValue ?? Swift.max(userValue, friendValue)
        return max > 0 ? userValue / max : 0
    }
    
    private var friendPercentage: Double {
        let max = maxValue ?? Swift.max(userValue, friendValue)
        return max > 0 ? friendValue / max : 0
    }
}

#Preview {
    FriendComparisonDetailView(
        comparison: EnhancedItemComparisonResponse(
            itemId: "sample-item-id",
            itemType: "album",
            itemName: "A Night at the Opera",
            itemImageUrl: "https://example.com/album.jpg",
            friendId: "friend123",
            friendNickname: "Alex",
            userStats: UserComparisonStats(
                listeningTime: 7200,
                ratingScore: 8.5,
                position: 5,
                prestigeTier: "Gold"
            ),
            friendStats: UserComparisonStats(
                listeningTime: 9600,
                ratingScore: 9.2,
                position: 2,
                prestigeTier: "Emerald"
            )
        )
    )
}

