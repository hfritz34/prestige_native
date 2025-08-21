//
//  ArtistPrestigeDetailView.swift
//  Individual Artist Detail View with Album List
//
//  Shows artist information with expandable album list, pin functionality,
//  and prestige level similar to Prestige.web artist pages.
//

import SwiftUI

struct ArtistPrestigeDetailView: View {
    let artist: UserArtistResponse
    let rank: Int
    
    @State private var showAllAlbums = false
    @State private var artistAlbums: ArtistAlbumsWithRankingsResponse?
    @State private var isLoadingAlbums = false
    @StateObject private var pinService = PinService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with artist image and info
                    artistHeaderSection
                    
                    // Progress indicator for albums
                    albumProgressSection
                    
                    // Show All Albums toggle
                    albumListSection
                    
                    // Action buttons
                    actionButtonsSection
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
        }
        .onAppear {
            loadArtistAlbums()
        }
    }
    
    // MARK: - View Sections
    
    private var artistHeaderSection: some View {
        VStack(spacing: 16) {
            // Artist artwork with prestige background
            ZStack {
                // Prestige tier background
                if artist.prestigeLevel != .none && !artist.prestigeLevel.imageName.isEmpty {
                    Image(artist.prestigeLevel.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .opacity(0.8)
                }
                
                // Artist image
                CachedAsyncImage(
                    url: artist.artist.images.first?.url ?? "",
                    placeholder: Image(systemName: "person.circle"),
                    contentMode: .fit,
                    maxWidth: 160,
                    maxHeight: 160
                )
                .clipShape(Circle())
                .shadow(radius: 12)
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Artist info
            VStack(spacing: 8) {
                HStack {
                    Text(artist.artist.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if pinService.isItemPinned(itemId: artist.artist.id, itemType: .artists) {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text("Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Artist rank
                Text("Artist Rank #\(rank)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                
                // Stats row
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(artist.totalTimeMinutes))")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Prestige Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(artist.prestigeLevel.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var albumProgressSection: some View {
        VStack(spacing: 16) {
            if let albumData = artistAlbums, !albumData.albums.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Albums")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(albumData.totalAlbums) albums")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var albumListSection: some View {
        VStack(spacing: 16) {
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAllAlbums.toggle()
                }
            }) {
                HStack {
                    Text(showAllAlbums ? "Hide Albums" : "Show All Albums")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: showAllAlbums ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(showAllAlbums ? 180 : 0))
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Expanded album list
            if showAllAlbums {
                albumListContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var albumListContent: some View {
        VStack(spacing: 8) {
            if isLoadingAlbums {
                CompactBeatVisualizer(isPlaying: true)
                    .padding(.vertical, 20)
            } else if let albumData = artistAlbums, !albumData.albums.isEmpty {
                LazyVStack(spacing: 4) {
                    ForEach(albumData.albums, id: \.albumId) { album in
                        ArtistAlbumRow(album: album)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else {
                Text("No album data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Pin button
            Button(action: {
                Task {
                    let _ = await pinService.togglePin(itemId: artist.artist.id, itemType: .artists)
                }
            }) {
                HStack {
                    Text("📌")
                    Text(pinService.isItemPinned(itemId: artist.artist.id, itemType: .artists) ? "Pinned" : "Pin")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(pinService.isItemPinned(itemId: artist.artist.id, itemType: .artists) ? Color.yellow.opacity(0.3) : Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            // Play/Open on Spotify
            Button(action: {
                // TODO: Open artist on Spotify
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadArtistAlbums() {
        isLoadingAlbums = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else {
                    print("No user ID available for loading artist albums")
                    await MainActor.run {
                        isLoadingAlbums = false
                    }
                    return
                }
                
                // Get artist albums with rankings from prestige API
                let albumsResponse = try await APIClient.shared.get(
                    "prestige/\(userId)/artists/\(artist.artist.id)/albums", 
                    responseType: ArtistAlbumsWithRankingsResponse.self
                )
                
                await MainActor.run {
                    artistAlbums = albumsResponse
                    isLoadingAlbums = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading artist albums: \(error)")
                    isLoadingAlbums = false
                }
            }
        }
    }
}

// MARK: - Artist Album Response Models

struct ArtistAlbumsWithRankingsResponse: Codable {
    let artistId: String
    let totalAlbums: Int
    let albums: [ArtistAlbumResponse]
}

struct ArtistAlbumResponse: Codable {
    let albumId: String
    let albumName: String
    let artistName: String
    let albumImage: String
    let albumRatingScore: Double?
    let totalTime: Int
    let isPinned: Bool
    let isFavorite: Bool
}

// MARK: - Artist Album Row

struct ArtistAlbumRow: View {
    let album: ArtistAlbumResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Album image
            CachedAsyncImage(
                url: album.albumImage,
                placeholder: Image(systemName: "square.stack"),
                contentMode: .fill,
                maxWidth: 50,
                maxHeight: 50
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Album info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.albumName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(album.totalTime / 60)) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 8) {
                if album.isPinned {
                    Text("📌")
                        .font(.caption)
                }
                if album.isFavorite {
                    Text("❤️")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .onTapGesture {
            // TODO: Navigate to album detail page
        }
    }
}

// MARK: - Preview

#Preview {
    ArtistPrestigeDetailView(
        artist: UserArtistResponse(
            totalTime: 50400, // 840 minutes
            artist: ArtistResponse(
                id: "artist1",
                name: "Sample Artist",
                images: []
            ),
            userId: "user1"
        ),
        rank: 3
    )
}