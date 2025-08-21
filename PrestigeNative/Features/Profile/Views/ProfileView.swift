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
    @StateObject private var imagePreloader = ImagePreloader.shared
    @State private var showingError = false
    @State private var selectedTopType: ContentType = .albums
    @State private var showingSettings = false
    @State private var selectedPrestige: PrestigeSelection?
    @State private var hasInitiallyLoaded = false
    
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
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
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
            if viewModel.isLoading && !hasInitiallyLoaded {
                BeatVisualizerLoadingView(message: "Loading your profile...")
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            if let userId = authManager.user?.id {
                Task {
                    await viewModel.loadProfileDataSynchronously(userId: userId)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hasInitiallyLoaded = true
                    }
                }
            }
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
            if let error = error {
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
        VStack(spacing: 16) {
            // Profile Picture
            AsyncImage(url: URL(string: viewModel.userProfile?.profilePictureUrl ?? "")) { image in
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
            
            // User Info
            VStack(spacing: 4) {
                if let name = viewModel.userProfile?.name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let nickname = viewModel.userProfile?.nickname {
                    Text(nickname)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if viewModel.isLoading {
                    Text("Loading...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                } else {
                    Text("User")
                        .font(.title2)
                        .fontWeight(.bold)
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
                        viewModel.changeFavoriteType(to: .albums)
                    }
                    Button("Songs") {
                        viewModel.changeFavoriteType(to: .tracks)
                    }
                    Button("Artists") {
                        viewModel.changeFavoriteType(to: .artists)
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedFavoriteType.displayName)
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
                
                // Type selector for Ratings section
                Menu {
                    Button("Albums") {
                        viewModel.changeRatingType(to: .album)
                    }
                    Button("Tracks") {
                        viewModel.changeRatingType(to: .track)
                    }
                    Button("Artists") {
                        viewModel.changeRatingType(to: .artist)
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedRatingType.displayName)
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
                        ForEach(Array(viewModel.currentRatings.prefix(10).enumerated()), id: \.element.id) { index, ratedItem in
                            RatedItemCard(ratedItem: ratedItem)
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
                ForEach(Array(viewModel.topAlbums.prefix(5).enumerated()), id: \.element.album.id) { index, album in
                    TopItemCard(album: album)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromAlbum(album),
                                rank: index + 1
                            )
                        }
                }
            case .tracks:
                ForEach(Array(viewModel.topTracks.prefix(5).enumerated()), id: \.element.totalTime) { index, track in
                    TopItemCard(track: track)
                        .onTapGesture {
                            selectedPrestige = PrestigeSelection(
                                item: PrestigeDisplayItem.fromTrack(track),
                                rank: index + 1
                            )
                        }
                }
            case .artists:
                ForEach(Array(viewModel.topArtists.prefix(5).enumerated()), id: \.element.artist.id) { index, artist in
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
                ForEach(Array(viewModel.favoriteAlbums.prefix(5).enumerated()), id: \.element.id) { index, album in
                    FavoriteAlbumCard(album: album)
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
                ForEach(Array(viewModel.favoriteTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    FavoriteItemCard(track: track)
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
                ForEach(Array(viewModel.favoriteArtists.prefix(5).enumerated()), id: \.element.id) { index, artist in
                    FavoriteArtistCard(artist: artist)
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
            isPinned: false
        )
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
            isPinned: false
        )
    }
    
}

#Preview {
    ProfileView()
}