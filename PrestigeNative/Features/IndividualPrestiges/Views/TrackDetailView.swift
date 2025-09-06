//
//  TrackDetailView.swift
//  Individual Track Detail View with Album Rankings
//
//  Shows track information with album position ranking, pin functionality,
//  and prestige level similar to Prestige.web track pages.
//

import SwiftUI

struct TrackDetailView: View {
    let track: UserTrackResponse
    let rank: Int?
    
    @State private var albumTracksResponse: AlbumTracksWithRankingsResponse?
    @State private var isLoadingAlbumData = false
    @StateObject private var pinService = PinService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with album art and prestige background
                    trackHeaderSection
                    
                    // Track stats (Minutes, Prestige Level, Album Rank)
                    trackStatsSection
                    
                    // Action buttons (Pin, Play on Spotify, View Album)
                    actionButtonsSection
                    
                    Spacer()
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
            .background(Color.black)
        }
        .onAppear {
            loadAlbumData()
        }
    }
    
    // MARK: - View Sections
    
    private var trackHeaderSection: some View {
        VStack(spacing: 16) {
            // Prestige background with album artwork
            ZStack {
                // Prestige tier background - full opacity with minimal transparency
                if track.prestigeLevel != .none && !track.prestigeLevel.imageName.isEmpty {
                    Image(track.prestigeLevel.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .opacity(0.8)
                }
                
                // Album artwork
                CachedAsyncImage(
                    url: track.track.album.images.first?.url ?? "",
                    placeholder: Image(systemName: "music.note.list"),
                    contentMode: .fit,
                    maxWidth: 160,
                    maxHeight: 160
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 12)
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Track info
            VStack(spacing: 8) {
                HStack {
                    Text(track.track.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if pinService.isItemPinned(itemId: track.track.id, itemType: .tracks) {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text(track.track.artists.first?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(track.track.album.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Overall rank if provided
                if let rank = rank {
                    Text("Track Rank #\(rank)")
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
    }
    
    private var trackStatsSection: some View {
        HStack(spacing: 24) {
            // Minutes listened
            VStack(spacing: 4) {
                Text("Minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(track.totalTimeMinutes))")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Prestige Level
            VStack(spacing: 4) {
                Text("Prestige Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(track.prestigeLevel.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Album Rank
            VStack(spacing: 4) {
                Text("Album Rank")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isLoadingAlbumData {
                    Text("...")
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let albumRanking = currentTrackAlbumRanking,
                          let totalTracks = albumTracksResponse?.totalTracks {
                    Text("🏆 #\(albumRanking) of \(totalTracks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                } else {
                    Text("—")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Pin button
                Button(action: {
                    Task {
                        let _ = await pinService.togglePin(itemId: track.track.id, itemType: .tracks)
                    }
                }) {
                    HStack {
                        Text("📌")
                        Text(pinService.isItemPinned(itemId: track.track.id, itemType: .tracks) ? "Pinned" : "Pin")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pinService.isItemPinned(itemId: track.track.id, itemType: .tracks) ? Color.yellow.opacity(0.3) : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Play/Open on Spotify
                Button(action: {
                    // TODO: Open track on Spotify
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
            
            // View Album button
            Button(action: {
                // TODO: Navigate to album detail view
            }) {
                HStack {
                    Image(systemName: "square.stack.fill")
                    Text("View Album")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentTrackAlbumRanking: Int? {
        return albumTracksResponse?.tracks.first { $0.trackId == track.track.id }?.albumRanking
    }
    
    // MARK: - Data Loading
    
    private func loadAlbumData() {
        isLoadingAlbumData = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else {
                    print("No user ID available for loading album data")
                    await MainActor.run {
                        isLoadingAlbumData = false
                    }
                    return
                }
                
                // Get album tracks with rankings from prestige API
                let albumData = try await APIClient.shared.getAlbumTracksWithRankings(
                    userId: userId,
                    albumId: track.track.album.id
                )
                
                await MainActor.run {
                    albumTracksResponse = albumData
                    isLoadingAlbumData = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading album data: \(error)")
                    isLoadingAlbumData = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TrackDetailView(
        track: UserTrackResponse(
            totalTime: 7200,
            track: TrackResponse(
                id: "track1",
                name: "Sample Track",
                duration_ms: 180000,
                album: .init(id: "album1", name: "Sample Album", images: []),
                artists: [.init(id: "artist1", name: "Sample Artist")]
            ),
            userId: "user1",
            albumPosition: 3,
            totalTracksInAlbum: 12
        ),
        rank: 5
    )
}