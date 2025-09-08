//
//  PrestigeGridCard.swift
//  Grid-style prestige card for 3-column layout
//
//  Square design with prestige tier framing the artwork and small rank indicator.
//

import SwiftUI

struct PrestigeGridCard: View {
    let item: PrestigeDisplayItem
    let rank: Int
    let gridColumnCount: Int
    
    @StateObject private var friendComparisonCache = FriendComparisonCache.shared
    @State private var friendsWhoListened: [FriendResponse] = []
    @State private var showingFriendComparison = false
    @State private var isLoadingFriends = false
    
    init(item: PrestigeDisplayItem, rank: Int, gridColumnCount: Int = 3) {
        self.item = item
        self.rank = rank
        self.gridColumnCount = gridColumnCount
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Main card with artwork and prestige frame
            ZStack {
                // Prestige tier background image - fills available space
                if item.prestigeLevel != .none && !item.prestigeLevel.imageName.isEmpty {
                    Image(item.prestigeLevel.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(1.1)
                        .opacity(0.8)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(spacing: 4) {
                    // Rating badge for albums/artists only (no trophy pins for tracks)
                    HStack {
                        Spacer()
                        
                        // Show rating for albums/artists only
                        if item.contentType != .tracks, let rating = item.rating {
                            HStack(spacing: 2) {
                                Image(systemName: rating >= 7 ? "star.fill" : rating >= 4 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(rating >= 7 ? .green : rating >= 4 ? .yellow : .red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 4))
                        }
                    }
                    
                    // Album artwork without rank overlay
                    CachedAsyncImage(
                        url: item.imageUrl,
                        placeholder: Image(systemName: getIconForType()),
                        contentMode: .fill,
                        maxWidth: spotifyImageSize,
                        maxHeight: spotifyImageSize
                    )
                    .frame(width: spotifyImageSize, height: spotifyImageSize)  // Enforce strict size
                    .clipped()  // Ensure no overflow
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Prestige badge and friend count
                    HStack(spacing: 4) {
                        PrestigeBadge(tier: item.prestigeLevel, showText: false)
                            .scaleEffect(0.8)
                        
                        // Friend indicator
                        if !friendsWhoListened.isEmpty {
                            Button(action: {
                                showingFriendComparison = true
                            }) {
                                HStack(spacing: 2) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption2)
                                    Text("\(friendsWhoListened.count)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.mini)
                            .tint(.blue)
                        } else if isLoadingFriends {
                            HStack(spacing: 2) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.regularMaterial, in: .capsule)
                        }
                    }
                }
                .padding(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            
            // Title and subtitle - fixed height to prevent layout shift
            VStack(spacing: 2) {
                Text("\(rank). \(item.name)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .frame(height: 16) // Fixed height
                
                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(height: 14) // Fixed height
                
                Text(TimeFormatter.formatListeningTime(item.totalTimeMilliseconds))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: item.prestigeLevel.color) ?? .blue)
                    .frame(height: 14) // Fixed height
            }
            .frame(height: 50) // Fixed total height for text area
        }
        .onAppear {
            // Only load friend data if user actually has friends
            Task {
                let friendsService = FriendsService()
                let hasFriends = await friendsService.getFriendsCount() > 0
                if hasFriends {
                    loadFriendsWhoListened()
                }
            }
        }
        .sheet(isPresented: $showingFriendComparison) {
            FriendComparisonSheet(
                item: PrestigeItem(
                    id: item.spotifyId,
                    name: item.name,
                    imageUrl: item.imageUrl,
                    itemType: getPrestigeItemType()
                ),
                friends: friendsWhoListened
            )
            .presentationBackground(.regularMaterial)
            .presentationCornerRadius(28)
        }
    }
    
    private func getIconForType() -> String {
        if item.subtitle == "Artist" {
            return "music.mic"
        } else if item.subtitle.contains("tracks") || item.name.contains("Album") {
            return "square.stack"
        } else {
            return "music.note"
        }
    }
    
    private func getPrestigeItemType() -> PrestigeItem.PrestigeItemType {
        switch item.contentType {
        case .tracks:
            return .track
        case .albums:
            return .album
        case .artists:
            return .artist
        }
    }
    
    private func loadFriendsWhoListened() {
        guard let userId = AuthManager.shared.user?.id else {
            print("No user ID available for loading friends who listened")
            return
        }
        
        Task {
            isLoadingFriends = true
            
            let itemTypeString: String
            switch item.contentType {
            case .tracks:
                itemTypeString = "track"
            case .albums:
                itemTypeString = "album"
            case .artists:
                itemTypeString = "artist"
            }
            
            let friends = await friendComparisonCache.getFriendsWhoListenedTo(
                itemType: itemTypeString,
                itemId: item.spotifyId,
                userId: userId
            )
            
            await MainActor.run {
                self.friendsWhoListened = friends
                self.isLoadingFriends = false
            }
        }
    }
    
    // MARK: - Dynamic Sizing Based on Prestige Background Frame
    
    private var spotifyImageSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32 // Account for padding
        let spacing: CGFloat = 16 // Grid spacing
        let totalSpacing = CGFloat(gridColumnCount - 1) * spacing
        let columnWidth = (availableWidth - totalSpacing) / CGFloat(gridColumnCount)
        
        // The prestige background frame size (square)
        // This is what we want to keep consistent
        let prestigeBackgroundSize = columnWidth
        
        // Spotify image should be 7/8 the size of the prestige background
        // This maintains perfect 7:8 ratio across all devices and column layouts
        let spotifyImageSize = prestigeBackgroundSize * (19.0 / 20.0)
        
        return spotifyImageSize 
    }
}


#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
        ForEach(0..<9) { index in
            PrestigeGridCard(
                item: PrestigeDisplayItem(
                    name: "Sample Track \(index + 1)",
                    subtitle: "Sample Artist",
                    imageUrl: "",
                    totalTimeMilliseconds: (index + 1) * 120000,
                    prestigeLevel: [.bronze, .silver, .gold, .diamond][index % 4],
                    spotifyId: "sample-track-\(index + 1)",
                    contentType: .tracks,
                    albumPosition: index + 1,
                    rating: Double(7 + index % 3),
                    isPinned: index % 3 == 0,
                    albumId: nil,
                    albumName: nil
                ),
                rank: index + 1
            )
        }
    }
    .padding()
}
