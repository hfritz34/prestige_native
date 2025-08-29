//
//  AlbumDetailView.swift
//  Album Detail View with Track List
//
//  Shows album information with expandable track list showing
//  album rankings, rated vs unrated tracks, and progress indicator
//

import SwiftUI

struct AlbumDetailView: View {
    let album: UserAlbumResponse
    let rank: Int
    
    @State private var showAllTracks = false
    @State private var albumTracksResponse: AlbumTracksWithRankingsResponse?
    @State private var isLoadingTracks = false
    @State private var isPinned = false
    @StateObject private var pinService = PinService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Theme color for this view
    private let themeColor: Color = Color(hex: "#5167FC") ?? .purple
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with album art and info
                    albumHeaderSection
                    
                    // Progress indicator
                    albumProgressSection
                    
                    // Show All Tracks toggle
                    trackListSection
                    
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
            loadAlbumTracks()
            Task {
                await pinService.loadPinnedItems()
            }
            isPinned = pinService.isItemPinned(itemId: album.album.id, itemType: .albums)
        }
    }
    
    // MARK: - View Sections
    
    private var albumHeaderSection: some View {
        VStack(spacing: 16) {
            // Album artwork
            CachedAsyncImage(
                url: album.album.images.first?.url ?? "",
                placeholder: Image(systemName: "square.stack"),
                contentMode: .fit,
                maxWidth: 200,
                maxHeight: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 12)
            
            // Album info
            VStack(spacing: 8) {
                HStack {
                    Text(album.album.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if isPinned {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text(album.album.artists.first?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Album rank
                Text("Album Rank #\(rank)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var albumProgressSection: some View {
        VStack(spacing: 16) {
            // Progress Stats
            if let tracksResponse = albumTracksResponse {
                VStack(spacing: 12) {
                    HStack {
                        Text("Album Tracks")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(tracksResponse.ratedTracks) of \(tracksResponse.totalTracks) tracks rated")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if tracksResponse.allTracksRated {
                                Text("⭐ Complete!")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Progress bar
                    ProgressView(value: Double(tracksResponse.ratedTracks), total: Double(tracksResponse.totalTracks))
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 2)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var trackListSection: some View {
        VStack(spacing: 16) {
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAllTracks.toggle()
                }
                
                // Load tracks if showing and not already loaded
                if showAllTracks && albumTracksResponse == nil && !isLoadingTracks {
                    loadAlbumTracks()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: showAllTracks ? "music.note.list" : "music.note")
                        .font(.title3)
                        .foregroundColor(themeColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(showAllTracks ? "Hide Tracks" : "Show All Tracks")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if !showAllTracks && albumTracksResponse == nil {
                            Text("View album track rankings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: showAllTracks ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeColor)
                        .rotationEffect(.degrees(showAllTracks ? 0 : 0))
                }
                .foregroundColor(.primary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Expanded track list
            if showAllTracks {
                trackListContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var trackListContent: some View {
        VStack(spacing: 8) {
            if isLoadingTracks {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    
                    Text("Loading album tracks...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let tracksResponse = albumTracksResponse, !tracksResponse.tracks.isEmpty {
                LazyVStack(spacing: 4) {
                    ForEach(tracksResponse.tracks.indices, id: \.self) { index in
                        AlbumTrackRow(
                            track: tracksResponse.tracks[index],
                            trackNumber: tracksResponse.tracks[index].trackNumber
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else {
                Text("No track data available")
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
                .background(isPinned ? Color.yellow : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isPinned ? .black : .primary)
                .cornerRadius(10)
            }
            
            // Play/Open on Spotify
            Button(action: {
                // TODO: Open album on Spotify
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
    
    // MARK: - Computed Properties
    
    private var isCompleteAlbum: Bool {
        return albumTracksResponse?.allTracksRated ?? false
    }
    
    // MARK: - Data Loading
    
    private func loadAlbumTracks() {
        isLoadingTracks = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else {
                    print("No user ID available for loading album tracks")
                    await MainActor.run {
                        isLoadingTracks = false
                    }
                    return
                }
                
                // Get album tracks with rankings from prestige API
                let tracksResponse = try await APIClient.shared.getAlbumTracksWithRankings(
                    userId: userId,
                    albumId: album.album.id
                )
                
                await MainActor.run {
                    albumTracksResponse = tracksResponse
                    isLoadingTracks = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading album tracks: \(error)")
                    albumTracksResponse = nil
                    isLoadingTracks = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePin() {
        Task {
            let newPinState = await pinService.togglePin(
                itemId: album.album.id,
                itemType: .albums
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPinned = newPinState
            }
        }
    }
}


// MARK: - Album Track Row

struct AlbumTrackRow: View {
    let track: AlbumTrackWithRanking
    let trackNumber: Int
    @StateObject private var pinService = PinService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Album ranking (bold purple number)
            Group {
                if let ranking = track.albumRanking {
                    Text("\(ranking)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .frame(width: 32, alignment: .center)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .center)
                }
            }
            
            // Track number (small gray)
            Text("\(trackNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .center)
            
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
            
            // Status indicators on the right
            HStack(spacing: 8) {
                if track.isFavorite {
                    Text("❤️")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            track.hasUserRating 
                ? Color(UIColor.secondarySystemBackground)
                : Color(UIColor.tertiarySystemBackground).opacity(0.7)
        )
        .cornerRadius(8)
        .onTapGesture {
            // TODO: Navigate to track detail page
        }
    }
}

// MARK: - Preview

#Preview {
    AlbumDetailView(
        album: UserAlbumResponse(
            totalTime: 3600,
            album: AlbumResponse(
                id: "album1",
                name: "Sample Album",
                images: [],
                artists: [TrackResponse.ArtistInfo(id: "artist1", name: "Sample Artist")]
            ),
            userId: "user1",
            isPinned: false,
            rating: 8.5
        ),
        rank: 5
    )
}