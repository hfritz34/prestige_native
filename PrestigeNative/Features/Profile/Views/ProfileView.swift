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
    @State private var showingError = false
    @State private var selectedTopType: ContentType = .tracks
    @State private var showingSettings = false
    
    var body: some View {
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
                viewModel.refreshData()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            if let userId = authManager.user?.id {
                viewModel.loadProfileData(userId: userId)
            } else {
                viewModel.loadProfileData() // Fallback
            }
        }
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
                    Button("Tracks") {
                        selectedTopType = .tracks
                    }
                    Button("Albums") {
                        selectedTopType = .albums
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
                    Button("Songs") {
                        viewModel.changeFavoriteType(to: .tracks)
                    }
                    Button("Albums") {
                        viewModel.changeFavoriteType(to: .albums)
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
                    Button("Tracks") {
                        viewModel.changeRatingType(to: .track)
                    }
                    Button("Albums") {
                        viewModel.changeRatingType(to: .album)
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
                        ForEach(Array(viewModel.currentRatings.prefix(10)), id: \.id) { ratedItem in
                            RatedItemCard(ratedItem: ratedItem)
                        }
                    }
                }
                .padding(.horizontal)
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
                .padding(.vertical, 50)
        } else {
            switch selectedTopType {
            case .tracks:
                ForEach(viewModel.topTracks.prefix(5), id: \.totalTime) { track in
                    TopItemCard(track: track)
                }
            case .albums:
                ForEach(viewModel.topAlbums.prefix(5), id: \.album.id) { album in
                    TopItemCard(album: album)
                }
            case .artists:
                ForEach(viewModel.topArtists.prefix(5), id: \.artist.id) { artist in
                    TopItemCard(artist: artist)
                }
            }
        }
    }
    
    @ViewBuilder
    private var favoritesCarouselContent: some View {
        switch viewModel.selectedFavoriteType {
        case .tracks:
            if viewModel.favoriteTracks.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(viewModel.favoriteTracks.prefix(5), id: \.id) { track in
                    FavoriteItemCard(track: track)
                }
            }
        case .albums:
            if viewModel.favoriteAlbums.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(viewModel.favoriteAlbums.prefix(5), id: \.id) { album in
                    // TODO: Create FavoriteAlbumCard
                    favoriteEmptyState
                }
            }
        case .artists:
            if viewModel.favoriteArtists.isEmpty {
                favoriteEmptyState
            } else {
                ForEach(viewModel.favoriteArtists.prefix(5), id: \.id) { artist in
                    // TODO: Create FavoriteArtistCard
                    favoriteEmptyState
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
                }
            }
        }
    }
    
}

#Preview {
    ProfileView()
}