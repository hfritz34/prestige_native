//
//  FriendComparisonModalView.swift
//  Friend Comparison Modal
//
//  A polished SwiftUI modal that displays friend comparison data for tracks, albums, and artists.
//  Based on the web app's friend-item-modal.tsx implementation.
//

import SwiftUI

struct FriendComparisonModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendsService = FriendsService()
    
    let item: PrestigeDisplayItem
    let itemType: String // "track", "album", "artist"
    
    @State private var friendsWithItem: [FriendResponse] = []
    @State private var friendListeningData: [String: FriendListeningData] = [:]
    @State private var isLoading = false
    @State private var selectedFriend: FriendResponse?
    @State private var showingFriendDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with item info
                itemHeaderSection
                
                // Friends comparison list
                if isLoading {
                    loadingSection
                } else if friendsWithItem.isEmpty {
                    emptyStateSection
                } else {
                    friendsListSection
                }
                
                Spacer()
            }
            .navigationTitle("Friend Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .sheet(isPresented: $showingFriendDetail) {
            if let friend = selectedFriend {
                FriendDetailModalView(
                    friend: friend,
                    item: item,
                    itemType: itemType,
                    listeningData: friendListeningData[friend.id]
                )
            }
        }
        .onAppear {
            loadFriendsData()
        }
    }
    
    // MARK: - View Components
    
    private var itemHeaderSection: some View {
        VStack(spacing: 16) {
            // Item artwork
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: item.contentType.iconName)
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 100, height: 100)
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // Item info
            VStack(spacing: 8) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                Text(itemType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Finding friends who listened to this \(itemType)...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No Friends Found")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("None of your friends have listened to this \(itemType) yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    private var friendsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(friendsWithItem) { friend in
                    FriendComparisonRowView(
                        friend: friend,
                        listeningData: friendListeningData[friend.id],
                        itemType: itemType
                    ) {
                        selectedFriend = friend
                        showingFriendDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFriendsData() {
        isLoading = true
        
        Task {
            let friends: [FriendResponse]
            
            // Load friends based on item type
            switch itemType {
            case "track":
                friends = await friendsService.findFriendsWithTrack(trackId: item.spotifyId)
            case "album":
                friends = await friendsService.findFriendsWithAlbum(albumId: item.spotifyId)
            case "artist":
                friends = await friendsService.findFriendsWithArtist(artistId: item.spotifyId)
            default:
                friends = []
            }
            
            // Load listening data for each friend
            var listeningDataDict: [String: FriendListeningData] = [:]
            for friend in friends {
                if let data = await friendsService.getFriendListeningData(
                    friendId: friend.id,
                    itemType: itemType,
                    itemId: item.spotifyId
                ) {
                    listeningDataDict[friend.id] = data
                }
            }
            
            await MainActor.run {
                self.friendsWithItem = friends.sorted { (friend1, friend2) in
                    let time1 = listeningDataDict[friend1.id]?.totalTime ?? 0
                    let time2 = listeningDataDict[friend2.id]?.totalTime ?? 0
                    return time1 > time2 // Sort by listening time descending
                }
                self.friendListeningData = listeningDataDict
                self.isLoading = false
            }
        }
    }
}

// MARK: - Friend Comparison Row

struct FriendComparisonRowView: View {
    let friend: FriendResponse
    let listeningData: FriendListeningData?
    let itemType: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Friend profile picture
                AsyncImage(url: URL(string: friend.profilePicUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String(friend.name.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // Friend info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.nickname ?? friend.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let data = listeningData {
                        Text(formatListeningTime(data.totalTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Prestige tier badge
                if let data = listeningData {
                    let tier = getPrestigeTier(totalTime: data.totalTime, type: itemType)
                    PrestigeBadge(tier: tier)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func formatListeningTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        if minutes == 0 {
            return "No listening time"
        }
        
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours == 0 {
            return "\(mins)m"
        }
        return "\(hours)h \(mins)m"
    }
    
    private func getPrestigeTier(totalTime: Int, type: String) -> PrestigeLevel {
        let timeInMinutes = totalTime / 60
        
        switch type {
        case "track":
            return PrestigeCalculator.getTrackPrestigeTier(totalTimeMinutes: timeInMinutes)
        case "album":
            return PrestigeCalculator.getAlbumPrestigeTier(totalTimeMinutes: timeInMinutes)
        case "artist":
            return PrestigeCalculator.getArtistPrestigeTier(totalTimeMinutes: timeInMinutes)
        default:
            return .bronze
        }
    }
}

// MARK: - Friend Detail Modal

struct FriendDetailModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ratingViewModel = RatingViewModel()
    
    let friend: FriendResponse
    let item: PrestigeDisplayItem
    let itemType: String
    let listeningData: FriendListeningData?
    
    @State private var userRating: Rating?
    @State private var userListeningTime: Int = 0
    @State private var userProfilePicUrl: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Side-by-side comparison using the same layout as ComparisonView
                prestigeComparisonContent
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                ratingViewModel.setAuthManager(AuthManager.shared)
                await loadUserData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Prestige Comparison")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("How do you compare to \(friend.nickname ?? friend.name)?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var prestigeComparisonContent: some View {
        HStack(spacing: 20) {
            // User's side (left)
            PrestigeComparisonCard(
                title: "You",
                item: item,
                listeningTime: userListeningTime,
                itemType: itemType,
                userRating: userRating,
                isUser: true,
                hasMorePrestige: userListeningTime > (listeningData?.totalTime ?? 0),
                profileImageUrl: userProfilePicUrl
            )
            
            // VS indicator (reusing from ComparisonView)
            VersusIndicator()
            
            // Friend's side (right)
            PrestigeComparisonCard(
                title: friend.nickname ?? friend.name,
                item: item,
                listeningTime: listeningData?.totalTime ?? 0,
                itemType: itemType,
                userRating: nil, // Friends don't show rating data
                isUser: false,
                hasMorePrestige: (listeningData?.totalTime ?? 0) > userListeningTime,
                profileImageUrl: friend.profilePicUrl
            )
        }
        .padding()
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() async {
        let itemTypeEnum = getRatingItemType()
        ratingViewModel.selectedItemType = itemTypeEnum
        await ratingViewModel.loadUserRatings()
        
        // Get user's rating for this item
        userRating = ratingViewModel.userRatings[itemTypeEnum.rawValue]?.first { $0.itemId == item.spotifyId }
        
        // Get user's listening time from the item itself
        userListeningTime = Int(item.totalTimeMilliseconds / 1000)
        
        // Get user's profile picture
        userProfilePicUrl = AuthManager.shared.user?.profilePictureUrl
    }
    
    private func getRatingItemType() -> RatingItemType {
        switch item.contentType {
        case .tracks: return .track
        case .albums: return .album
        case .artists: return .artist
        }
    }
}

// MARK: - Prestige Comparison Card

struct PrestigeComparisonCard: View {
    let title: String
    let item: PrestigeDisplayItem
    let listeningTime: Int
    let itemType: String
    let userRating: Rating?
    let isUser: Bool
    let hasMorePrestige: Bool
    let profileImageUrl: String?
    
    init(title: String, item: PrestigeDisplayItem, listeningTime: Int, itemType: String, userRating: Rating?, isUser: Bool, hasMorePrestige: Bool, profileImageUrl: String? = nil) {
        self.title = title
        self.item = item
        self.listeningTime = listeningTime
        self.itemType = itemType
        self.userRating = userRating
        self.isUser = isUser
        self.hasMorePrestige = hasMorePrestige
        self.profileImageUrl = profileImageUrl
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile section - fixed height for alignment
            VStack(spacing: 8) {
                if isUser {
                    // User profile picture or fallback icon
                    if let profilePicUrl = profileImageUrl {
                        AsyncImage(url: URL(string: profilePicUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        // Fallback user icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )
                    }
                } else {
                    // Friend profile picture
                    AsyncImage(url: URL(string: profileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(String(title.prefix(1)).uppercased())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(height: 80) // Fixed height for alignment
            
            // Prestige card with tier background
            VStack(spacing: 16) {
                // Item image with prestige tier background
                ZStack {
                    // Prestige tier background
                    let prestigeLevel = getPrestigeTier(totalTime: listeningTime, type: itemType)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: prestigeLevel.color) ?? .blue,
                                    Color(hex: prestigeLevel.color)?.opacity(0.7) ?? .blue.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    // Glow effect for winner
                    if hasMorePrestige {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.yellow.opacity(0.6), radius: 8, x: 0, y: 0)
                            .shadow(color: Color.orange.opacity(0.4), radius: 16, x: 0, y: 0)
                    }
                    
                    // Item image
                    AsyncImage(url: URL(string: item.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: item.contentType.iconName)
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Crown overlay for winner
                    if hasMorePrestige {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.title3)
                                    .foregroundColor(.yellow)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 30, height: 30)
                                    )
                                    .offset(x: -5, y: 5)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Stats - consistent spacing
                VStack(spacing: 12) {
                    // Listening time
                    VStack(spacing: 4) {
                        Text("Listening Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatListeningTime(listeningTime))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    // Prestige tier badge
                    let tier = getPrestigeTier(totalTime: listeningTime, type: itemType)
                    PrestigeBadge(tier: tier)
                    
                    // Rating/Position info (only for user)
                    if isUser, let rating = userRating {
                        VStack(spacing: 4) {
                            Text(itemType == "track" ? "Position" : "Rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if itemType == "track" {
                                Text("#\(rating.position)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            } else {
                                Text(rating.displayScore)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .frame(minHeight: 140) // Consistent stats height
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        // Extra glow for winner
                        hasMorePrestige ? 
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.6), Color.orange.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        : nil
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatListeningTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        if minutes == 0 {
            return "0m"
        }
        
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours == 0 {
            return "\(mins)m"
        }
        return "\(hours)h \(mins)m"
    }
    
    private func getPrestigeTier(totalTime: Int, type: String) -> PrestigeLevel {
        let timeInMinutes = totalTime / 60
        
        switch type {
        case "track":
            return PrestigeCalculator.getTrackPrestigeTier(totalTimeMinutes: timeInMinutes)
        case "album":
            return PrestigeCalculator.getAlbumPrestigeTier(totalTimeMinutes: timeInMinutes)
        case "artist":
            return PrestigeCalculator.getArtistPrestigeTier(totalTimeMinutes: timeInMinutes)
        default:
            return .bronze
        }
    }
}


#Preview {
    FriendComparisonModalView(
        item: PrestigeDisplayItem(
            name: "Bohemian Rhapsody",
            subtitle: "Queen • A Night at the Opera",
            imageUrl: "https://example.com/image.jpg",
            totalTimeMilliseconds: 180000,
            prestigeLevel: .gold,
            spotifyId: "4u7EnebtmKWzUH433cf5Qv",
            contentType: .tracks,
            albumPosition: 2,
            rating: 8.5,
            isPinned: false,
            albumId: "sample-album-id",
            albumName: "A Night at the Opera"
        ),
        itemType: "track"
    )
}