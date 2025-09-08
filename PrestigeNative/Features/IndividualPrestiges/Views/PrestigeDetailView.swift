//
//  PrestigeDetailView.swift
//  Individual Prestige Detail View
//
//  Displays detailed information about a prestige item including
//  progress to next tier, total time, and statistics.
//

import SwiftUI

struct PrestigeDetailView: View {
    let item: PrestigeDisplayItem
    let rank: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var isPinned: Bool = false
    @State private var showFriendComparison = false
    @State private var isPlaying = false
    @StateObject private var ratingViewModel = RatingViewModel()
    @StateObject private var pinService = PinService.shared
    @StateObject private var progressService = PrestigeProgressService.shared
    
    // Progress data
    @State private var progressData: PrestigeProgressResponse?
    @State private var isLoadingProgress = false
    
    // Album tracks data
    @State private var albumTracksResponse: AlbumTracksWithRankingsResponse?
    @State private var isLoadingAlbumTracks = false
    @State private var showAllTracks = false
    
    // Artist albums data
    @State private var artistAlbumsResponse: ArtistAlbumsWithRankingsResponse?
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
                    // Header with artwork
                    headerSection
                    
                    // Prestige info and progress
                    prestigeInfoSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Album tracks section (only for albums)
                    if item.contentType == .albums {
                        albumTracksSection
                    }
                    
