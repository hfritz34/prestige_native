//
//  ArtistDetailView.swift
//  Individual Artist Detail View with Album List
//
//  Shows artist information with expandable album list, pin functionality,
//  and prestige level similar to Prestige.web artist pages.
//

import SwiftUI

struct ArtistDetailView: View {
    let item: PrestigeDisplayItem
    let rank: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var isPinned: Bool = false
    @State private var showComparisonView = false
    @State private var isPlaying = false
    @StateObject private var ratingViewModel = RatingViewModel()
    @StateObject private var pinService = PinService.shared
    @State private var ratedAlbumsResponse: ArtistAlbumsWithRankingsResponse?
    @State private var isLoadingAlbums = false
    @State private var showAllAlbums = true
    @StateObject private var friendComparisonCache = FriendComparisonCache.shared
    @StateObject private var friendsService = FriendsService()
    @State private var friendsWhoListened: [FriendResponse] = []
    @State private var showingFriendComparison = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with artwork
                    headerSection
                    
                    // Prestige info and progress
                    prestigeInfoSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Rated Albums Section
                    ratedAlbumsSection
                    
                    // Friend comparison section
                    friendComparisonSection
                    
                    // Rating Section
                    ratingSection
                    
                    // Actions
                    actionButtons
                }
                .padding()
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
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $ratingViewModel.showRatingModal) {
                RatingModal()
                    .environmentObject(ratingViewModel)
            }
            .sheet(isPresented: $showingFriendComparison) {
                FriendComparisonSheet(
                    item: PrestigeItem(
                        id: item.spotifyId,
                        name: item.name,
                        imageUrl: item.imageUrl,
                        itemType: .artist
                    ),
                    friends: friendsWhoListened
                )
            }
        }
        .onAppear {
            Task {
                // Inject AuthManager into RatingViewModel
                await ratingViewModel.setAuthManager(AuthManager.shared)
                
                await loadItemRating()
                await loadRatedAlbums()
                await loadFriendsWhoListened()
                await pinService.loadPinnedItems()
            }
            isPinned = pinService.isItemPinned(itemId: item.spotifyId, itemType: item.contentType)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Artist artwork (circular for artists)
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.mic")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .shadow(radius: 8)
            
            // Artist name and subtitle
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if isPinned {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Artist rank
                Text("Artist Rank #\(rank)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var prestigeInfoSection: some View {
        VStack(spacing: 20) {
            // Current prestige badge
            PrestigeBadge(
                tier: item.prestigeLevel
            )
            .scaleEffect(1.3)
            
            // Progress to next tier
            if let progress = progressToNextTier {
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress to \(progress.nextTier.displayName)")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(progress.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    PrestigeProgressBar(
                        progress: progress.percentage / 100,
                        currentTier: item.prestigeLevel,
                        nextTier: progress.nextTier
                    )
                    
                    Text("\(progress.remainingTime) more to reach \(progress.nextTier.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8)
            ], spacing: 12) {
                StatCard(
                    title: "Minutes",
                    value: TimeFormatter.formatListeningTime(item.totalTimeMilliseconds),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Prestige Level",
                    value: item.prestigeLevel.displayName,
                    icon: "star.fill",
                    color: Color(hex: item.prestigeLevel.color) ?? .blue
                )
                
                StatCard(
                    title: "Rated Albums",
                    value: "\(ratedAlbumsResponse?.ratedAlbums ?? 0)",
                    icon: "square.stack.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var ratedAlbumsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Rated Albums")
                    .font(.headline)
                
                Spacer()
                
                if let response = ratedAlbumsResponse, !response.albums.isEmpty {
                    Button(showAllAlbums ? "Hide Albums" : "Show Albums") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllAlbums.toggle()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Albums content
            if isLoadingAlbums {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    
                    Text("Loading rated albums...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let response = ratedAlbumsResponse, !response.albums.isEmpty, showAllAlbums {
                LazyVStack(spacing: 8) {
                    ForEach(Array(sortedAlbums.enumerated()), id: \.element.id) { index, album in
                        RatedAlbumRow(
                            album: album,
                            rank: index + 1
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else if let response = ratedAlbumsResponse, response.albums.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No Rated Albums")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Rate albums by this artist to see them here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var friendComparisonSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Friends")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !friendsWhoListened.isEmpty {
                    Button("Compare") {
                        showingFriendComparison = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if friendsWhoListened.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("None of your friends have listened to this artist yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                // Friends who listened preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(friendsWhoListened.prefix(5)) { friend in
                            FriendListenedPreview(friend: friend)
                                .onTapGesture {
                                    showingFriendComparison = true
                                }
                        }
                        
                        if friendsWhoListened.count > 5 {
                            Button(action: {
                                showingFriendComparison = true
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        
                                        Text("+\(friendsWhoListened.count - 5)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text("more")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Summary text
                Text("\(friendsWhoListened.count) friend\(friendsWhoListened.count == 1 ? "" : "s") listened to this artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var ratingSection: some View {
        VStack(spacing: 16) {
            Text("Rating")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let rating = currentRating {
                // Show existing rating
                ratedItemView(rating)
            } else {
                // Show rate button
                unratedItemView
            }
        }
    }
    
    private func ratedItemView(_ rating: Rating) -> some View {
        VStack(spacing: 16) {
            // Rating display
            HStack {
                RatingBadge(score: rating.personalScore, size: .large)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let category = rating.category {
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Score: \(rating.displayScore)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Rate Again") {
                    Task {
                        await startRatingFlow()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("Remove Rating") {
                    Task {
                        await removeCurrentRating()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var unratedItemView: some View {
        Button(action: {
            Task {
                await startRatingFlow()
            }
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Rate this Artist")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Artist-specific action buttons
            HStack(spacing: 12) {
                // Pin button
                Button(action: {
                    togglePin()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.title3)
                        Text(isPinned ? "Pinned" : "Pin")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPinned ? Color.yellow : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(isPinned ? .black : .primary)
                    .cornerRadius(10)
                }
                
                // Compare with friends
                Button(action: {
                    showComparisonView = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                        Text("Compare")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // View discography
                Button(action: {
                    // Navigate to discography
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "music.note.list")
                            .font(.title3)
                        Text("Albums")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Open on Spotify
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: item.spotifyId,
                    type: item.contentType
                )
            }) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Artist on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Share button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Artist")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadRatedAlbums() async {
        await MainActor.run { isLoadingAlbums = true }
        
        do {
            guard let userId = AuthManager.shared.user?.id else {
                print("❌ ArtistDetail: No user ID available for loading rated albums")
                await MainActor.run { isLoadingAlbums = false }
                return
            }
            
            print("🔵 ArtistDetail: Loading rated albums for userId: \(userId), artistId: \(item.spotifyId)")
            
            let albumsResponse = try await APIClient.shared.getArtistAlbumsWithUserActivity(
                userId: userId,
                artistId: item.spotifyId
            )
            
            print("✅ ArtistDetail: Successfully loaded rated albums - count: \(albumsResponse.albums.count)")
            print("🔵 ArtistDetail: Albums response: \(albumsResponse)")
            
            await MainActor.run {
                ratedAlbumsResponse = albumsResponse
                isLoadingAlbums = false
            }
        } catch {
            print("❌ ArtistDetail: Error loading rated albums: \(error)")
            print("❌ ArtistDetail: Error details: \(error.localizedDescription)")
            
            if let apiError = error as? APIError {
                print("❌ ArtistDetail: API Error type: \(apiError)")
            }
            
            await MainActor.run {
                ratedAlbumsResponse = nil
                isLoadingAlbums = false
            }
        }
    }
    
    private func loadFriendsWhoListened() async {
        guard let userId = AuthManager.shared.user?.id else {
            print("No user ID available for loading friends who listened")
            return
        }
        
        let friends = await friendComparisonCache.getFriendsWhoListenedTo(
            itemType: "artist",
            itemId: item.spotifyId,
            userId: userId
        )
        
        await MainActor.run {
            self.friendsWhoListened = friends
        }
        
        // Preload friend times for the first 5 friends for better performance
        let firstFiveFriends = friends.prefix(5).map { $0.friendId }
        if !firstFiveFriends.isEmpty {
            await friendComparisonCache.loadFriendTimesForItem(
                itemType: "artist",
                itemId: item.spotifyId,
                friendIds: firstFiveFriends
            )
        }
    }
    
    // MARK: - Rating Properties and Methods
    
    private var currentRating: Rating? {
        let itemType = getRatingItemType()
        return ratingViewModel.userRatings[itemType.rawValue]?.first { $0.itemId == item.spotifyId }
    }
    
    private var sortedAlbums: [ArtistAlbumWithRating] {
        return ratedAlbumsResponse?.albums.sorted { first, second in
            // Sort by rating score (highest to lowest)
            // Handle nil ratings by putting them at the end
            switch (first.albumRatingScore, second.albumRatingScore) {
            case let (.some(firstScore), .some(secondScore)):
                return firstScore > secondScore
            case (.some(_), .none):
                return true  // Rated albums come before unrated
            case (.none, .some(_)):
                return false // Unrated albums go to the end
            case (.none, .none):
                return false // Keep original order for unrated albums
            }
        } ?? []
    }
    
    private func getRatingItemType() -> RatingItemType {
        return .artist
    }
    
    private func loadItemRating() async {
        let itemType = getRatingItemType()
        await ratingViewModel.loadUserRatings()
        ratingViewModel.selectedItemType = itemType
    }
    
    private func startRatingFlow() async {
        let ratingItemData = RatingItemData(
            id: item.spotifyId,
            name: item.name,
            imageUrl: item.imageUrl,
            artists: nil,
            albumName: nil,
            albumId: nil,
            itemType: getRatingItemType()
        )
        
        await ratingViewModel.startRating(for: ratingItemData)
    }
    
    private func removeCurrentRating() async {
        if let rating = currentRating {
            await ratingViewModel.deleteRating(rating)
        }
    }
    
    // MARK: - Action Methods
    
    private func togglePin() {
        Task {
            let newPinState = await pinService.togglePin(
                itemId: item.spotifyId,
                itemType: item.contentType
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPinned = newPinState
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var progressToNextTier: (percentage: Double, nextTier: PrestigeLevel, remainingTime: String)? {
        // Progress calculation disabled - all prestige logic moved to backend
        return nil
    }
    
    private func formatTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Supporting Views

/// Small friend preview for friends who listened section (reused from AlbumDetailView)
struct FriendListenedPreview: View {
    let friend: FriendResponse
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile picture
            if let profilePicUrl = friend.profilePicUrl {
                CachedAsyncImage(
                    url: profilePicUrl,
                    placeholder: Image(systemName: "person.crop.circle.fill")
                )
                .artistImage(size: 50)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Name
            Text(friend.nickname ?? friend.name)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 60)
        }
    }
}

struct RatedAlbumRow: View {
    let album: ArtistAlbumWithRating
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Album rank
            Text("\(rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .frame(width: 24, alignment: .center)
            
            // Album artwork
            AsyncImage(url: URL(string: album.albumImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "square.stack")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Album info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.albumName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let releaseDate = album.releaseDate, !releaseDate.isEmpty {
                        Text(String(releaseDate.prefix(4)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let ratedTracks = album.ratedTracks, let totalTracks = album.totalTracks {
                        Text("\(ratedTracks)/\(totalTracks) tracks rated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No track data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Rating and stats
            VStack(alignment: .trailing, spacing: 2) {
                if let rating = album.albumRatingScore {
                    RatingBadge(score: rating, size: .small)
                }
                
                if let position = album.albumRatingPosition {
                    Text("Rank #\(position)")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ArtistDetailView(
        item: PrestigeDisplayItem(
            name: "The Beatles",
            subtitle: "Rock • Liverpool",
            imageUrl: "https://example.com/beatles.jpg",
            totalTimeMilliseconds: 3600000,
            prestigeLevel: .gold,
            spotifyId: "3WrFJ7ztbogyGnTHbHJFl2",
            contentType: .artists,
            albumPosition: nil,
            rating: 9.2,
            isPinned: false,
            albumId: nil,
            albumName: nil
        ),
        rank: 1
    )
}