//
//  FriendProfileView.swift
//  Display friend's profile similar to user's own profile
//

import SwiftUI

struct FriendProfileView: View {
    let friendId: String
    @StateObject private var viewModel = FriendProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContentType: ContentType = .albums
    @State private var selectedTopType: ContentType = .albums
    @State private var selectedFavoriteType: ContentType = .albums
    @State private var selectedRatingType: RatingItemType = .album
    @State private var selectedPrestige: PrestigeSelection?
    @State private var hasInitiallyLoaded = false
    @State private var minimumLoadingTime = false
    @State private var selectedFriendItem: FriendNavigationItem?
    
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
                        
                        // Favorites Section
                        favoritesSection
                        
                        // Ratings Section
                        ratingsSection
                        
                        // Recently Played Section
                        recentlyPlayedSection
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Friend Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .refreshable {
                    await viewModel.loadFriendProfile(friendId: friendId)
                }
                .sheet(item: $selectedPrestige) { selection in
                    PrestigeDetailView(
                        item: selection.item,
                        rank: selection.rank
                    )
                }
                .sheet(item: $selectedFriendItem) { friendItem in
                    FriendPrestigeDetailView(
                        friendPrestigeItem: friendItem.prestigeItem,
                        friendName: friendItem.friendName,
                        friendId: friendItem.friendId,
                        rank: friendItem.rank
                    )
                }
            }
            .opacity(hasInitiallyLoaded ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: hasInitiallyLoaded)
            
            // Full-screen loading overlay
            if (viewModel.isLoading || !minimumLoadingTime) && !hasInitiallyLoaded {
                BeatVisualizerLoadingView(message: "Loading friend's profile...")
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .task {
            // Start minimum loading timer (2.5 seconds)
            Task {
                try await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run {
                    minimumLoadingTime = true
                }
            }
            
            // Load friend profile data
            await viewModel.loadFriendProfile(friendId: friendId)
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            checkIfReadyToShow()
        }
        .onChange(of: minimumLoadingTime) { _, _ in
            checkIfReadyToShow()
        }
    }
    
    // MARK: - View Components
    
    private var contentTypeTabs: some View {
        HStack(spacing: 0) {
            ForEach([ContentType.albums, ContentType.tracks, ContentType.artists], id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedContentType = type
                        // Update all the individual section types
                        selectedTopType = type
                        selectedFavoriteType = type
                        // No need to update selectedRatingType as we handle all types
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedContentType == type ? .semibold : .medium)
                            .foregroundColor(selectedContentType == type ? .white : .secondary)
                            .lineLimit(1)
                        
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
    
    private var profileHeaderSection: some View {
        VStack(spacing: 12) {
            // Compact Profile Header
            HStack(alignment: .top, spacing: 14) {
                // LEFT: name, handle, bio
                VStack(alignment: .leading, spacing: 4) {
                    // Display name with verification badge
                    HStack(spacing: 6) {
                        if let nickname = viewModel.friend?.nickname {
                            Text(nickname)
                                .font(.system(size: 28, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .foregroundColor(.white)
                        } else if let name = viewModel.friend?.name {
                            Text(name)
                                .font(.system(size: 28, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .foregroundColor(.white)
                        } else {
                            Text("Loading...")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        // Verification badge
                        if viewModel.friend?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .accessibilityLabel("Verified user")
                        }
                    }

                    // Spotify handle
                    if let nickname = viewModel.friend?.nickname,
                       let name = viewModel.friend?.name,
                       nickname != name {
                        Text("@\(name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Bio
                    if let bio = viewModel.friend?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Friend on Prestige")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // RIGHT: avatar
                if let profilePicUrl = viewModel.friend?.profilePicUrl {
                    AsyncImage(url: URL(string: profilePicUrl)) { phase in
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
                } else {
                    Circle().fill(Color.secondary.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                        .overlay(
                            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
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
                            VStack(spacing: 4) {
                                // Item image with rating overlay - match ProfileView exactly
                                CachedAsyncImage(
                                    url: ratedItem.imageUrl,
                                    placeholder: Image(systemName: getIconForRatingType(ratedItem.itemData.itemType)),
                                    contentMode: .fill,
                                    maxWidth: 160,
                                    maxHeight: 160
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    // Rating score overlay
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text(ratedItem.rating.displayScore)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.7))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(6)
                                )
                                
                                // Item details - match ProfileView exactly
                                VStack(spacing: 1) {
                                    Text(ratedItem.displayTitle)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                    
                                    if !ratedItem.displaySubtitle.isEmpty {
                                        Text(ratedItem.displaySubtitle)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    // Prestige badge at bottom (match ProfileView pattern)
                                    let prestigeLevel = getPrestigeLevelForRatedItem(ratedItem)
                                    if prestigeLevel != .none {
                                        PrestigeBadge(tier: prestigeLevel)
                                            .scaleEffect(0.6)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(width: 160)
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
                            // Navigate to friend's album context instead of user's
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendAlbum(
                                    albumId: album.album.id,
                                    albumName: album.album.name,
                                    imageUrl: album.album.images.first?.url ?? "",
                                    artistName: album.album.artists.first?.name
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
                        }
                }
            case .tracks:
                ForEach(Array(viewModel.topTracks.prefix(25).enumerated()), id: \.element.totalTime) { index, track in
                    TopItemCard(track: track)
                        .onTapGesture {
                            // Navigate to friend's track context instead of user's
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendTrack(
                                    trackId: track.track.id,
                                    trackName: track.track.name,
                                    imageUrl: track.track.album.images.first?.url ?? "",
                                    artistName: track.track.artists.first?.name
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
                        }
                }
            case .artists:
                ForEach(Array(viewModel.topArtists.prefix(25).enumerated()), id: \.element.artist.id) { index, artist in
                    TopItemCard(artist: artist)
                        .onTapGesture {
                            // Navigate to friend's artist context instead of user's
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendArtist(
                                    artistId: artist.artist.id,
                                    artistName: artist.artist.name,
                                    imageUrl: artist.artist.images.first?.url ?? ""
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var favoritesCarouselContent: some View {
        switch selectedFavoriteType {
        case .albums:
            if viewModel.favoriteAlbums.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteAlbums.prefix(25).enumerated()), id: \.element.album.id) { index, album in
                    FavoriteAlbumCard(
                        album: album.album,
                        prestigeLevel: getPrestigeLevelForAlbum(album.album.id)
                    )
                        .onTapGesture {
                            // Navigate to friend's favorite album context
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendAlbum(
                                    albumId: album.album.id,
                                    albumName: album.album.name,
                                    imageUrl: album.album.images.first?.url ?? "",
                                    artistName: album.album.artists.first?.name
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
                        }
                }
            }
        case .tracks:
            if viewModel.favoriteTracks.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteTracks.prefix(25).enumerated()), id: \.element.track.id) { index, track in
                    FavoriteItemCard(
                        track: track.track,
                        prestigeLevel: getPrestigeLevelForTrack(track.track.id)
                    )
                        .onTapGesture {
                            // Navigate to friend's favorite track context
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendTrack(
                                    trackId: track.track.id,
                                    trackName: track.track.name,
                                    imageUrl: track.track.album.images.first?.url ?? "",
                                    artistName: track.track.artists.first?.name
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
                        }
                }
            }
        case .artists:
            if viewModel.favoriteArtists.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(Array(viewModel.favoriteArtists.prefix(25).enumerated()), id: \.element.artist.id) { index, artist in
                    FavoriteArtistCard(
                        artist: artist.artist,
                        prestigeLevel: getPrestigeLevelForArtist(artist.artist.id)
                    )
                        .onTapGesture {
                            // Navigate to friend's favorite artist context
                            Task {
                                if let friendPrestigeItem = await viewModel.navigateToFriendArtist(
                                    artistId: artist.artist.id,
                                    artistName: artist.artist.name,
                                    imageUrl: artist.artist.images.first?.url ?? ""
                                ) {
                                    selectedFriendItem = FriendNavigationItem(
                                        prestigeItem: friendPrestigeItem,
                                        friendName: viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Friend",
                                        friendId: viewModel.friend?.friendId ?? "",
                                        rank: index + 1
                                    )
                                }
                            }
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
                    subtitle: "Recently played tracks will appear here"
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
    
    private func checkIfReadyToShow() {
        if !viewModel.isLoading && minimumLoadingTime && !hasInitiallyLoaded {
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
            totalTimeMilliseconds: 0,
            prestigeLevel: .none,
            spotifyId: ratedItem.itemData.id,
            contentType: contentType,
            albumPosition: nil,
            rating: ratedItem.rating.personalScore,
            isPinned: false,
            albumId: ratedItem.itemData.albumId,
            albumName: ratedItem.itemData.albumName
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
    
    private func getIconForRatingType(_ itemType: RatingItemType) -> String {
        switch itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "music.mic"
        }
    }
    
    private func getCurrentRatingItems() -> [RatedItem] {
        return viewModel.getCurrentRatingItems(for: selectedContentType)
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
}