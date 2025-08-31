//
//  FriendProfileView.swift
//  Display friend's profile similar to user's own profile
//

import SwiftUI

struct FriendProfileView: View {
    let friendId: String
    @StateObject private var viewModel = FriendProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopType: ContentType = .albums
    @State private var selectedFavoriteType: ContentType = .albums
    @State private var selectedRatingType: RatingItemType = .album
    @State private var selectedPrestige: PrestigeSelection?
    @State private var hasInitiallyLoaded = false
    @State private var minimumLoadingTime = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeaderSection
                        
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
                .navigationBarTitleDisplayMode(.large)
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
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let profilePicUrl = viewModel.friend?.profilePicUrl {
                AsyncImage(url: URL(string: profilePicUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // User Info
            VStack(spacing: 4) {
                if let nickname = viewModel.friend?.nickname {
                    Text(nickname)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let name = viewModel.friend?.name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("Loading...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                if let nickname = viewModel.friend?.nickname,
                   let name = viewModel.friend?.name,
                   nickname != name {
                    Text("@\(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var topSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Type selector for Top section
                Menu {
                    Button("Albums") {
                        selectedTopType = .albums
                    }
                    Button("Tracks") {
                        selectedTopType = .tracks
                    }
                    Button("Artists") {
                        selectedTopType = .artists
                    }
                } label: {
                    HStack {
                        Text(selectedTopType.displayName)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            // Top items carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    topCarouselContent
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Favorites")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Type selector for Favorites section
                Menu {
                    Button("Albums") {
                        selectedFavoriteType = .albums
                    }
                    Button("Songs") {
                        selectedFavoriteType = .tracks
                    }
                    Button("Artists") {
                        selectedFavoriteType = .artists
                    }
                } label: {
                    HStack {
                        Text(selectedFavoriteType.displayName)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    favoritesCarouselContent
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ratings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Type selector for Ratings section (Albums and Artists only)
                Menu {
                    Button("Albums") {
                        selectedRatingType = .album
                    }
                    Button("Artists") {
                        selectedRatingType = .artist
                    }
                } label: {
                    HStack {
                        Text(selectedRatingType.displayName)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.8))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            // Ratings carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    if viewModel.currentRatings.isEmpty {
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
                        ForEach(Array(viewModel.currentRatings.prefix(25).enumerated()), id: \.element.id) { index, ratedItem in
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
        VStack(alignment: .leading, spacing: 16) {
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
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromAlbum(album),
                                rank: index + 1
                            )
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
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromTrack(track),
                                rank: index + 1
                            )
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
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromArtist(artist),
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
            if viewModel.recentTracks.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No Recent Activity",
                    subtitle: "Recently played tracks will appear here"
                )
                .padding(.horizontal)
            } else {
                ForEach(Array(viewModel.recentTracks.prefix(30).enumerated()), id: \.offset) { index, track in
                    // Placeholder for recent track rows
                    // This needs to be implemented based on your data model
                    EmptyView()
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
}