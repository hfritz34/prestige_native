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
    
    // Album tracks data
    @State private var albumTracksResponse: AlbumTracksWithRankingsResponse?
    @State private var isLoadingAlbumTracks = false
    @State private var showAllTracks = false
    
    // Artist albums data
    @State private var artistAlbumsResponse: ArtistAlbumsWithRankingsResponse?
    @State private var isLoadingArtistAlbums = false
    @State private var showAllAlbums = false
    
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
                    maxWidth: 180,
                    maxHeight: 180
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 8)
            }
            .frame(width: 220, height: 220)
            
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
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
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
                
                if item.contentType == .tracks, let position = item.albumPosition {
                    StatCard(
                        title: "Album Rank",
                        value: "🏆 #\(position)",
                        icon: "number.square.fill",
                        color: .yellow
                    )
                } else if item.contentType == .tracks {
                    StatCard(
                        title: "Album Rank",
                        value: "...",
                        icon: "number.square.fill",
                        color: .gray
                    )
                } else {
                    StatCard(
                        title: "Play Count",
                        value: "\(Int(item.totalTimeMilliseconds / 1000 / 60 / 3))",
                        icon: "play.fill",
                        color: .green
                    )
                }
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
            .background(
                ZStack {
                    Color(UIColor.systemBackground)
                        .opacity(0.8)
                    Color.white.opacity(0.1)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .cornerRadius(12)
            .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Rate Again") {
                    Task {
                        await startRatingFlow()
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                
                Button("Remove Rating") {
                    Task {
                        await removeCurrentRating()
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.deleteRed)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.deleteRed.opacity(0.1))
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
                Text("Rate this \(getContentTypeName())")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Theme.primary.opacity(0.9), Theme.primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    Color.white.opacity(0.1)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.primary.opacity(0.3), lineWidth: 0.5)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Theme.primary.opacity(0.2), radius: 8, x: 0, y: 4)
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
                
                // Compare with friends (for all content types)
                Button(action: {
                    showFriendComparison = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                        Text("Compare")
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
                
                // Context-specific third button
                if item.contentType == .tracks {
                    // View album for tracks
                    Button(action: {
                        // Album navigation will be implemented in future version
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.stack")
                                .font(.title3)
                            Text("Album")
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
                } else if item.contentType == .albums {
                    // View tracks for albums
                    Button(action: {
                        loadAlbumTracks()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllTracks.toggle()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.title3)
                            Text("Tracks")
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
                } else if item.contentType == .artists {
                    // View albums for artists
                    Button(action: {
                        loadArtistAlbums()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllAlbums.toggle()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.stack")
                                .font(.title3)
                            Text("Albums")
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
            
            // Share button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Prestige")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    ZStack {
                        Color(UIColor.systemBackground)
                            .opacity(0.7)
                        Color.white.opacity(0.1)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .foregroundColor(.primary)
                .cornerRadius(12)
                .shadow(color: Theme.shadowLight, radius: 4, x: 0, y: 2)
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
    
    private func startRatingFlow() async {
        let itemType = getRatingItemType()
        
        let ratingItemData = RatingItemData(
            id: item.spotifyId,
            name: item.name,
            imageUrl: item.imageUrl,
            artists: item.contentType == .tracks ? [item.subtitle.components(separatedBy: " • ").first ?? ""] : nil,
            albumName: item.albumName,
            albumId: item.albumId,
            itemType: itemType
        )
        
        await ratingViewModel.startRating(for: ratingItemData)
    }
    
    private func removeCurrentRating() async {
        if let rating = currentRating {
            await ratingViewModel.deleteRating(rating)
        }
    }
    
    private func getContentTypeName() -> String {
        switch item.contentType {
        case .tracks: return "Track"
        case .albums: return "Album"
        case .artists: return "Artist"
        }
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
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.tertiarySystemBackground))
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
                            .foregroundColor(Theme.primary)
                        
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
                            .foregroundColor(Theme.primary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.primary.opacity(0.2), lineWidth: 1)
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
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.tertiarySystemBackground))
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
                            .foregroundColor(.green)
                        
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
                            .foregroundColor(.green)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
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
    let progress: Double
    let currentTier: PrestigeLevel
    let nextTier: PrestigeLevel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                // Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: currentTier.color) ?? .blue,
                                Color(hex: nextTier.color) ?? .purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * (progress.isNaN || progress.isInfinite ? 0 : progress)), height: 12)
            }
        }
        .frame(height: 12)
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