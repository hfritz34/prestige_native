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
    @StateObject private var progressService = PrestigeProgressService.shared
    
    // Progress data
    @State private var progressData: PrestigeProgressResponse?
    @State private var isLoadingProgress = false
    
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
                await loadProgressData()
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
            if isLoadingProgress {
                VStack(spacing: 12) {
                    HStack {
                        Text("Loading progress...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    // Skeleton progress bar
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 60, height: 16)
                                .offset(x: -40)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let progressData = progressData {
                VStack(spacing: 12) {
                    HStack {
                        if progressData.progress.isMaxLevel {
                            Text("Maximum Prestige Achieved!")
                                .font(.headline)
                                .foregroundColor(.purple)
                        } else {
                            Text("Progress to \(progressData.nextLevel?.displayName ?? "Next Level")")
                                .font(.headline)
                        }
                        Spacer()
                        Text("\(Int(progressData.progress.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    PrestigeProgressBar(
                        progressData: progressData
                    )
                    
                    if !progressData.progress.isMaxLevel, let timeEst = progressData.estimatedTimeToNext {
                        Text("\(timeEst.formattedTime) more to reach \(progressData.nextLevel?.displayName ?? "next level")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if progressData.progress.isMaxLevel {
                        Text("You've achieved the highest prestige tier for this artist!")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.8))
                    }
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
                    color: Color(hex: item.prestigeLevel.color) ?? .blue
                )
                
                // Show rating for artists
                if let rating = currentRating {
                    let ratingColor: Color = {
                        if rating.personalScore >= 6.8 {
                            return Color(hex: "#22c55e") ?? .green
                        } else if rating.personalScore >= 3.4 {
                            return Color(hex: "#eab308") ?? .yellow
                        } else {
                            return Color(hex: "#ef4444") ?? .red
                        }
                    }()
                    
                    StatCard(
                        title: "Rating",
                        value: String(format: "%.1f", rating.personalScore),
                        icon: "star.fill",
                        color: ratingColor
                    )
                } else {
                    StatCard(
                        title: "Rating",
                        value: "No Rating",
                        icon: "star",
                        color: .gray
                    )
                }
                
                StatCard(
                    title: "Play Count",
                    value: "\(Int(item.totalTimeMilliseconds / 1000 / 60 / 3))",
                    icon: "play.fill",
                    color: .blue
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
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.gray)
                    )
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
                
                // Share button moved up
                Button(action: {
                    showingShareSheet = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                        Text("Share")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
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
    
    
    private func formatTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    /// Load prestige progress data for the current artist
    private func loadProgressData() async {
        isLoadingProgress = true
        
        // Use real API now that backend is implemented
        let progress = await progressService.fetchUserProgress(
            itemId: item.spotifyId,
            itemType: item.contentType
        )
        
        await MainActor.run {
            if let progress = progress {
                print("✅ Using real API progress data for \(item.name): \(progress.progress.percentage)%")
                withAnimation(.easeInOut(duration: 0.6)) {
                    progressData = progress
                }
            } else {
                // Fallback to mock data for development if API fails
                print("⚠️ API failed, falling back to mock data for \(item.name)")
                if let mockProgress = progressService.generateMockProgress(for: item) {
                    print("🎭 Using deterministic mock progress: \(mockProgress.progress.percentage)%")
                    withAnimation(.easeInOut(duration: 0.6)) {
                        progressData = mockProgress
                    }
                }
            }
            isLoadingProgress = false
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