                    // Artist albums section (only for artists)
                    if item.contentType == .artists {
                        artistAlbumsSection
                    }
                    
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
            .sheet(isPresented: $showFriendComparison) {
                FriendComparisonModalView(
                    item: item,
                    itemType: getItemTypeString()
                )
            }
        }
        .onAppear {
            Task {
                // Inject AuthManager into RatingViewModel
                ratingViewModel.setAuthManager(AuthManager.shared)
                
                await loadItemRating()
                await pinService.loadPinnedItems()
                await loadProgressData()
            }
            isPinned = pinService.isItemPinned(itemId: item.spotifyId, itemType: item.contentType)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Artwork with prestige background
            ZStack {
                // Background container with prestige theme
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.clear)
                    .overlay(
                        Group {
                            // Prestige tier background image - full opacity with minimal transparency
                            if item.prestigeLevel != .none && !item.prestigeLevel.imageName.isEmpty {
                                Image(item.prestigeLevel.imageName)
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
                    url: item.imageUrl,
                    placeholder: Image(systemName: item.contentType.iconName),
                    contentMode: .fill,
                    maxWidth: prestigeDetailSpotifySize,
                    maxHeight: prestigeDetailSpotifySize
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 8)
            }
            .frame(width: prestigeDetailBackgroundSize, height: prestigeDetailBackgroundSize)
            
            // Title and subtitle
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Now playing indicator
                    if isPlaying && item.contentType == .tracks {
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
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                .padding()
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
                        Text("You've achieved the highest prestige tier for this item!")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.8))
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .background(
                    ZStack {
                        Color(UIColor.systemBackground)
                            .opacity(0.8)
                        Color.white.opacity(0.05)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                )
                .cornerRadius(12)
                .shadow(color: Theme.shadowLight, radius: 3, x: 0, y: 2)
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
                
                // For tracks: show album position instead of rating
                if item.contentType == .tracks {
                    if let position = item.albumPosition {
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
                    // For albums and artists: show rating
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
    
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Action buttons based on content type
            HStack(spacing: 12) {
                // Pin button (for all content types)
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
                    .background(
                        ZStack {
                            if isPinned {
                                Theme.primarySoft
                            } else {
                                Color(UIColor.systemBackground)
                                    .opacity(0.7)
                            }
                            
                            // Glass effect
                            Color.white.opacity(0.1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPinned ? Theme.primary.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .foregroundColor(isPinned ? Theme.primary : .primary)
                    .cornerRadius(10)
                    .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
                }
                
                // Compare with friends (for all content types) - only if user has listening time
                Button(action: {
                    showFriendComparison = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: item.totalTimeMilliseconds > 0 ? "person.2.fill" : "person.2.slash")
                            .font(.title3)
                        Text(item.totalTimeMilliseconds > 0 ? "Compare" : "No Data")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            item.totalTimeMilliseconds > 0 ? Color(UIColor.systemBackground).opacity(0.7) : Color.gray.opacity(0.3)
                            Color.white.opacity(0.1)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(item.totalTimeMilliseconds > 0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.5), lineWidth: 0.5)
                    )
                    .foregroundColor(item.totalTimeMilliseconds > 0 ? .primary : .secondary)
                    .cornerRadius(10)
                    .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
                }
                .disabled(item.totalTimeMilliseconds == 0)
                
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
            
            // Play/Open on Spotify
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: item.spotifyId,
                    type: item.contentType
                )
                withAnimation {
                    isPlaying = true
                }
            }) {
                HStack {
                    Image(systemName: item.contentType == .tracks ? "play.fill" : "arrow.up.right.square")
                    Text(item.contentType == .tracks ? "Play on Spotify" : "Open on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
        }
    }
    
    // MARK: - Rating Properties and Methods
    
    private var currentRating: Rating? {
        let itemType = getRatingItemType()
        return ratingViewModel.userRatings[itemType.rawValue]?.first { $0.itemId == item.spotifyId }
    }
    
    private func getRatingItemType() -> RatingItemType {
        switch item.contentType {
        case .tracks: return .track
        case .albums: return .album
        case .artists: return .artist
        }
    }
    
    private func loadItemRating() async {
        let itemType = getRatingItemType()
        ratingViewModel.selectedItemType = itemType
        await ratingViewModel.loadUserRatings()
    }
    
    
    private func getItemTypeString() -> String {
        switch item.contentType {
        case .tracks: return "track"
        case .albums: return "album"
        case .artists: return "artist"
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
        guard let progress = progressData,
              progress.hasNextLevel,
              let nextLevel = progress.nextLevel,
              let timeEst = progress.estimatedTimeToNext else {
            return nil
        }
        
        return (
            percentage: progress.progress.percentage,
            nextTier: nextLevel.toPrestigeLevel(),
            remainingTime: timeEst.formattedTime
        )
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
    
    /// Load prestige progress data for the current item
    private func loadProgressData() async {
        isLoadingProgress = true
        
        // Use real API now that backend is implemented
        let progress = await progressService.fetchUserProgress(
            itemId: item.spotifyId,
            itemType: item.contentType
        )
        
        await MainActor.run {
            if let progress = progress {
                print("✅ PrestigeDetailView: Using real API progress data for \(item.name)")
                print("✅ PrestigeDetailView: Tier: \(progress.currentLevel.displayName), Progress: \(progress.progress.percentage)%")
                withAnimation(.easeInOut(duration: 0.6)) {
                    progressData = progress
                }
            } else {
                // Fallback to mock data for development if API fails
                print("⚠️ PrestigeDetailView: API failed, falling back to mock data for \(item.name)")
                if let mockProgress = progressService.generateMockProgress(for: item) {
                    print("🎭 PrestigeDetailView: Using deterministic mock progress: \(mockProgress.progress.percentage)%")
                    withAnimation(.easeInOut(duration: 0.6)) {
                        progressData = mockProgress
                    }
                } else {
                    print("❌ PrestigeDetailView: Failed to generate mock data for \(item.name)")
                }
            }
            isLoadingProgress = false
        }
    }
    
    // MARK: - Album Tracks Section
    
    private var albumTracksSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Album Tracks")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if albumTracksResponse != nil {
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
                    
                    Text("Loading album tracks...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let tracksResponse = albumTracksResponse, showAllTracks {
                LazyVStack(spacing: 8) {
                    ForEach(tracksResponse.tracks.indices, id: \.self) { index in
                        let track = tracksResponse.tracks[index]
                        HStack(spacing: 12) {
                            // Album ranking
                            if let ranking = track.albumRanking {
                                Text("🏆 #\(ranking)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.primary)
                                    .frame(width: 40, alignment: .leading)
                            } else {
                                Text("\(track.trackNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .center)
                            }
                            
                            // Track info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.trackName)
                                    .font(.subheadline)
                                    .fontWeight(track.hasUserRating ? .semibold : .medium)
                                    .lineLimit(1)
                                
                                Text(track.artists.map { $0.name }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Status indicators
                            HStack(spacing: 4) {
                                if track.isPinned {
                                    Text("📌")
                                        .font(.caption)
                                }
                                if track.isFavorite {
                                    Text("❤️")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            track.hasUserRating 
                                ? Color(UIColor.secondarySystemBackground)
                                : Color(UIColor.tertiarySystemBackground).opacity(0.7)
                        )
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else if albumTracksResponse == nil {
                Button(action: {
                    loadAlbumTracks()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllTracks = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show All Tracks")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("View album track rankings")
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
    
    // MARK: - Artist Albums Section
    
    private var artistAlbumsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rated Albums")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if artistAlbumsResponse != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllAlbums.toggle()
                        }
                    }) {
                        Text(showAllAlbums ? "Hide Albums" : "Show Rated Albums")
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
                    
                    Text("Loading rated albums...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let albumsResponse = artistAlbumsResponse, !albumsResponse.albums.isEmpty, showAllAlbums {
                LazyVStack(spacing: 8) {
                    ForEach(Array(albumsResponse.albums.enumerated()), id: \.element.id) { index, album in
                        HStack(spacing: 12) {
                            // Album rank
                            Text("#\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.primary)
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
                                    
                                    Text("\(album.trackCount) tracks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Rating
                            if let rating = album.albumRatingScore {
                                RatingBadge(score: rating, size: .small)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else if let albumsResponse = artistAlbumsResponse, albumsResponse.albums.isEmpty {
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
            } else if artistAlbumsResponse == nil {
                Button(action: {
                    loadArtistAlbums()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllAlbums = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.stack")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Rated Albums")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("View artist album rankings")
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
    
    // MARK: - Data Loading Methods
    
    private func loadAlbumTracks() {
        isLoadingAlbumTracks = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else {
                    print("No user ID available for loading album tracks")
                    await MainActor.run {
                        isLoadingAlbumTracks = false
                    }
                    return
                }
                
                let tracksResponse = try await APIClient.shared.getAlbumTracksWithRankings(
                    userId: userId,
                    albumId: item.spotifyId
                )
                
                await MainActor.run {
                    albumTracksResponse = tracksResponse
                    isLoadingAlbumTracks = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading album tracks: \(error)")
                    albumTracksResponse = nil
                    isLoadingAlbumTracks = false
                }
            }
        }
    }
    
    private func loadArtistAlbums() {
        isLoadingArtistAlbums = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else {
                    print("No user ID available for loading artist albums")
                    await MainActor.run {
                        isLoadingArtistAlbums = false
                    }
                    return
                }
                
                let albumsResponse = try await APIClient.shared.getArtistAlbumsWithUserActivity(
                    userId: userId,
                    artistId: item.spotifyId
                )
                
                await MainActor.run {
                    artistAlbumsResponse = albumsResponse
                    isLoadingArtistAlbums = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading artist albums: \(error)")
                    artistAlbumsResponse = nil
                    isLoadingArtistAlbums = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PrestigeProgressBar: View {
    let progressData: PrestigeProgressResponse
    
    @State private var animatedProgress: Double = 0
    @State private var isMaxTier = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track with modern flat design
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                // Progress fill with multicolor gradient (web-like)
                if isMaxTier {
                    // Max prestige - vibrant purple gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.8),
                                    Color(red: 0.8, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width, height: 20)
                } else {
                    // Multi-tier gradient from current to next level
                    RoundedRectangle(cornerRadius: 8)
                        .fill(multiColorGradient)
                        .frame(
                            width: max(12, geometry.size.width * animatedProgress),
                            height: 20
                        )
                }
                
            }
        }
        .frame(height: 20)
        .onAppear {
            isMaxTier = progressData.progress.isMaxLevel
            
            // Animate progress fill
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                animatedProgress = clampedProgress
            }
            
        }
        .onChange(of: progressData.progressValue) { oldValue, newValue in
            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = clampedProgress
            }
        }
        .onChange(of: progressData.progress.isMaxLevel) { oldValue, newValue in
            isMaxTier = newValue
        }
    }
    
    private var clampedProgress: Double {
        let progress = progressData.progressValue
        let safeProgress = progress.isNaN || progress.isInfinite ? 0 : progress
        return max(0, min(1, safeProgress))
    }
    
    private var multiColorGradient: LinearGradient {
        let currentColor = Color(hex: progressData.currentLevel.color) ?? .blue
        let nextColor = progressData.nextLevel != nil ? 
            Color(hex: progressData.nextLevel!.color) ?? .green : currentColor
        
        return LinearGradient(
            colors: [currentColor, nextColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
}

// MARK: - Extensions

extension ContentType {
    var iconName: String {
        switch self {
        case .tracks: return "music.note"
        case .albums: return "square.stack"
        case .artists: return "music.mic"
        }
    }
}


#Preview {
    PrestigeDetailView(
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
        rank: 1
    )
}