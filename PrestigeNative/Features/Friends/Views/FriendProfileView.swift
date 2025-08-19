//
//  FriendProfileView.swift
//  Display friend's profile similar to user's own profile
//

import SwiftUI

struct FriendProfileView: View {
    let friendId: String
    @StateObject private var viewModel = FriendProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeaderView
                        .padding()
                    
                    // Tab Selection
                    Picker("", selection: $selectedTab) {
                        Text("Top").tag(0)
                        Text("Favorites").tag(1)
                        Text("Recent").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Tab Content
                    tabContentView
                        .padding(.top)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadFriendProfile(friendId: friendId)
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let profilePicUrl = viewModel.friend?.profilePicUrl {
                CachedAsyncImage(
                    url: profilePicUrl,
                    placeholder: Image(systemName: "person.crop.circle.fill")
                )
                .artistImage(size: 100)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // Name
            VStack(spacing: 4) {
                Text(viewModel.friend?.nickname ?? viewModel.friend?.name ?? "Loading...")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let nickname = viewModel.friend?.nickname,
                   nickname != viewModel.friend?.name {
                    Text("@\(viewModel.friend?.name ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats Row
            HStack(spacing: 30) {
                StatView(value: viewModel.totalTracks, label: "Tracks")
                StatView(value: viewModel.totalAlbums, label: "Albums")
                StatView(value: viewModel.totalArtists, label: "Artists")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case 0:
            topItemsView
        case 1:
            favoritesView
        case 2:
            recentTracksView
        default:
            EmptyView()
        }
    }
    
    // MARK: - Top Items View
    
    private var topItemsView: some View {
        VStack(spacing: 20) {
            // Top Tracks
            if !viewModel.topTracks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Tracks")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.topTracks) { userTrack in
                        FriendTrackRow(userTrack: userTrack)
                    }
                }
            }
            
            // Top Albums
            if !viewModel.topAlbums.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Albums")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.topAlbums) { userAlbum in
                                FriendAlbumCard(userAlbum: userAlbum)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Top Artists
            if !viewModel.topArtists.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Artists")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.topArtists) { userArtist in
                        FriendArtistRow(userArtist: userArtist)
                    }
                }
            }
        }
    }
    
    // MARK: - Favorites View
    
    private var favoritesView: some View {
        VStack(spacing: 20) {
            if viewModel.favoriteTracks.isEmpty &&
               viewModel.favoriteAlbums.isEmpty &&
               viewModel.favoriteArtists.isEmpty {
                Text("No favorites set")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            } else {
                // Favorite Tracks
                if !viewModel.favoriteTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Tracks")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.favoriteTracks) { userTrack in
                            FriendTrackRow(userTrack: userTrack)
                        }
                    }
                }
                
                // Favorite Albums
                if !viewModel.favoriteAlbums.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Albums")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.favoriteAlbums) { userAlbum in
                                    FriendAlbumCard(userAlbum: userAlbum)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Favorite Artists
                if !viewModel.favoriteArtists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Artists")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.favoriteArtists) { userArtist in
                            FriendArtistRow(userArtist: userArtist)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Tracks View
    
    private var recentTracksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.recentTracks.isEmpty {
                Text("No recent tracks")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
            } else {
                ForEach(viewModel.recentTracks) { track in
                    // Recent track row implementation
                    EmptyView() // TODO: Implement recent track row
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FriendTrackRow: View {
    let userTrack: UserTrackResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            if let imageUrl = userTrack.track.album.images.first?.url {
                CachedAsyncImage(
                    url: imageUrl,
                    placeholder: Image(systemName: "music.note")
                )
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userTrack.track.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text(userTrack.track.artists.first?.name ?? "Unknown Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Prestige Badge
            PrestigeBadge(tier: userTrack.prestigeLevel)
        }
        .padding(.horizontal)
    }
}

struct FriendAlbumCard: View {
    let userAlbum: UserAlbumResponse
    
    var body: some View {
        VStack(spacing: 8) {
            // Album Art with Prestige Outline
            ZStack {
                if let imageUrl = userAlbum.album.images.first?.url {
                    CachedAsyncImage(
                        url: imageUrl,
                        placeholder: Image(systemName: "music.note.list")
                    )
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                }
                
                // Prestige Outline
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color(hex: userAlbum.prestigeLevel.color) ?? .gray,
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
            }
            
            // Album Name
            Text(userAlbum.album.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100)
        }
    }
}

struct FriendArtistRow: View {
    let userArtist: UserArtistResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Artist Image
            if let imageUrl = userArtist.artist.images.first?.url {
                CachedAsyncImage(
                    url: imageUrl,
                    placeholder: Image(systemName: "person.circle.fill")
                )
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // Artist Name
            Text(userArtist.artist.name)
                .font(.body)
            
            Spacer()
            
            // Prestige Badge
            PrestigeBadge(tier: userArtist.prestigeLevel)
        }
        .padding(.horizontal)
    }
}