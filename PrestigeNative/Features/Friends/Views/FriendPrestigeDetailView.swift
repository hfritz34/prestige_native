//
//  FriendPrestigeDetailView.swift
//  Friend's Prestige Detail View - Identical UI to user's own prestige views
//

import SwiftUI

struct FriendPrestigeDetailView: View {
    let friendPrestigeItem: PrestigeDisplayItem
    let friendName: String
    let friendId: String
    let rank: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendProfileViewModel = FriendProfileViewModel()
    @StateObject private var progressService = PrestigeProgressService.shared
    @State private var showingShareSheet = false
    @State private var showFriendComparison = false
    @State private var isPlaying = false
    @State private var comparisonData: EnhancedItemComparisonResponse?
    
    // Progress data for friend
    @State private var friendProgressData: PrestigeProgressResponse?
    @State private var isLoadingProgress = false
    
    // Album tracks data (for friend's albums)
    @State private var friendAlbumTracks: [FriendTrackRankingResponse] = []
    @State private var isLoadingAlbumTracks = false
    @State private var showAllTracks = false
    
    // Artist albums data (for friend's artists)
    @State private var friendArtistAlbums: [FriendAlbumRatingResponse] = []
    @State private var isLoadingArtistAlbums = false
    @State private var showAllAlbums = false
    
    // Computed properties for consistent sizing with 19:20 ratio
    private var prestigeDetailBackgroundSize: CGFloat {
        return 220  // Detail view background frame size
    }
    
