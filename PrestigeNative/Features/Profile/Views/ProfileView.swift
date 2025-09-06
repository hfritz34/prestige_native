//
//  ProfileView.swift
//  User Profile Screen
//
//  Shows Top section (carousel), Favorites section, and Recently Played.
//  Matches ProfilePage.tsx from the web application.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @StateObject private var imagePreloader = ImagePreloader.shared
    @State private var showingError = false
    @State private var selectedTopType: ContentType = .albums
    @State private var selectedContentType: ContentType = .albums
    @State private var showingSettings = false
    @State private var selectedPrestige: PrestigeSelection?
    @State private var hasInitiallyLoaded = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 12) {
                        // Profile Header
                        profileHeaderSection
                        
                        // Unified Content Type Tabs
                        contentTypeTabs
                        
                        // Top Section
                        topSection
                        
                        // Pinned Items Section - TODO: Re-enable when ready
                        // PinnedItemsView()
                        
                        // Favorites Section
                        favoritesSection
                        
                        // Ratings Section
                        ratingsSection
                        
                        // Recently Played Section
                        recentlyPlayedSection
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshDataSynchronously()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(authManager)
                        .environmentObject(appearanceManager)
                }
                .sheet(item: $selectedPrestige) { selection in
                    PrestigeDetailView(
                        item: selection.item,
                        rank: selection.rank
                    )
                }
            }
            .opacity(hasInitiallyLoaded ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: hasInitiallyLoaded)
            
            // Full-screen loading overlay - show until all data is loaded
            if (viewModel.isLoading || !viewModel.ratingsLoaded) && !hasInitiallyLoaded {
                BeatVisualizerLoadingView(message: "Loading your profile...")
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            if let userId = authManager.user?.id {
                Task {
                    // Load profile data immediately
                    await viewModel.loadProfileDataSynchronously(userId: userId)
                }
            }
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            checkIfReadyToShow()
        }
        .onChange(of: viewModel.ratingsLoaded) { _, _ in
            checkIfReadyToShow()
        }
        .preloadAlbumImages(viewModel.topAlbums)
        .preloadTrackImages(viewModel.topTracks)
        .preloadArtistImages(viewModel.topArtists)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: viewModel.error) { _, error in
            if error != nil {
                // Add a small delay to avoid showing flash errors during loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Only show error if it's still present after delay
                    if viewModel.error != nil {
                        showingError = true
                    }
                }
            } else {
                showingError = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var profileHeaderSection: some View {
        VStack(spacing: 12) {
            // Compact Profile Header
            HStack(alignment: .top, spacing: 14) {
                // LEFT: name, handle, bio
                VStack(alignment: .leading, spacing: 4) {
                    // Display name
                    if let name = viewModel.userProfile?.name {
                        Text(name)
                            .font(.system(size: 28, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundColor(.white)
                    } else if let nickname = viewModel.userProfile?.nickname {
                        Text(nickname)
                            .font(.system(size: 28, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundColor(.white)
                    } else if viewModel.isLoading {
                        Text("Loading...")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.secondary)
                    } else {
                        Text("User")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }


                    // Bio
                    if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Add a bio to tell others about your music taste")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.7))
                            .italic()
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // RIGHT: avatar
                AsyncImage(url: URL(string: viewModel.userProfile?.profilePictureUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Circle().fill(Color.secondary.opacity(0.2))
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                .contentShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Profile Actions
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Edit profile action
                }) {
                    Text("Edit profile")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button(action: {
                    // TODO: Share profile action
                }) {
                    Text("Share profile")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var contentTypeTabs: some View {
        HStack(spacing: 0) {
            ForEach([ContentType.albums, ContentType.tracks, ContentType.artists], id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedContentType = type
                        // Update all the individual section types
                        selectedTopType = type
                        viewModel.changeFavoriteType(to: type)
                        if type != .tracks {
                            viewModel.changeRatingType(to: type == .albums ? .album : .artist)
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedContentType == type ? .semibold : .medium)
                            .foregroundColor(selectedContentType == type ? .white : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedContentType == type ? .white : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var topSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Top items carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    topCarouselContent
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    favoritesCarouselContent
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ratings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Ratings carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    if getCurrentRatingItems().isEmpty {
                        // Empty state
                        VStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: "star.fill")
                                            .font(.title)
                                            .foregroundColor(.orange)
                                        Text("No ratings yet")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                )
                        }
                    } else {
                        // Display rated items
                        ForEach(Array(getCurrentRatingItems().prefix(25).enumerated()), id: \.element.id) { index, ratedItem in
                            RatedItemCard(
                                ratedItem: ratedItem,
                                prestigeLevel: getPrestigeLevelForRatedItem(ratedItem)
                            )
                                .onTapGesture {
                                    selectedPrestige = PrestigeSelection(
                                        item: convertRatedItemToPrestigeDisplayItem(ratedItem),
                                        rank: index + 1
                                    )
                                }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Played")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            recentlyPlayedContent
        }
    }
    
    @ViewBuilder
    private var topCarouselContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .scaleEffect(1.2)
                .padding(.vertical, 30)
        } else {
            switch selectedTopType {
            case .albums:
                ForEach(Array(viewModel.topAlbums.prefix(25).enumerated()), id: \.element.album.id) { index, album in
                    TopItemCard(album: album)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromAlbum(album),
                                rank: index + 1
                            )
                        }
                }
            case .tracks:
                ForEach(Array(viewModel.topTracks.prefix(25).enumerated()), id: \.element.totalTime) { index, track in
                    TopItemCard(track: track)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromTrack(track),
                                rank: index + 1
                            )
                        }
                }
            case .artists:
                ForEach(Array(viewModel.topArtists.prefix(25).enumerated()), id: \.element.artist.id) { index, artist in
                    TopItemCard(artist: artist)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromArtist(artist),
                                rank: index + 1
                            )
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var favoritesCarouselContent: some View {
        switch viewModel.selectedFavoriteType {
        case .albums:
            if viewModel.favoriteAlbums.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteAlbums.prefix(25).enumerated()), id: \.element.id) { index, album in
                    FavoriteAlbumCard(
                        album: album,
                        prestigeLevel: getPrestigeLevelForAlbum(album.id)
                    )
                        .onTapGesture {
                            // Convert AlbumResponse to UserAlbumResponse for PrestigeDisplayItem
                            let userAlbum = UserAlbumResponse(
                                totalTime: 0, // Favorites don't have listening time
                                album: album,
                                userId: authManager.user?.id ?? ""
                            )
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromAlbum(userAlbum),
                                rank: index + 1
                            )
                        }
                }
            }
        case .tracks:
            if viewModel.favoriteTracks.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteTracks.prefix(25).enumerated()), id: \.element.id) { index, track in
                    FavoriteItemCard(
                        track: track,
                        prestigeLevel: getPrestigeLevelForTrack(track.id)
                    )
                        .onTapGesture {
                            // Convert TrackResponse to UserTrackResponse for PrestigeDisplayItem
                            let userTrack = UserTrackResponse(
                                totalTime: 0, // Favorites don't have listening time
                                track: track,
                                userId: authManager.user?.id ?? ""
                            )
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromTrack(userTrack),
                                rank: index + 1
                            )
                        }
                }
            }
        case .artists:
            if viewModel.favoriteArtists.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteArtists.prefix(25).enumerated()), id: \.element.id) { index, artist in
                    FavoriteArtistCard(
                        artist: artist,
                        prestigeLevel: getPrestigeLevelForArtist(artist.id)
                    )
                        .onTapGesture {
                            // Convert ArtistResponse to UserArtistResponse for PrestigeDisplayItem
                            let userArtist = UserArtistResponse(
                                totalTime: 0, // Favorites don't have listening time
                                artist: artist,
                                userId: authManager.user?.id ?? ""
                            )
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromArtist(userArtist),
                                rank: index + 1
                            )
                        }
                }
            }
        }
    }
    
    private var favoriteEmptyState: some View {
        VStack {
            Image(systemName: "heart")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No favorites yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var recentlyPlayedContent: some View {
        VStack(spacing: 8) {
            if viewModel.recentlyPlayed.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No Recent Activity",
                    subtitle: "Your recently played tracks will appear here"
                )
                .padding(.horizontal)
            } else {
                ForEach(Array(viewModel.recentlyPlayed.prefix(30).enumerated()), id: \.offset) { index, track in
                    RecentTrackRow(track: track)
                        .padding(.horizontal)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: convertRecentTrackToPrestigeDisplayItem(track),
                                rank: index + 1
                            )
                        }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Check if ready to show content (data loaded and ratings ready)
    private func checkIfReadyToShow() {
        // Check if all data including ratings have been loaded
        let allDataReady = !viewModel.isLoading && viewModel.ratingsLoaded
        
        if allDataReady && !hasInitiallyLoaded {
            withAnimation(.easeInOut(duration: 0.5)) {
                hasInitiallyLoaded = true
            }
        }
    }
    
    private func convertRatedItemToPrestigeDisplayItem(_ ratedItem: RatedItem) -> PrestigeDisplayItem {
        let contentType: ContentType
        switch ratedItem.itemData.itemType {
        case .track: contentType = .tracks
        case .album: contentType = .albums
        case .artist: contentType = .artists
        }
        
        return PrestigeDisplayItem(
            name: ratedItem.itemData.name,
            subtitle: ratedItem.itemData.artists?.joined(separator: ", ") ?? ratedItem.itemData.albumName ?? "Unknown",
            imageUrl: ratedItem.itemData.imageUrl ?? "",
            totalTimeMilliseconds: 0, // Rated items don't have listening time
            prestigeLevel: .none, // Rated items don't have prestige levels
            spotifyId: ratedItem.itemData.id,
            contentType: contentType,
            albumPosition: nil,
            rating: ratedItem.rating.personalScore,
            isPinned: false,
            albumId: ratedItem.itemData.albumId,
            albumName: ratedItem.itemData.albumName
        )
    }
    
    private func preloadProfileImages() {
        // Preload images from all profile sections
        let topImageUrls: [String] = {
            switch selectedTopType {
            case .albums: return viewModel.topAlbums.compactMap { $0.album.images.first?.url }
            case .tracks: return viewModel.topTracks.compactMap { $0.track.album.images.first?.url }
            case .artists: return viewModel.topArtists.compactMap { $0.artist.images.first?.url }
            }
        }()
        
        let favoriteImageUrls: [String] = {
            switch viewModel.selectedFavoriteType {
            case .albums: return viewModel.favoriteAlbums.compactMap { $0.images.first?.url }
            case .tracks: return viewModel.favoriteTracks.compactMap { $0.album.images.first?.url }
            case .artists: return viewModel.favoriteArtists.compactMap { $0.images.first?.url }
            }
        }()
        
        let ratingImageUrls = viewModel.currentRatings.compactMap { $0.imageUrl }
        let recentImageUrls = viewModel.recentlyPlayed.compactMap { $0.imageUrl }
        
        let allImageUrls = topImageUrls + favoriteImageUrls + ratingImageUrls + recentImageUrls
        
        // Preload images
        for imageUrl in allImageUrls.prefix(40) { // Limit to first 40 to avoid overwhelming
            imagePreloader.preloadImage(imageUrl)
        }
    }
    
    private func getCurrentRatingItems() -> [RatedItem] {
        switch selectedContentType {
        case .tracks:
            // For tracks, we need to implement proper track ratings organized by album and position
            // For now, return empty since ProfileViewModel doesn't support track ratings yet
            // TODO: Implement track ratings in ProfileViewModel with album grouping and positional sorting
            return []
        case .albums:
            return viewModel.ratedAlbums
        case .artists:
            return viewModel.ratedArtists
        }
    }
    
    private func convertRecentTrackToPrestigeDisplayItem(_ track: RecentlyPlayedResponse) -> PrestigeDisplayItem {
        return PrestigeDisplayItem(
            name: track.trackName,
            subtitle: track.artistName,
            imageUrl: track.imageUrl,
            totalTimeMilliseconds: 0, // Recent tracks don't have total listening time
            prestigeLevel: .none, // Recent tracks don't have prestige levels
            spotifyId: track.id,
            contentType: .tracks,
            albumPosition: nil,
            rating: nil,
            isPinned: false,
            albumId: nil, // Recent tracks don't have album ID in this context
            albumName: nil // Recent tracks don't have album name in this context
        )
    }
    
    // MARK: - Prestige Level Helpers
    
    private func getPrestigeLevelForTrack(_ trackId: String) -> PrestigeLevel {
        return viewModel.topTracks.first { $0.track.id == trackId }?.prestigeLevel ?? .none
    }
    
    private func getPrestigeLevelForAlbum(_ albumId: String) -> PrestigeLevel {
        return viewModel.topAlbums.first { $0.album.id == albumId }?.prestigeLevel ?? .none
    }
    
    private func getPrestigeLevelForArtist(_ artistId: String) -> PrestigeLevel {
        return viewModel.topArtists.first { $0.artist.id == artistId }?.prestigeLevel ?? .none
    }
    
    private func getPrestigeLevelForRatedItem(_ ratedItem: RatedItem) -> PrestigeLevel {
        switch ratedItem.itemData.itemType {
        case .track:
            return getPrestigeLevelForTrack(ratedItem.itemData.id)
        case .album:
            return getPrestigeLevelForAlbum(ratedItem.itemData.id)
        case .artist:
            return getPrestigeLevelForArtist(ratedItem.itemData.id)
        }
    }
    
}

#Preview {
    ProfileView()
}