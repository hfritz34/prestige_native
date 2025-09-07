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
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
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
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(8)
                            }
                        } else if isLoadingFriends {
                            HStack(spacing: 2) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            
            // Title and subtitle
            VStack(spacing: 2) {
                Text("\(rank). \(item.name)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(TimeFormatter.formatListeningTime(item.totalTimeMilliseconds))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: item.prestigeLevel.color) ?? .blue)
            }
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
    
    // MARK: - Dynamic Sizing Based on Grid Columns
    
    private var spotifyImageSize: CGFloat {
        // **TRIED AND FAILED VALUES:**
        // iPhone 16 Pro Max: baseImageSize 110pt with 1.8x, 1.1x, 0.85x caused cutoffs and overlaps
        
        let screenWidth = UIScreen.main.bounds.width
        
        // More moderate base sizing - smaller than previous attempt
        let baseImageSize: CGFloat
        switch screenWidth {
        case ..<375:    // iPhone SE 1st gen (320pt)
            baseImageSize = 60   // Conservative increase from 70 original
        case ..<390:    // iPhone SE 2nd/3rd, iPhone 8-13 mini (375pt)
            baseImageSize = 70   // Conservative increase from 80 original
        case ..<400:    // iPhone 12/13/14/15 standard (390-393pt)
            baseImageSize = 100  // Conservative increase from 85 original
        case ..<420:    // iPhone 16 Pro (402pt), iPhone 11/XR (414pt)
            baseImageSize = 105  // Conservative increase from 90 original
        case ..<440:    // iPhone 12/13/14/15 Pro Max/Plus (428-430pt)
            baseImageSize = 105   // Conservative increase from 95 original
        default:        // iPhone 16 Pro Max (440pt+)
            baseImageSize = 115   // Conservative increase from 75 original
        }
        
        // Same scaling factors as before
        let scaleFactor: CGFloat = {
            switch gridColumnCount {
            case 2: return 1.6   // Less than 1.8x
            case 3: return 1.0   // Base size, no scaling
            case 4: return 0.75  // Less than 0.85x, more conservative
            default: return 1.0
            }
        }()
        
        // iPhone 12 (390pt) special handling - maintain proportion
        if screenWidth >= 390 && screenWidth < 394 && gridColumnCount == 3 {
            return baseImageSize * 0.85  // Same ratio as before
        }
        
        return baseImageSize * scaleFactor
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
