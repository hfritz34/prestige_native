//
//  FriendComparisonDetailView.swift
//  Enhanced comparison view showing detailed friend vs user data
//

import SwiftUI

struct FriendComparisonDetailView: View {
    let comparison: EnhancedItemComparisonResponse
    @Environment(\.dismiss) private var dismiss
    
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
            .frame(width: 120, height: 120)
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
            
            HStack(spacing: 20) {
                // User stats
                VStack(spacing: 12) {
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.primary)
                    
                    VStack(spacing: 8) {
                        if let listeningTime = comparison.userStats.listeningTime {
                            StatComparisonCard(
                                title: "Listening Time",
                                value: TimeFormatter.formatListeningTime(listeningTime * 1000),
                                icon: "clock.fill",
                                color: .blue
                            )
                        }
                        
                        if let rating = comparison.userStats.ratingScore {
                            StatComparisonCard(
                                title: "Rating",
                                value: String(format: "%.1f", rating),
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                        
                        if let position = comparison.userStats.position {
                            StatComparisonCard(
                                title: "Position",
                                value: "#\(position)",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                        
                        if let tier = comparison.userStats.prestigeTier {
                            StatComparisonCard(
                                title: "Prestige",
                                value: tier,
                                icon: "crown.fill",
                                color: Color(hex: PrestigeLevel(rawValue: tier)?.color ?? "#6B7280") ?? .gray
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // VS separator
                VStack {
                    Text("VS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .frame(width: 1, height: 100)
                        .foregroundColor(.secondary)
                }
                
                // Friend stats
                VStack(spacing: 12) {
                    Text(comparison.friendNickname)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    VStack(spacing: 8) {
                        if let listeningTime = comparison.friendStats.listeningTime {
                            StatComparisonCard(
                                title: "Listening Time",
                                value: TimeFormatter.formatListeningTime(listeningTime * 1000),
                                icon: "clock.fill",
                                color: .blue
                            )
                        }
                        
                        if let rating = comparison.friendStats.ratingScore {
                            StatComparisonCard(
                                title: "Rating",
                                value: String(format: "%.1f", rating),
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                        
                        if let position = comparison.friendStats.position {
                            StatComparisonCard(
                                title: "Position",
                                value: "#\(position)",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                        
                        if let tier = comparison.friendStats.prestigeTier {
                            StatComparisonCard(
                                title: "Prestige",
                                value: tier,
                                icon: "crown.fill",
                                color: Color(hex: PrestigeLevel(rawValue: tier)?.color ?? "#6B7280") ?? .gray
                            )
                        }
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
    
    private var detailedStatsSection: some View {
        VStack(spacing: 16) {
            Text("Detailed Comparison")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Listening time comparison
                if let userTime = comparison.userStats.listeningTime,
                   let friendTime = comparison.friendStats.listeningTime {
                    ComparisonBar(
                        title: "Listening Time",
                        userValue: Double(userTime),
                        friendValue: Double(friendTime),
                        userLabel: TimeFormatter.formatListeningTime(userTime * 1000),
                        friendLabel: TimeFormatter.formatListeningTime(friendTime * 1000),
                        friendName: comparison.friendNickname
                    )
                }
                
                // Rating comparison
                if let userRating = comparison.userStats.ratingScore,
                   let friendRating = comparison.friendStats.ratingScore {
                    ComparisonBar(
                        title: "Rating",
                        userValue: userRating,
                        friendValue: friendRating,
                        userLabel: String(format: "%.1f", userRating),
                        friendLabel: String(format: "%.1f", friendRating),
                        friendName: comparison.friendNickname,
                        maxValue: 10.0
                    )
                }
                
                // Position comparison (lower is better)
                if let userPosition = comparison.userStats.position,
                   let friendPosition = comparison.friendStats.position {
                    let maxPosition = max(userPosition, friendPosition)
                    ComparisonBar(
                        title: "Position (Lower is Better)",
                        userValue: Double(maxPosition + 1 - userPosition),
                        friendValue: Double(maxPosition + 1 - friendPosition),
                        userLabel: "#\(userPosition)",
                        friendLabel: "#\(friendPosition)",
                        friendName: comparison.friendNickname,
                        maxValue: Double(maxPosition + 1),
                        isInverted: true
                    )
                }
            }
        }
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