    private var prestigeDetailSpotifySize: CGFloat {
        return prestigeDetailBackgroundSize * (17.0 / 20.0)  // 17:20 ratio
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with artwork - IDENTICAL to PrestigeDetailView
                    friendHeaderSection
                    
                    // Prestige info and progress - IDENTICAL to PrestigeDetailView
                    prestigeInfoSection
                    
                    // Statistics - IDENTICAL to PrestigeDetailView
                    statisticsSection
                    
                    // Album tracks section (only for albums) - IDENTICAL layout
                    if friendPrestigeItem.contentType == .albums {
                        friendAlbumTracksSection
                    }
                    
                    // Artist albums section (only for artists) - IDENTICAL layout
                    if friendPrestigeItem.contentType == .artists {
                        friendArtistAlbumsSection
                    }
                    
                    // Actions - Adapted for friend context
                    friendActionButtons
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
            .sheet(isPresented: $showFriendComparison) {
                if let comparison = comparisonData {
                    FriendComparisonDetailView(comparison: comparison)
                }
            }
        }
        .task {
            await loadFriendSpecificData()
        }
    }
    
    // MARK: - View Components (Reusing PrestigeDetailView Design)
    
    private var friendHeaderSection: some View {
        VStack(spacing: 16) {
            // Artwork with prestige background - IDENTICAL to PrestigeDetailView
            ZStack {
                // Background container with prestige theme
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.clear)
                    .overlay(
                        Group {
                            // Prestige tier background image - full opacity with minimal transparency
                            if friendPrestigeItem.prestigeLevel != .none && !friendPrestigeItem.prestigeLevel.imageName.isEmpty {
                                Image(friendPrestigeItem.prestigeLevel.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaleEffect(1.2)
                                    .opacity(0.8)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Main artwork
                CachedAsyncImage(
                    url: friendPrestigeItem.imageUrl,
                    placeholder: Image(systemName: friendPrestigeItem.contentType.iconName),
                    contentMode: .fit
                )
                .frame(width: prestigeDetailSpotifySize, height: prestigeDetailSpotifySize)
                .cornerRadius(14)
                .shadow(radius: 8)
            }
            .frame(width: prestigeDetailBackgroundSize, height: prestigeDetailBackgroundSize)
            
            // Title and subtitle with friend context
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(friendPrestigeItem.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Now playing indicator
                    if isPlaying && friendPrestigeItem.contentType == .tracks {
                        HStack(spacing: 4) {
                            Text("🎵")
                                .font(.footnote)
                            Text("Now Playing")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.primary.opacity(0.12))
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Text(friendPrestigeItem.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Friend context indicator
                Text("From \(friendName)'s Library")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.primary.opacity(0.15))
                    .cornerRadius(12)
            }
        }
    }
    
    private var prestigeInfoSection: some View {
        VStack(spacing: 20) {
            // Current prestige badge - IDENTICAL to PrestigeDetailView
            PrestigeBadge(
                tier: friendPrestigeItem.prestigeLevel
            )
            .scaleEffect(1.3)
            
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
                    value: TimeFormatter.formatListeningTime(friendPrestigeItem.totalTimeMilliseconds),
                    icon: "clock.fill",
                    color: Color(hex: friendPrestigeItem.prestigeLevel.color) ?? .blue
                )
                
                // For tracks: show album position instead of rating
                if friendPrestigeItem.contentType == .tracks {
                    if let position = friendPrestigeItem.albumPosition {
                        StatCard(
                            title: "Album Rank",
                            value: "#\(position)",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                    } else {
                        StatCard(
                            title: "Album Rank",
                            value: "N/A",
                            icon: "trophy",
                            color: .gray
                        )
                    }
                } else {
                    // For albums and artists: show friend's rating
                    if let rating = friendPrestigeItem.rating {
                        let ratingColor: Color = {
                            if rating >= 6.8 {
                                return Color(hex: "#22c55e") ?? .green
                            } else if rating >= 3.4 {
                                return Color(hex: "#eab308") ?? .yellow
                            } else {
                                return Color(hex: "#ef4444") ?? .red
                            }
                        }()
                        
                        StatCard(
                            title: "\(friendName)'s Rating",
                            value: String(format: "%.1f", rating),
                            icon: "star.fill",
                            color: ratingColor
                        )
                    } else {
                        StatCard(
                            title: "\(friendName)'s Rating",
                            value: "No Rating",
                            icon: "star",
                            color: .gray
                        )
                    }
                }
                
                StatCard(
                    title: "Play Count",
                    value: "\(Int(friendPrestigeItem.totalTimeMilliseconds / 1000 / 60 / 3))",
                    icon: "play.fill",
                    color: .blue
                )
            }
        }
    }
    
    
    private var friendActionButtons: some View {
        VStack(spacing: 16) {
            // Action buttons adapted for friend context
            HStack(spacing: 12) {
                // Friend's Pin Status (read-only)
                Button(action: {}) {
                    VStack(spacing: 4) {
                        Image(systemName: friendPrestigeItem.isPinned ? "pin.fill" : "pin")
                            .font(.title3)
                        Text(friendPrestigeItem.isPinned ? "Friend's Pin" : "Not Pinned")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if friendPrestigeItem.isPinned {
                                Theme.primarySoft
                            } else {
                                Color(UIColor.systemBackground)
                                    .opacity(0.7)
                            }
                            Color.white.opacity(0.1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(friendPrestigeItem.isPinned ? Theme.primary.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .foregroundColor(friendPrestigeItem.isPinned ? Theme.primary : .secondary)
                    .cornerRadius(10)
                    .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
                }
                .disabled(true) // Read-only for friend's data
                
                // Enhanced Compare with friend - only if friend has listening time
                Button(action: {
                    Task {
                        await loadComparisonData()
                        showFriendComparison = true
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: friendPrestigeItem.totalTimeMilliseconds > 0 ? "arrow.left.arrow.right" : "arrow.left.arrow.right.slash")
                            .font(.title3)
                        Text(friendPrestigeItem.totalTimeMilliseconds > 0 ? "Compare" : "No Data")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            friendPrestigeItem.totalTimeMilliseconds > 0 ? Theme.primarySoft : Color.gray.opacity(0.3)
                            Color.white.opacity(0.1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(friendPrestigeItem.totalTimeMilliseconds > 0 ? Theme.primary.opacity(0.3) : Color.gray.opacity(0.5), lineWidth: 0.5)
                    )
                    .foregroundColor(friendPrestigeItem.totalTimeMilliseconds > 0 ? Theme.primary : .secondary)
                    .cornerRadius(10)
                    .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
                }
                .disabled(friendPrestigeItem.totalTimeMilliseconds == 0)
                
                // Share button moved up as third button
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
                    .background(
                        ZStack {
                            Color(UIColor.systemBackground)
                                .opacity(0.7)
                            Color.white.opacity(0.1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
                }
            }
            
            // Play/Open on Spotify - IDENTICAL to PrestigeDetailView
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: friendPrestigeItem.spotifyId,
                    type: friendPrestigeItem.contentType
                )
                withAnimation {
                    isPlaying = true
                }
            }) {
                HStack {
                    Image(systemName: friendPrestigeItem.contentType == .tracks ? "play.fill" : "arrow.up.right.square")
                    Text(friendPrestigeItem.contentType == .tracks ? "Play on Spotify" : "Open on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
        }
    }
    
    // MARK: - Friend Album Tracks Section
    
    private var friendAlbumTracksSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Track Rankings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !friendAlbumTracks.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllTracks.toggle()
                        }
                    }) {
                        Text(showAllTracks ? "Hide Tracks" : "Show All Tracks")
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
            }
            
            if isLoadingAlbumTracks {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                    
                    Text("Loading \(friendName)'s track rankings...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if !friendAlbumTracks.isEmpty && showAllTracks {
                LazyVStack(spacing: 8) {
                    ForEach(friendAlbumTracks.indices, id: \.self) { index in
                        let track = friendAlbumTracks[index]
                        FriendTrackRankingRow(track: track, friendName: friendName)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            } else if friendAlbumTracks.isEmpty {
                Button(action: {
                    loadFriendAlbumTracks()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllTracks = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Track Rankings")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("View \(friendName)'s track rankings in this album")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Friend Artist Albums Section
    
    private var friendArtistAlbumsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Album Rankings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !friendArtistAlbums.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllAlbums.toggle()
                        }
                    }) {
                        Text(showAllAlbums ? "Hide Albums" : "Show All Albums")
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
            }
            
            if isLoadingArtistAlbums {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                    
                    Text("Loading \(friendName)'s album rankings...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if !friendArtistAlbums.isEmpty && showAllAlbums {
                LazyVStack(spacing: 8) {
                    ForEach(Array(friendArtistAlbums.enumerated()), id: \.element.id) { index, album in
                        FriendAlbumRankingRow(album: album, friendName: friendName, rank: index + 1)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else if friendArtistAlbums.isEmpty {
                Button(action: {
                    loadFriendArtistAlbums()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllAlbums = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.stack")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Album Rankings")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("View \(friendName)'s album rankings for this artist")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            Task {
                await loadFriendProgressData()
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
    
    /// Load prestige progress data for the friend's item
    private func loadFriendProgressData() async {
        isLoadingProgress = true
        
        // Use real API for friend progress
        let progress = await progressService.fetchFriendProgress(
            friendId: friendId,
            itemId: friendPrestigeItem.spotifyId,
            itemType: friendPrestigeItem.contentType
        )
        
        await MainActor.run {
            if let progress = progress {
                withAnimation(.easeInOut(duration: 0.6)) {
                    friendProgressData = progress
                }
            } else {
                // Fallback to mock data for development if API fails
                if let mockProgress = progressService.generateMockProgress(for: friendPrestigeItem) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        friendProgressData = mockProgress
                    }
                }
            }
            isLoadingProgress = false
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadFriendSpecificData() async {
        // Set up friend profile view model with friend data
        friendProfileViewModel.friend = FriendResponse(
            id: friendId,
            name: friendName,
            nickname: friendName,
            profilePicUrl: nil,
            bio: nil,
            isVerified: false, // Default to false for friend data
            friendshipDate: nil,
            mutualFriends: nil,
            status: nil,
            favoriteTracks: nil,
            favoriteAlbums: nil,
            favoriteArtists: nil,
            topTracks: nil,
            topAlbums: nil,
            topArtists: nil,
            ratedTracks: nil,
            ratedAlbums: nil,
            ratedArtists: nil,
            recentlyPlayed: nil
        )
    }
    
    private func loadFriendAlbumTracks() {
        isLoadingAlbumTracks = true
        
        Task {
            let tracks = await friendProfileViewModel.getFriendAlbumTracks(albumId: friendPrestigeItem.spotifyId)
            await MainActor.run {
                friendAlbumTracks = tracks
                isLoadingAlbumTracks = false
            }
        }
    }
    
    private func loadFriendArtistAlbums() {
        isLoadingArtistAlbums = true
        
        Task {
            let albums = await friendProfileViewModel.getFriendArtistAlbums(artistId: friendPrestigeItem.spotifyId)
            await MainActor.run {
                friendArtistAlbums = albums
                isLoadingArtistAlbums = false
            }
        }
    }
    
    private func loadComparisonData() async {
        // Only proceed if friend has listening time (button should be disabled otherwise)
        guard friendPrestigeItem.totalTimeMilliseconds > 0 else {
            print("Cannot compare - friend has no listening time for this item")
            return
        }
        
        let itemType = friendPrestigeItem.contentType == .tracks ? "track" : 
                      friendPrestigeItem.contentType == .albums ? "album" : "artist"
        
        let comparison = await friendProfileViewModel.getEnhancedComparison(
            itemId: friendPrestigeItem.spotifyId,
            itemType: itemType
        )
        
        // Check if both users have listening time before showing comparison
        if let comparison = comparison,
           let userTime = comparison.userStats.listeningTime,
           let friendTime = comparison.friendStats.listeningTime,
           userTime > 0 && friendTime > 0 {
            comparisonData = comparison
        } else {
            print("Cannot compare - one or both users have no listening time for this item")
            // Could show an alert here if needed
        }
    }
}